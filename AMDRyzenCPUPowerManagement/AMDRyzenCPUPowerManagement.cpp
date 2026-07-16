#include "AMDRyzenCPUPowerManagement.hpp"
#include <string.h>
#include <mach/mach_time.h>
#include <kern/clock.h>
#include <IOKit/IOPlatformExpert.h>
#include <libkern/c++/OSString.h>
#include <libkern/c++/OSData.h>

OSDefineMetaClassAndStructors(AMDRyzenCPUPowerManagement, IOService);

#define TCTL_OFFSET_TABLE_LEN 6
static constexpr const struct tctl_offset tctl_offset_table[] = {
    { 0x17, "AMD Ryzen 5 1600X", 20 },
    { 0x17, "AMD Ryzen 7 1700X", 20 },
    { 0x17, "AMD Ryzen 7 1800X", 20 },
    { 0x17, "AMD Ryzen 7 2700X", 10 },
    { 0x17, "AMD Ryzen Threadripper 19", 27 }, /* 19{00,20,50}X */
    { 0x17, "AMD Ryzen Threadripper 29", 27 }, /* 29{20,50,70,90}[W]X */
};

static constexpr float  kTHERMAL_GUARD_TEMP_C        = 85.0f;
static constexpr uint8_t kTHERMAL_GUARD_PWM          = 200;   // 80%
static constexpr float  kTHERMAL_THROTTLE_TEMP_C     = 95.0f; // CPPC throttle
static constexpr float  kTHERMAL_THROTTLE_CLEAR_C    = 85.0f;
static constexpr float  kCURVE_OPTIMIZER_BLOCK_TEMP_C = 75.0f;

bool ADDPR(debugEnabled) = false;
uint32_t ADDPR(debugPrintDelay) = 0;


extern "C"{
void pmRyzen_wrmsr_safe(void *handle, uint32_t addr, uint64_t value){
    static_cast<AMDRyzenCPUPowerManagement*>(handle)->write_msr(addr, value);
}

uint64_t pmRyzen_rdmsr_safe(void *handle, uint32_t addr){
    uint64_t v = 0;
    static_cast<AMDRyzenCPUPowerManagement*>(handle)->read_msr(addr, &v);
    return v;
}

pmRyzen_symtable_t pmRyzen_symtable={0};
uint8_t pmRyzen_symtable_ready = 0;

}


bool AMDRyzenCPUPowerManagement::init(OSDictionary *dictionary){
    strncpy(kMODULE_VERSION, xStringify(MODULE_VERSION), sizeof(kMODULE_VERSION) - 1);
    kMODULE_VERSION[sizeof(kMODULE_VERSION) - 1] = '\0';
    IOLog("AMDRyzenCPUPowerManagement v%s, init\n", xStringify(MODULE_VERSION));
    
    IOLog("AMDRyzenCPUPowerManagement::enter dlinking..\n");
    
    pmRyzen_symtable_ready = 0;
    bool resolved = false;
    for (int symbolRetries = 0; symbolRetries < 50; symbolRetries++) {
        find_mach_header_addr(getKernelVersion() >= KernelVersion::BigSur);
        pmRyzen_symtable._wrmsr_carefully = lookup_symbol("_wrmsr_carefully");
        if (pmRyzen_symtable._wrmsr_carefully) {
            resolved = true;
            break;
        }
        IOSleep(10);
    }
    if (!resolved) {
        OSIncrementAtomic((SInt32*)&kextloadAlerts);
        IOLog("AMDRyzenCPUPowerManagement::init symbol resolution for _wrmsr_carefully failed after 50 retries\n");
        return false;
    }
    
    pciConfigLock = IOSimpleLockAlloc();
    superIOLock = IOLockAlloc();
    smuCmdLock = IOLockAlloc();
    rendezvousLock = IOLockAlloc();
    
    pmRyzen_symtable._KUNCUserNotificationDisplayAlert = lookup_symbol("_KUNCUserNotificationDisplayAlert");
    pmRyzen_symtable._tscFreq = lookup_symbol("_tscFreq");
    pmRyzen_symtable._pmDispatch = lookup_symbol("_pmDispatch");
    pmRyzen_symtable._pmUnRegister = lookup_symbol("_pmUnRegister");
    pmRyzen_symtable._cpu_NMI_interrupt = lookup_symbol("_cpu_NMI_interrupt");
    pmRyzen_symtable._NMIPI_enable = lookup_symbol("_NMIPI_enable");
    pmRyzen_symtable._i386_cpu_IPI = lookup_symbol("_i386_cpu_IPI");
    pmRyzen_symtable_ready = 1;
    IOLog("AMDRyzenCPUPowerManagement::enter link finished.\n");
    return IOService::init(dictionary);
}

void AMDRyzenCPUPowerManagement::free(){
    // Cleanup resources allocated in init() in case start() failed partway
    // and stop() was never called. IOLockFree handles NULL on some XNU versions
    // but we guard explicitly for safety.
    if (pciConfigLock)   { IOSimpleLockFree(pciConfigLock);   pciConfigLock = nullptr; }
    if (superIOLock)     { IOLockFree(superIOLock);           superIOLock = nullptr; }
    if (smuCmdLock)      { IOLockFree(smuCmdLock);            smuCmdLock = nullptr; }
    if (rendezvousLock)  { IOLockFree(rendezvousLock);        rendezvousLock = nullptr; }
    if (fIOPCIDevice)    { fIOPCIDevice->release();           fIOPCIDevice = nullptr; }
    IOService::free();
}


bool AMDRyzenCPUPowerManagement::getPCIService(){
    OSDictionary *matching_dict = serviceMatching("IOPCIDevice");
    if(!matching_dict){
        IOLog("AMDRyzenCPUPowerManagement::getPCIService: serviceMatching unable to generate matching dictonary.\n");
        return false;
    }
    
    //Wait for PCI services to init.
    waitForMatchingService(matching_dict);
    
    OSIterator *service_iter = getMatchingServices(matching_dict);
    IOPCIDevice *service = nullptr;
    
    if(!service_iter){
        IOLog("AMDRyzenCPUPowerManagement::getPCIService: unable to find a matching IOPCIDevice.\n");
        return false;
    }
    
    while (OSObject *obj = service_iter->getNextObject()) {
        IOPCIDevice *dev = OSDynamicCast(IOPCIDevice, obj);
        if (dev) {
            uint16_t vendor = dev->configRead16(kIOPCIConfigVendorID);
            if (vendor == 0x1022) { // AMD Host Bridge Vendor ID
                service = dev;
                break;
            }
        }
    }
    service_iter->release();
    
    if(!service){
        IOLog("AMDRyzenCPUPowerManagement::getPCIService: unable to get AMD IOPCIDevice on host system.\n");
        return false;
    }
    
    IOLog("AMDRyzenCPUPowerManagement::getPCIService: succeed!\n");
    // Retain PCI device reference to guarantee pointer outlives both telemetry timer event sources
    fIOPCIDevice = service;
    fIOPCIDevice->retain();
    
    return true;
}

void AMDRyzenCPUPowerManagement::initWorkLoop() {
    IOLog("AMDRyzenCPUPowerManagement::startWorkLoop setting up timer");
    timerEvent_main = IOTimerEventSource::timerEventSource(this, [](OSObject *object, IOTimerEventSource *sender) {
        AMDRyzenCPUPowerManagement *provider = OSDynamicCast(AMDRyzenCPUPowerManagement, object);
        if (!provider) return;

        //Run initialization
        if(!provider->serviceInitialized){
            IOLog("AMDRyzenCPUPowerManagement::startWorkLoop initialize service");
            
            //Disable interrupts and sync all processor cores.
            IOLockLock(provider->rendezvousLock);
            mp_rendezvous_no_intrs([](void *obj) {
                auto provider = static_cast<AMDRyzenCPUPowerManagement*>(obj);
                
                // NOTE: Writing kMSR_CSTATE_ADDR (0xC0010073) with 0xF0 disables
                // deep C-states (C6+). This prevents macOS from parking cores in
                // low-power idle, which reduces wake latency for telemetry but
                // increases idle power consumption. This is intentional for the
                // monitoring use-case — if power efficiency is critical, consider
                // making this configurable via a boot-arg.
                provider->write_msr(kMSR_CSTATE_ADDR, 0xf0);
                
                uint64_t hwConfig;
                if(!provider->read_msr(kMSR_HWCR, &hwConfig)) {
                    IOLog("AMDRyzenCPUPowerManagement::startWorkLoop: failed to read kMSR_HWCR, skipping init.\n");
                    return;
                }

                hwConfig |= (1 << 30);
                provider->write_msr(kMSR_HWCR, hwConfig);


                uint32_t cpu_num = cpu_number();

                //Read PStateDef generated by EFI.
                if(pmRyzen_cpu_is_master(cpu_num))
                    provider->dumpPstate();

                // Query CPPC core ranking per logical core if supported
                // Only read CPPC CAP1 for core ranking; do NOT write CPPC_ENABLE in baseline.
                if (provider->cppcSupported && cpu_num < CPUInfo::MaxCpus) {
                    uint64_t cppcCap = 0;
                    bool msrSuccess = provider->read_msr(kMSR_AMD_CPPC_CAP1, &cppcCap);
                    IOLog("AMDRyzenCPUPowerManagement::startWorkLoop Core %d CPPC CAP1 read: %d, value: 0x%llX\n", cpu_num, msrSuccess, cppcCap);
                    if (msrSuccess) {
                        // AMD PPR states bits 7:0 are HighestPerformance
                        provider->cppcHighestPerf_perCore[cpu_num] = cppcCap & 0xFF;
                        
                        // For Vermeer baseline: do NOT enable CPPC by default
                        // Keep cppcActiveMode=false to avoid writing CPPC_ENABLE/REQ
                    }
                }


                if(!pmRyzen_cpu_primary_in_core(cpu_num)) return;
                uint8_t physical = pmRyzen_cpu_phys_num(cpu_num);


                //Init performance frequency counter.
                uint64_t APERF, MPERF;
                if(!provider->read_msr(kMSR_APERF, &APERF) || !provider->read_msr(kMSR_MPERF, &MPERF)) {
                    IOLog("AMDRyzenCPUPowerManagement::startWorkLoop: failed to read APERF/MPERF, skipping core init.\n");
                    return;
                }

                provider->lastAPERF_perCore[physical] = APERF;
                provider->lastMPERF_perCore[physical] = MPERF;

            }, provider);
            
            uint64_t cstateAddr = 0;
            if (provider->read_msr(kMSR_CSTATE_ADDR, &cstateAddr)) {
                provider->cstateAddrConfig = cstateAddr;
                IOLog("AMDRyzenCPUPowerManagement::startWorkLoop: C-State address configuration: 0x%llX\n", cstateAddr);
            }
            
            //Make all cores P0 state by default.
            provider->PStateCtl = 0;
            
            provider->serviceInitialized = true;
            provider->timerEvent_main->setTimeoutMS(1);
            IOLockUnlock(provider->rendezvousLock);
            return;
        }

        if (!provider->serviceInitialized) return;

        // Post-wake deferred reinit: consume the flag set by resumeWorkLoop()
        // so reinitHwState() runs here on the workLoop thread, not the PM thread.
        if (provider->pendingReinit) {
            provider->pendingReinit = false;
            provider->reinitHwState();
            sender->setTimeoutMS(provider->updateTimeInterval);
            return;
        }

        IOLockLock(provider->rendezvousLock);
        mp_rendezvous_no_intrs([](void *obj) {
            auto provider = static_cast<AMDRyzenCPUPowerManagement*>(obj);
            uint32_t cpu_num = cpu_number();

            provider->updateInstructionDelta(cpu_num);

            // Ignore hyper-threaded cores
            if(!pmRyzen_cpu_primary_in_core(cpu_num)) return;
            uint8_t physical = pmRyzen_cpu_phys_num(cpu_num);


            provider->calculateEffectiveFrequency(physical);

        }, provider);
        
        //Read stats from package.
        provider->updatePackageTemp();
        provider->updatePackageEnergy();

        IOLockUnlock(provider->rendezvousLock);

        uint32_t now = uint32_t(getCurrentTimeNs() / 1000000); //ms
        uint32_t newInt = max(now - provider->timeOfLastMissedRequest,
                              provider->estimatedRequestTimeInterval);

        provider->actualUpdateTimeInterval = now - provider->timeOfLastUpdate;
        provider->timeOfLastUpdate = now;
        provider->updateTimeInterval = min(1200, max(50, newInt));

        provider->timerEvent_main->setTimeoutMS(provider->updateTimeInterval);

//        IOLog("fpp %d %d %.4f.\n", HF_TEMP_SAMPLE_FREQ, HF_TEMP_SAMPLE_PERIOD, (float)HF_TEMP_SAMPLE_REP);

    });
    
//    tempSamplePeriod = (int)((1.0f / (float)HF_TEMP_SAMPLE_FREQ) * 1000);
    float fillT = getPackageTemp();
    tempNextSample = 0;
    for (int i = 0; i < HF_TEMP_SAMPLE_LEN; i++) tempSamples[i] = fillT;
    
    timerEvent_tempe = IOTimerEventSource::timerEventSource(this, [](OSObject *object, IOTimerEventSource *sender) {
        AMDRyzenCPUPowerManagement *provider = OSDynamicCast(AMDRyzenCPUPowerManagement, object);
        if (!provider || !provider->serviceInitialized) return;
        
        int next_samp = provider->tempNextSample;
        float t = provider->getPackageTemp();
        provider->tempSamples[next_samp] = t;
        provider->tempNextSample = (next_samp + 1) % HF_TEMP_SAMPLE_LEN;
        
        for (uint8_t i = 0; i < provider->ccdCount; i++) {
            provider->ccdTemperatures[i] = provider->getCCDTemp(i);
        }
        
        provider->evaluateFanCurves();
        
        sender->setTimeoutMS(HF_TEMP_SAMPLE_PERIOD);
    });
    
    registerService();
    
    lastUpdateTime = getCurrentTimeNs();
    pwrLastTSC = rdtsc64();
    workLoop->addEventSource(timerEvent_main);
    workLoop->addEventSource(timerEvent_tempe);
    timerEvent_main->setTimeoutMS(1);
    timerEvent_tempe->setTimeoutMS(HF_TEMP_SAMPLE_PERIOD);
}

void AMDRyzenCPUPowerManagement::stopWorkLoop() {
    if (timerEvent_main) timerEvent_main->cancelTimeout();
    if (timerEvent_tempe) timerEvent_tempe->cancelTimeout();
    if (workLoop) workLoop->disableAllEventSources();
    serviceInitialized = false;
}

void AMDRyzenCPUPowerManagement::resumeWorkLoop() {
    if (!workLoop) return;
    // NOTE: Do NOT call reinitHwState() here — this runs on the IOKit PM thread
    // during the wake sequence. Blocking the PM thread with MSR reads + CPPC
    // write + dumpPstate() (up to 128 MSR reads on 16-core Zen 3) causes
    // perceptible lag right after S3 resume. Instead, set the pending flag and
    // let the first timer tick on the workLoop thread do the reinit safely.
    pendingReinit = true;
    workLoop->enableAllEventSources();
    serviceInitialized = true;
    pwrLastTSC = rdtsc64();
    // Give the system 250ms to complete the wake sequence before the kext
    // starts its own rendezvous / MSR work. 1ms was causing a CPU stall spike.
    if (timerEvent_main) timerEvent_main->setTimeoutMS(250);
    if (timerEvent_tempe) timerEvent_tempe->setTimeoutMS(HF_TEMP_SAMPLE_PERIOD);
}

bool AMDRyzenCPUPowerManagement::start(IOService *provider){
    
    bool success = IOService::start(provider);
    if(!success){
        IOLog("AMDRyzenCPUPowerManagement::start failed to start. :(\n");
        return false;
    }
    
    disablePrivilegeCheck = checkKernelArgument("-amdpnopchk");
    
    uint32_t cpuid_eax = 0;
    uint32_t cpuid_ebx = 0;
    uint32_t cpuid_ecx = 0;
    uint32_t cpuid_edx = 0;
    CPUInfo::getCpuid(0, 0, &cpuid_eax, &cpuid_ebx, &cpuid_ecx, &cpuid_edx);
    IOLog("AMDRyzenCPUPowerManagement::start got CPUID: %X %X %X %X\n", cpuid_eax, cpuid_ebx, cpuid_ecx, cpuid_edx);
    
    if(cpuid_ebx != CPUInfo::signature_AMD_ebx
       || cpuid_ecx != CPUInfo::signature_AMD_ecx
       || cpuid_edx != CPUInfo::signature_AMD_edx){
        IOLog("AMDRyzenCPUPowerManagement::start no AMD signature detected, failing..\n");
        
        return false;
    }
    
    CPUInfo::getCpuid(1, 0, &cpuid_eax, &cpuid_ebx, &cpuid_ecx, &cpuid_edx);
    cpuFamily = ((cpuid_eax >> 20) & 0xff) + ((cpuid_eax >> 8) & 0xf);
    // Correct CPUID model decode: extended model must be shifted left by 4
    uint8_t baseModel = (cpuid_eax >> 4) & 0xF;
    uint8_t extModel = (cpuid_eax >> 16) & 0xF;
    cpuModel = baseModel | (extModel << 4);
    
    // Support for Zen (17h), Zen 2/3/4 (19h), and Zen 5 (1Ah)
    cpuSupportedByCurrentVersion = (cpuFamily == 0x17 || cpuFamily == 0x19 || cpuFamily == 0x1A)? 1 : 0;
    IOLog("AMDRyzenCPUPowerManagement::start Family %02Xh, Model %02Xh\n", cpuFamily, cpuModel);
    
    // cpuArchName is populated below by the active profile's generationName.
    // The profile block handles all known CPU families (Zen 1-5) and
    // sets "Unknown" for unmatched CPUs.
    
    // Determine CCD temperature register offset based on CPU family/model.
    // Sourced from Linux kernel drivers/hwmon/k10temp.c:
    //   Family 17h: offset 0x154 (all models)
    //   Family 19h models 00-5Fh: offset 0x154 (Zen 3/3+)
    //   Family 19h models 60-7Fh: offset 0x308 (Zen 4)
    //   Family 1Ah models 40-4Fh: offset 0x308 (Zen 5 Granite Ridge)
    if (cpuFamily == 0x1A) {
        // Zen 5 (Granite Ridge, etc.)
        ccdOffset = kZEN_CCD_OFFSET_ZEN4_5;
    } else if (cpuFamily == 0x19 && cpuModel >= 0x60 && cpuModel <= 0x7F) {
        // Family 19h models 60-7Fh: Zen 4 desktop (Raphael)
        ccdOffset = kZEN_CCD_OFFSET_ZEN4_5;
    } else {
        // Family 17h all models and Family 19h Zen 3/3+ models use the legacy offset.
        ccdOffset = kZEN_CCD_OFFSET_LEGACY;
    }
    IOLog("AMDRyzenCPUPowerManagement::start CCD temperature offset: 0x%X\n", ccdOffset);
    
    // Resolve capability profile for detected CPU from all known profiles.
    // Each profile defines whether the kext registers PM dispatch + legacy P-states
    // (Zen 1/2: macOS has no native AMD PM) or stays telemetry-only (Zen 3+).
    {
        const ZenCpuFeatureMap *allProfiles[] = {
            &ZEN1_PROFILE, &ZEN_PLUS_PROFILE, &ZEN2_PROFILE,
            &ZEN3_CEZANNE_PROFILE, &ZEN3_VERMEER_PROFILE, &ZEN3_PLUS_PROFILE,
            &ZEN4_PROFILE, &ZEN5_PROFILE,
        };
        const ZenCpuFeatureMap *activeProfile = nullptr;
        for (auto *profile : allProfiles) {
            if (cpuFamily == profile->family &&
                cpuModel >= profile->modelStart &&
                cpuModel <= profile->modelEnd) {
                activeProfile = profile;
                break;
            }
        }
        
        if (activeProfile) {
            cppcReadInInit = activeProfile->supportsCPPC;
            legacyPstateAllowed = activeProfile->legacyPstateAllowed;
            pmDispatchAllowed = activeProfile->pmDispatchAllowed;
            supportsCPPC = activeProfile->supportsCPPC;
            supportsCPPCv2 = activeProfile->supportsCPPCv2;
            zenGeneration = activeProfile->zenGeneration;
            strlcpy(cpuArchName, activeProfile->generationName, sizeof(cpuArchName));
            
            // Build capabilities string matching the app's profile log format
            char capsBuf[64];
            capsBuf[0] = '\0';
            if (activeProfile->pmDispatchAllowed) {
                strlcpy(capsBuf, "PM Dispatch", sizeof(capsBuf));
            }
            if (activeProfile->legacyPstateAllowed) {
                if (capsBuf[0]) strlcat(capsBuf, " · ", sizeof(capsBuf));
                strlcat(capsBuf, "Legacy P-States", sizeof(capsBuf));
            }
            if (activeProfile->supportsCPPC) {
                if (capsBuf[0]) strlcat(capsBuf, " · ", sizeof(capsBuf));
                strlcat(capsBuf, "CPPC", sizeof(capsBuf));
            }
            if (capsBuf[0] == '\0') {
                strlcpy(capsBuf, "Telemetry only", sizeof(capsBuf));
            }
            
            const char *mode = activeProfile->pmDispatchAllowed ? "Full PM Dispatch" : "Telemetry-only";
            IOLog("AMDRyzenCPUPowerManagement::start CPU Profile: %s — %s (Capabilities: %s)\n",
                  mode, activeProfile->generationName, capsBuf);
        } else {
            zenGeneration = 0;
            strlcpy(cpuArchName, "Unknown", sizeof(cpuArchName));
            IOLog("AMDRyzenCPUPowerManagement::start WARN: no profile for Family %02Xh Model %02Xh\n",
                  cpuFamily, cpuModel);
        }
    }
    
    // Single idle strategy for all CPUs: sti; hlt (SIMPLE).
    // Intel-style MONITOR/MWAIT was removed (unsafe on AMD — CPUs don't report CPUID.01h:ECX[3]).
    // AMD MONITORX/MWAITX may be added as a future enhancement for Zen 3+.
    cpuIdleStrategy = PMRYZEN_IDLE_STRATEGY_SIMPLE;
    pmRyzen_idle_strategy = cpuIdleStrategy;
    IOLog("AMDRyzenCPUPowerManagement::start Idle strategy: SIMPLE (sti;hlt)\n");
    
    CPUInfo::getCpuid(0x80000005, 0, &cpuid_eax, &cpuid_ebx, &cpuid_ecx, &cpuid_edx);
    // L1-D size in bits [31:24] of ECX, L1-I size in bits [31:24] of EDX (CPUID 0x80000005)
    cpuCacheL1_perCore = (cpuid_ecx >> 24) + (cpuid_edx >> 24);
    
    
    CPUInfo::getCpuid(0x80000006, 0, &cpuid_eax, &cpuid_ebx, &cpuid_ecx, &cpuid_edx);
    cpuCacheL2_perCore = (cpuid_ecx >> 16);
    cpuCacheL3 = (cpuid_edx >> 18) * 512;
    IOLog("AMDRyzenCPUPowerManagement::start L1: %u, L2: %u, L3: %u\n",
          cpuCacheL1_perCore, cpuCacheL2_perCore, cpuCacheL3);
    
    
    char nameString[49] = {0};
    uint32_t *namePtr = (uint32_t*)nameString;
    CPUInfo::getCpuid(0x80000002, 0, &cpuid_eax, &cpuid_ebx, &cpuid_ecx, &cpuid_edx);
    namePtr[0] = cpuid_eax; namePtr[1] = cpuid_ebx; namePtr[2] = cpuid_ecx; namePtr[3] = cpuid_edx;
    CPUInfo::getCpuid(0x80000003, 0, &cpuid_eax, &cpuid_ebx, &cpuid_ecx, &cpuid_edx);
    namePtr[4] = cpuid_eax; namePtr[5] = cpuid_ebx; namePtr[6] = cpuid_ecx; namePtr[7] = cpuid_edx;
    CPUInfo::getCpuid(0x80000004, 0, &cpuid_eax, &cpuid_ebx, &cpuid_ecx, &cpuid_edx);
    namePtr[8] = cpuid_eax; namePtr[9] = cpuid_ebx; namePtr[10] = cpuid_ecx; namePtr[11] = cpuid_edx;
    nameString[48] = '\0';
    
    IOLog("AMDRyzenCPUPowerManagement::start Processor: %s\n", nameString);
    
    //Check tctl temperature offset
    for(int i = 0; i < TCTL_OFFSET_TABLE_LEN; i++){
        const TempOffset *to = tctl_offset_table + i;
        if(cpuFamily == to->model && strstr(nameString, to->id)){
            
            tempOffset = (float)to->offset;
            break;
        }
    }

    reinitHwState();
    
    fetchOEMBaseBoardInfo();
    
    IOLog("AMDRyzenCPUPowerManagement::start trying to init PCI service...\n");
    if(!getPCIService()){
        IOLog("AMDRyzenCPUPowerManagement::start no PCI support found, failing...\n");
        return false;
    }
    
    // Probe for available CCDs by reading CCD temperature registers.
    // A CCD is considered present if the valid bit (bit 11) is set.
    ccdCount = 0;
    for (uint8_t i = 0; i < kMAX_CCD_COUNT; i++) {
        uint32_t regVal = readCCDRegisterRaw(i);
        if (regVal & kZEN_CCD_TEMP_VALID_BIT) {
            ccdCount = i + 1;
            IOLog("AMDRyzenCPUPowerManagement::start CCD%u detected, raw=0x%X\n", i, regVal);
        }
    }
    IOLog("AMDRyzenCPUPowerManagement::start Total CCDs detected: %u\n", ccdCount);
    
//    while (!pmRyzen_symtable_ready) {
//        IOSleep(200);
//    }
    
    void *safe_wrmsr = pmRyzen_symtable._wrmsr_carefully;
    if(!safe_wrmsr){
        IOLog("AMDRyzenCPUPowerManagement::start WARN: Can't find _wrmsr_carefully, proceeding with unsafe wrmsr\n");
    } else {
        wrmsr_carefully = (int(*)(uint32_t,uint32_t,uint32_t)) safe_wrmsr;
    }

    void *_kunc_alert = pmRyzen_symtable._KUNCUserNotificationDisplayAlert;
    if(!_kunc_alert){
        IOLog("AMDRyzenCPUPowerManagement::start WARN: Can't find _KUNCUserNotificationDisplayAlert.\n");
    } else {
        kunc_alert =
        (kern_return_t(*)(int,unsigned,const char*,const char*,const char*,
        const char*,const char*,const char*,const char*,const char*,unsigned*))_kunc_alert;
    }

    if (pmRyzen_symtable._tscFreq != nullptr) {
        xnuTSCFreq = *((uint64_t*)pmRyzen_symtable._tscFreq);
    } else {
        struct mach_timebase_info tbInfoData;
        clock_timebase_info(&tbInfoData);
        if (tbInfoData.numer != 0) {
            xnuTSCFreq = (1000000000ULL * (uint64_t)tbInfoData.denom) / (uint64_t)tbInfoData.numer;
            IOLog("AMDRyzenCPUPowerManagement::start WARN: _tscFreq symbol null, using mach_timebase_info fallback TSC frequency (%llu Hz)\n", xnuTSCFreq);
        }
    }
    if (xnuTSCFreq == 0) {
        xnuTSCFreq = 1000000000u; // Fallback default 1GHz calibration
    }

    pmRyzen_init(this, pmDispatchAllowed ? 1 : 0);

    // Populate per-family SMU mailbox descriptor.
    // Sources: Linux drivers/platform/x86/amd-pmf/, AGESA SMU headers, amdgpu nv.c.
    if (cpuFamily == 0x19 && cpuModel >= 0x21 && cpuModel <= 0x2F) {
        // Zen 3 Vermeer
        smuMailbox = { 0x3B10524, 0x3B10528, 0x3B1052C, 0x3D, true };
    } else if (cpuFamily == 0x19 && cpuModel >= 0x60 && cpuModel <= 0x7F) {
        // Zen 4 Raphael — SMU mailbox moved; Curve Optimizer command is 0x55.
        // NOTE: offsets below are placeholders — verify against AGESA Family 19h Model 60h PPR.
        smuMailbox = { 0x3B10590, 0x3B10594, 0x3B10598, 0x55, true };
        IOLog("AMDRyzenCPUPowerManagement: Zen 4 SMU mailbox offsets are UNVERIFIED — Curve Optimizer writes blocked.\n");
        smuMailbox.supported = false;   // Block until verified
    } else if (cpuFamily == 0x1A) {
        // Zen 5 Granite Ridge — SMU firmware restructured; Curve Optimizer path unknown.
        smuMailbox = { 0, 0, 0, 0, false };
        IOLog("AMDRyzenCPUPowerManagement: Zen 5 SMU mailbox unsupported — Curve Optimizer blocked.\n");
    } else {
        smuMailbox = { 0x3B10524, 0x3B10528, 0x3B1052C, 0x3D, false };
    }

    totalNumberOfLogicalCores = pmRyzen_num_logi;
    totalNumberOfPhysicalCores = pmRyzen_num_phys;

    IOLog("AMDRyzenCPUPowerManagement::start, Physical Count: %u, Logical Count %u.\n",
              totalNumberOfPhysicalCores, totalNumberOfLogicalCores);

    for (size_t i = 0; i < kMAX_FANS; i++) {
        fanToCurveMap[i] = -1;
        lastAppliedPWM[i] = 0;
        lastPWMUpdateTime[i] = 0;
    }
    for (int i = 0; i < MAX_FAN_CURVES; i++) {
        memset(fanCurves[i].lut, 0, 256);
        fanCurves[i].sourceSensor = 0;
        fanCurves[i].hysteresis = 2;
        fanCurves[i].rampRate = 5;
        curveSmoothedTemp[i] = 40.0f;
    }
    gpuTempC = 0.0f;

    workLoop = IOWorkLoop::workLoop();
    initWorkLoop();


    PMinit();
    provider->joinPMtree(this);
    registerPowerDriver(this, powerStates, kNrOfPowerStates);

    return success;
}

void AMDRyzenCPUPowerManagement::stop(IOService *provider){
    IOLog("AMDRyzenCPUPowerManagement stopping...\n");

    // 1. Cancel all timerEventSource (cancelTimeout)
    if (timerEvent_main)  timerEvent_main->cancelTimeout();
    if (timerEvent_tempe) timerEvent_tempe->cancelTimeout();

    // 2. workLoop->removeEventSource() for each timer
    if (workLoop) {
        workLoop->disableAllEventSources();
        if (timerEvent_main)  workLoop->removeEventSource(timerEvent_main);
        if (timerEvent_tempe) workLoop->removeEventSource(timerEvent_tempe);
    }
    serviceInitialized = false;

    // 3. release() and null each timer
    if (timerEvent_main)  { timerEvent_main->release();  timerEvent_main = nullptr; }
    if (timerEvent_tempe) { timerEvent_tempe->release(); timerEvent_tempe = nullptr; }

    // 4. pmRyzen_stop() after timers are completely drained and unlinked
    pmRyzen_stop();

    // 5. release() of fIOPCIDevice and null
    if (fIOPCIDevice) { fIOPCIDevice->release(); fIOPCIDevice = nullptr; }

    // 6. SuperIO defaults + delete and workloop release before super::stop()
    if (superIOLock) {
        IOLockLock(superIOLock);
        if (superIO) {
            for (int i = 0; i < superIO->getNumberOfFans(); i++) {
                superIO->setDefaultFanControl(i);
            }
            delete superIO;
            superIO = nullptr;
        }
        IOLockUnlock(superIOLock);
    } else if (superIO) {
        delete superIO;
        superIO = nullptr;
    }

    if (pciConfigLock) {
        IOSimpleLockFree(pciConfigLock);
        pciConfigLock = nullptr;
    }
    if (smuCmdLock) {
        IOLockFree(smuCmdLock);
        smuCmdLock = nullptr;
    }
    if (superIOLock) {
        IOLockFree(superIOLock);
        superIOLock = nullptr;
    }
    if (rendezvousLock) {
        IOLockFree(rendezvousLock);
        rendezvousLock = nullptr;
    }
    if (workLoop) {
        workLoop->release();
        workLoop = nullptr;
    }

    PMstop();
    IOService::stop(provider);
}

IOReturn AMDRyzenCPUPowerManagement::setPowerState(unsigned long powerStateOrdinal, IOService* provider) {
    if (0 == powerStateOrdinal) {
        // Going to sleep
        IOLog("AMDRyzenCPUPowerManagement::setPowerState preparing for sleep\n");
        wentToSleep = true;
        stopWorkLoop();
    } else if (1 == powerStateOrdinal && wentToSleep) {
        // Waking up
        IOLog("AMDRyzenCPUPowerManagement::setPowerState preparing for wakeup\n");
        wentToSleep = false;
        if (workLoop) {
            resumeWorkLoop();
        }
    }

    return kIOPMAckImplied;
}

void AMDRyzenCPUPowerManagement::fetchOEMBaseBoardInfo(){
    if (boardInfoValid) return;
    strlcpy(boardVendor, "Unknown Vendor", BASEBOARD_STRING_MAX);
    strlcpy(boardName, "Unknown Platform", BASEBOARD_STRING_MAX);
    
    auto efiRT = EfiRuntimeServices::get();
    uint32_t att = 0;
    uint64_t sizee = BASEBOARD_STRING_MAX;
    uint64_t efistat;
    
    efistat = efiRT->getVariable(OC_OEM_VENDOR_VARIABLE_NAME, &EfiRuntimeServices::LiluVendorGuid,
                                 &att, &sizee, boardVendor);
    
    sizee = BASEBOARD_STRING_MAX;
    uint64_t efistat2 = efiRT->getVariable(OC_OEM_BOARD_VARIABLE_NAME, &EfiRuntimeServices::LiluVendorGuid,
                                  &att, &sizee, boardName);
                                  
    if (efistat == EFI_SUCCESS && efistat2 == EFI_SUCCESS) {
        boardInfoValid = true;
    } else {
        // Fallback: Query IOPlatformExpertDevice properties
        IOPlatformExpert *platform = getPlatform();
        if (platform) {
            bool foundVendor = false;
            bool foundModel = false;
            OSObject *mfgObj = platform->getProperty("manufacturer");
            OSObject *modelObj = platform->getProperty("model");
            
            if (mfgObj) {
                if (OSString *str = OSDynamicCast(OSString, mfgObj)) {
                    strncpy(boardVendor, str->getCStringNoCopy(), BASEBOARD_STRING_MAX - 1);
                    boardVendor[BASEBOARD_STRING_MAX - 1] = '\0';
                    foundVendor = true;
                } else if (OSData *data = OSDynamicCast(OSData, mfgObj)) {
                    size_t len = data->getLength();
                    size_t copyLen = (len < BASEBOARD_STRING_MAX - 1) ? len : (BASEBOARD_STRING_MAX - 1);
                    memcpy(boardVendor, data->getBytesNoCopy(), copyLen);
                    boardVendor[copyLen] = '\0';
                    foundVendor = true;
                }
            }
            
            if (modelObj) {
                if (OSString *str = OSDynamicCast(OSString, modelObj)) {
                    strncpy(boardName, str->getCStringNoCopy(), BASEBOARD_STRING_MAX - 1);
                    boardName[BASEBOARD_STRING_MAX - 1] = '\0';
                    foundModel = true;
                } else if (OSData *data = OSDynamicCast(OSData, modelObj)) {
                    size_t len = data->getLength();
                    size_t copyLen = (len < BASEBOARD_STRING_MAX - 1) ? len : (BASEBOARD_STRING_MAX - 1);
                    memcpy(boardName, data->getBytesNoCopy(), copyLen);
                    boardName[copyLen] = '\0';
                    foundModel = true;
                }
            }
            boardInfoValid = foundVendor && foundModel;
        } else {
            boardInfoValid = false;
        }
    }
    
    IOLog("MB: %s %s (Valid: %d)\n", boardName, boardVendor, boardInfoValid);
}

bool AMDRyzenCPUPowerManagement::read_msr(uint32_t addr, uint64_t *value){
    if (cpuFamily >= 0x19) {
        // Zen 3+ MSR Bounds Checking — block Intel-exclusive MSRs that #GP on AMD.
        // Whitelist: 0xE7 (MPERF), 0xE8 (APERF) — used by this kext for effective freq.
        if (addr == 0xCE                          // IA32_ARCH_CAPABILITIES
            || addr == 0xE2                        // IA32_POWER_CTL (Intel layout)
            || (addr >= 0x198 && addr <= 0x19C)    // IA32_PERF_STATUS / PERF_CTL / UCODE
            || addr == 0x1A0                       // IA32_MISC_ENABLE
            || addr == 0x1AD                       // IA32_ENERGY_PERF_BIAS (Intel EPB)
            || addr == 0x345                       // IA32_PERF_LIMIT_REASONS
            || (addr >= 0x610 && addr <= 0x617)) { // Intel RAPL PL1/PL2/PL3 + status
            IOLog("AMDRyzenCPUPowerManagement::read_msr BLOCKED unsafe Intel MSR 0x%X for Zen 3+\n", addr);
            *value = 0;
            return false;
        }
    }

    uint32_t lo, hi;
    int err = rdmsr_carefully(addr, &lo, &hi);
    
    if(!err) *value = lo | ((uint64_t)hi << 32);
    
    return err == 0;
}

bool AMDRyzenCPUPowerManagement::write_msr(uint32_t addr, uint64_t value){
    if (cpuFamily >= 0x19) {
        // Zen 3+ MSR Bounds Checking — block Intel-exclusive MSRs that #GP on AMD.
        if (addr == 0xCE                          // IA32_ARCH_CAPABILITIES
            || addr == 0xE2                        // IA32_POWER_CTL (Intel layout)
            || (addr >= 0x198 && addr <= 0x19C)    // IA32_PERF_STATUS / PERF_CTL / UCODE
            || addr == 0x1A0                       // IA32_MISC_ENABLE
            || addr == 0x1AD                       // IA32_ENERGY_PERF_BIAS (Intel EPB)
            || addr == 0x345                       // IA32_PERF_LIMIT_REASONS
            || (addr >= 0x610 && addr <= 0x617)) { // Intel RAPL PL1/PL2/PL3 + status
            IOLog("AMDRyzenCPUPowerManagement::write_msr BLOCKED unsafe Intel MSR 0x%X for Zen 3+\n", addr);
            return false;
        }
    }

    if(wrmsr_carefully){
        uint32_t lo = value & 0xffffffff;
        uint32_t hi = value >> 32;
        return (*wrmsr_carefully)(addr, lo, hi) == 0;
    }
    
    IOLog("AMDRyzenCPUPowerManagement::write_msr safe wrapper unavailable for MSR 0x%X\n", addr);
    return false;
}

void AMDRyzenCPUPowerManagement::registerRequest(){
    uint32_t now = (uint32_t)(getCurrentTimeNs() / 1000000);
    
    estimatedRequestTimeInterval = now - timeOfLastMissedRequest;
    timeOfLastMissedRequest = now;
}

void AMDRyzenCPUPowerManagement::updateClockSpeed(uint8_t physical){
    
    uint64_t msr_value_buf = 0;
    bool err = !read_msr(kMSR_HARDWARE_PSTATE_STATUS, &msr_value_buf);
    if (err) {
        IOLog("AMDRyzenCPUPowerManagement::updateClockSpeed failed to read MSR 0xC0010293\n");
        return;
    }
    
    //Convert register value to clock speed.
    uint32_t eax = (uint32_t)(msr_value_buf & 0xffffffff);
    
    float clock;
    if (cpuFamily >= 0x1A) {
        // Family 1Ah onward (Zen 5) uses 12-bit CpuFid and no CpuDfsId.
        // Frequency is CpuFid * 5 MHz.
        float curCpuFid = (float)(eax & 0xfff);
        clock = curCpuFid * 5.0f;
    } else {
        // MSRC001_0293
        // CurHwPstate [24:22]
        // CurCpuVid [21:14]
        // CurCpuDfsId [13:8]
        // CurCpuFid [7:0]
        float curCpuDfsId = (float)((eax >> 8) & 0x3f);
        float curCpuFid = (float)(eax & 0xff);
        if (curCpuDfsId == 0.0f) {
            static bool loggedUpdateClockDfsZero = false;
            if (!loggedUpdateClockDfsZero) {
                loggedUpdateClockDfsZero = true;
                IOLog("AMDRyzenCPUPowerManagement::updateClockSpeed: curCpuDfsId is zero, clamping clock to 0\n");
            }
            clock = 0.0f;
        } else {
            clock = curCpuFid / curCpuDfsId * 200.0f;
        }
    }
    
//    PStateCur_perCore[physical] = curHwPstate;
    effFreq_perCore[physical] = clock;
    
    //    IOLog("AMDRyzenCPUPowerManagement::updateClockSpeed: %u\n", curHwPstate);
}

void AMDRyzenCPUPowerManagement::calculateEffectiveFrequency(uint8_t physical){
    uint64_t APERF = 0;
    uint64_t MPERF = 0;
    
    if (!read_msr(kMSR_APERF, &APERF) || !read_msr(kMSR_MPERF, &MPERF)) {
        return;
    }
        
    uint64_t lastAPERF = lastAPERF_perCore[physical];
    uint64_t lastMPERF = lastMPERF_perCore[physical];
    
    lastAPERF_perCore[physical] = APERF;
    lastMPERF_perCore[physical] = MPERF;
    //If an overflow of either the MPERF or APERF register occurs between read of last MPERF and
    //read of last APERF, the effective frequency calculated in is invalid.
    if(APERF <= lastAPERF || MPERF <= lastMPERF) {
//        IOLog("AMDRyzenCPUPowerManagement::calculateEffectiveFrequency: frequency is invalid!!!");
        return;
    }
    
    float freqP0 = PStateDefClock_perCore[0];
    // P0 clock not ready yet (dumpPstate failed / still zero) — skip this sample (audit R-3).
    if (freqP0 <= 0.0f) {
        return;
    }
    
    uint64_t deltaAPERF = APERF - lastAPERF;
    float effFreq = ((float)deltaAPERF / (float)(MPERF - lastMPERF)) * freqP0;
    
    effFreq_perCore[physical] = effFreq;
    

}

void AMDRyzenCPUPowerManagement::updateInstructionDelta(uint8_t cpu_num){
    uint64_t insCount;
    
    if(!read_msr(kMSR_PERF_IRPC, &insCount)) {
        IOLog("AMDRyzenCPUPowerManagement::updateInstructionDelta failed to read MSR 0xC00000E9\n");
        return;
    }
    
    
    //Skip if overflowed
    if(lastInstructionDelta_perCore[cpu_num] > insCount) return;
    
//    uint64_t delta = insCount - lastInstructionDelta_perCore[cpu_num];
    instructionDelta_perCore[cpu_num] = insCount - lastInstructionDelta_perCore[cpu_num];
    
    lastInstructionDelta_perCore[cpu_num] = insCount;
    
    //write_msr(kMSR_PERF_IRPC, 0);
    
    
    //Calculate load index
//    float estimatedInstRet = (effFreq_perCore[cpu_num] * 1000000);
//    estimatedInstRet = estimatedInstRet * (actualUpdateTimeInterval * 0.001);
//    float index = (float)delta / estimatedInstRet;
//
//    float growth = 3200;
//    loadIndex_PerCore[cpu_num] = log10f(min(index,1) * growth) / log10f(growth);
}

void AMDRyzenCPUPowerManagement::applyPowerControl(){
    // Legacy P-state writes are controlled per CPU profile.
    // Enabled on Zen 1/2 (full PM dispatch), disabled on Zen 3+ (telemetry-only).
    if (!legacyPstateAllowed) {
        if (cppcActiveMode) {
            IOLog("AMDRyzenCPUPowerManagement::applyPowerControl ignored - CPPC Active Mode active\n");
        } else {
            IOLog("AMDRyzenCPUPowerManagement::applyPowerControl ignored - legacy P-state disabled for this profile\n");
        }
        return;
    }
    
    IOLockLock(rendezvousLock);
    mp_rendezvous(nullptr, [](void *obj) {
        auto provider = static_cast<AMDRyzenCPUPowerManagement*>(obj);
        provider->write_msr(kMSR_PSTATE_CTL, (uint64_t)(provider->PStateCtl & 0x7));
    }, nullptr, this);
    IOLockUnlock(rendezvousLock);
}

void AMDRyzenCPUPowerManagement::applyEPPControl() {
    // CPPC writes (ENABLE/REQ MSRs) are disabled in the current baseline.
    // This function is a no-op until validated CPPC write support is added
    // via a per-profile capability flag.
    IOLog("AMDRyzenCPUPowerManagement::applyEPPControl ignored - CPPC writes disabled in baseline\n");
    return;

    IOLockLock(rendezvousLock);
    mp_rendezvous(nullptr, [](void *obj) {
        auto provider = static_cast<AMDRyzenCPUPowerManagement*>(obj);

        uint64_t cppcCap = 0;
        if (provider->read_msr(kMSR_AMD_CPPC_CAP1, &cppcCap)) {
            uint8_t highestPerf = cppcCap & 0xFF;
            uint8_t lowestPerf = (cppcCap >> 24) & 0xFF;

            uint64_t reqVal = 0;
            reqVal |= (uint64_t)lowestPerf;
            reqVal |= ((uint64_t)highestPerf) << 8;
            reqVal |= 0ULL << 16; // Desired Performance = 0 (autonomous)

            uint8_t effectiveEPP = provider->cppcThrottled ? 0xFF : provider->cppcEPPValue;
            reqVal |= ((uint64_t)effectiveEPP) << 24;

            provider->write_msr(kMSR_AMD_CPPC_ENABLE, 1);
            provider->write_msr(kMSR_AMD_CPPC_REQ, reqVal);
        }
    }, nullptr, this);
    IOLockUnlock(rendezvousLock);
}

void AMDRyzenCPUPowerManagement::setCPBState(bool enabled){
    if(!cpbSupported) return;
    
    uint64_t hwConfig;
    if(!read_msr(kMSR_HWCR, &hwConfig)) {
        IOLog("AMDRyzenCPUPowerManagement::setCPBState failed to read MSR 0xC0010015\n");
        return;
    }
    
    if(enabled){
        hwConfig &= ~(1 << 25);
    } else {
        hwConfig |= (1 << 25);
    }
    
    struct CPBArgs {
        AMDRyzenCPUPowerManagement *provider;
        uint64_t hwConfig;
    } cpbArgs{this, hwConfig};

    IOLockLock(rendezvousLock);
    mp_rendezvous(nullptr, [](void *obj) {
        auto args = static_cast<CPBArgs*>(obj);
        args->provider->write_msr(kMSR_HWCR, args->hwConfig);
    }, nullptr, &cpbArgs);
    IOLockUnlock(rendezvousLock);
}

bool AMDRyzenCPUPowerManagement::getCPBState(){
    uint64_t hwConfig;
    if(!read_msr(kMSR_HWCR, &hwConfig)) {
        IOLog("AMDRyzenCPUPowerManagement::getCPBState failed to read MSR 0xC0010015\n");
        return false;
    }
    
    return !((hwConfig >> 25) & 0x1);
}

inline float AMDRyzenCPUPowerManagement::getPackageTemp() {
    if (!fIOPCIDevice || !pciConfigLock) return 0.0f;
    IOPCIAddressSpace space;
    space.bits = 0x00;
    
    uint8_t smnCtrlReg = (cpuFamily == 0x1A) ? kFAMILY_1AH_PCI_CONTROL_REGISTER
                                             : kFAMILY_17H_PCI_CONTROL_REGISTER;
    IOSimpleLockLock(pciConfigLock);
    fIOPCIDevice->configWrite32(space, smnCtrlReg, (UInt32)kF17H_M01H_THM_TCON_CUR_TMP);
    uint32_t temperature = fIOPCIDevice->configRead32(space, smnCtrlReg + 4);
    IOSimpleLockUnlock(pciConfigLock);
    
    // kF17H_TEMP_OFFSET_FLAG (bit 19, 0x80000) is confirmed correct for Family 17h
    // (Zen/Zen+/Zen 2) and Family 19h (Zen 3/3+/Zen 4) per Linux k10temp.c.
    // Family 1Ah (Zen 5) uses the same bit but the 49 °C compensation is unverified —
    // until confirmed against a Granite Ridge PPR or k10temp update, skip the offset
    // on Zen 5 and log once so the user sees the discrepancy.
    static bool loggedZen5TempOffset = false;
    bool tempOffsetFlag = false;
    if (cpuFamily != 0x1A) {
        tempOffsetFlag = (temperature & kF17H_TEMP_OFFSET_FLAG) != 0;
    } else if (!loggedZen5TempOffset) {
        loggedZen5TempOffset = true;
        IOLog("AMDRyzenCPUPowerManagement: Zen 5 temperature offset flag unverified — skipping 49°C compensation. Verify against k10temp.c.\n");
    }
    temperature = (temperature >> 21) * 125;
    
    float t = temperature * 0.001f;
    
    t -= tempOffset;
    
    if (tempOffsetFlag)
        t -= 49.0f;
    
    return t;
}

uint32_t AMDRyzenCPUPowerManagement::readCCDRegisterRaw(uint8_t ccd) {
    if (ccd >= kMAX_CCD_COUNT || !fIOPCIDevice || !pciConfigLock) return 0;
    IOPCIAddressSpace space;
    space.bits = 0x00;
    uint32_t ccdRegAddr = kF17H_M01H_THM_TCON_CUR_TMP + ccdOffset + (ccd * 4);
    
    IOSimpleLockLock(pciConfigLock);
    fIOPCIDevice->configWrite32(space, (UInt8)kFAMILY_17H_PCI_CONTROL_REGISTER, (UInt32)ccdRegAddr);
    uint32_t regVal = fIOPCIDevice->configRead32(space, kFAMILY_17H_PCI_CONTROL_REGISTER + 4);
    IOSimpleLockUnlock(pciConfigLock);
    
    return regVal;
}

float AMDRyzenCPUPowerManagement::getCCDTemp(uint8_t ccd) {
    if (ccd >= kMAX_CCD_COUNT) return 0.0f;
    
    uint32_t regVal = readCCDRegisterRaw(ccd);
    
    // Check CCD valid bit (bit 11) — if not set, CCD is not present
    if (!(regVal & kZEN_CCD_TEMP_VALID_BIT)) return 0.0f;
    
    // Temperature formula from Linux k10temp:
    // temp = (regVal & 0x7FF) * 125 - 49000 (in millidegrees)
    // We convert to float degrees Celsius:
    float temp = (float)(regVal & kZEN_CCD_TEMP_MASK) * 0.125f - 49.0f;
    temp -= tempOffset;
    
    return temp;
}

uint32_t AMDRyzenCPUPowerManagement::smnRead32(uint32_t addr) {
    if (!fIOPCIDevice || !pciConfigLock) return 0;
    IOPCIAddressSpace space;
    space.bits = 0x00;
    
    IOSimpleLockLock(pciConfigLock);
    fIOPCIDevice->configWrite32(space, (UInt8)kFAMILY_17H_PCI_CONTROL_REGISTER, (UInt32)addr);
    uint32_t val = fIOPCIDevice->configRead32(space, kFAMILY_17H_PCI_CONTROL_REGISTER + 4);
    IOSimpleLockUnlock(pciConfigLock);
    return val;
}

void AMDRyzenCPUPowerManagement::smnWrite32(uint32_t addr, uint32_t val) {
    if (!fIOPCIDevice || !pciConfigLock) return;
    IOPCIAddressSpace space;
    space.bits = 0x00;
    
    IOSimpleLockLock(pciConfigLock);
    fIOPCIDevice->configWrite32(space, (UInt8)kFAMILY_17H_PCI_CONTROL_REGISTER, (UInt32)addr);
    fIOPCIDevice->configWrite32(space, kFAMILY_17H_PCI_CONTROL_REGISTER + 4, (UInt32)val);
    IOSimpleLockUnlock(pciConfigLock);
}

int AMDRyzenCPUPowerManagement::smuSendCmd(uint32_t cmd, uint32_t arg) {
    if (!smuMailbox.supported) return SMU_RSP_INVALID_CMD;
    uint32_t msgReg = smuMailbox.msgReg;
    uint32_t argReg = smuMailbox.argReg;
    uint32_t rspReg = smuMailbox.rspReg;
    
    // Serialize the full SMU mailbox sequence (clear → arg → msg → poll).
    // Individual smnRead/Write use pciConfigLock, but that alone does not protect
    // the multi-step protocol against concurrent UserClient callers (audit R-8).
    if (smuCmdLock) {
        IOLockLock(smuCmdLock);
    }
    
    // Clear response register first
    smnWrite32(rspReg, 0);
    
    // Write argument
    smnWrite32(argReg, arg);
    
    // Send command
    smnWrite32(msgReg, cmd);
    
    // Memory barrier: ensure the SMU sees the command write before we start
    // polling the response register. Without this, write-combining buffers on
    // the SMN bus can delay command delivery, causing the poll to read a stale
    // zero and falsely trigger the timeout reset path.
    __asm__ volatile("mfence" ::: "memory");
    
    // Wait for response. Curve Optimizer (0x3D) triggers PLL reconfiguration and can
    // take 5-15 ms on Zen 3; use 50 ms ceiling. Other commands typically complete <1 ms.
    const uint32_t timeoutUs = (cmd == smuMailbox.curveOptimizerCmd) ? 50000 : 2000;
    const uint32_t pollIters = timeoutUs;
    uint32_t rsp = 0;
    for (uint32_t i = 0; i < pollIters; i++) {
        rsp = smnRead32(rspReg);
        if (rsp != 0) break;
        IODelay(1);
    }
    
    if (smuCmdLock) {
        IOLockUnlock(smuCmdLock);
    }

    if (rsp == 0) {
        // Mailbox stuck — flush before returning so the next caller doesn't inherit stale state.
        smnWrite32(msgReg, 0x01);  // SMU_MSG_ResetMsgBus
        IODelay(100);
    }
    
    return (int)rsp;
}

int AMDRyzenCPUPowerManagement::setCurveOptimizer(uint8_t core, int8_t offset) {
    // Curve Optimizer writes remain disabled during the telemetry-first baseline.
    // The SMU command and payload must be validated against the exact AGESA/SMU
    // firmware before enabling this control path for Vermeer or another profile.
    if (!legacyPstateAllowed) {
        IOLog("AMDRyzenCPUPowerManagement: Curve Optimizer is disabled in baseline mode.\n");
        return -1;
    }
    
    // Bounds check on core index
    if (core >= totalNumberOfPhysicalCores) {
        IOLog("AMDRyzenCPUPowerManagement: Invalid core index %d (max: %d).\n", core, totalNumberOfPhysicalCores - 1);
        return -2;
    }
    
    // Safety check: Limit Curve Optimizer offset to safe range [-30, +30] as per implementation plan
    if (offset < -30 || offset > 30) {
        IOLog("AMDRyzenCPUPowerManagement: Offset %d exceeds safe limits [-30, +30]. Blocking write for safety.\n", offset);
        return -3;
    }
    
    // Thermal safety check: Block if temperature is too high (> kCURVE_OPTIMIZER_BLOCK_TEMP_C) to prevent instability
    float currentTemp = PACKAGE_TEMPERATURE_perPackage[0];
    if (currentTemp > kCURVE_OPTIMIZER_BLOCK_TEMP_C) {
        IOLog("AMDRyzenCPUPowerManagement: Blocked Curve Optimizer write due to high core temperature (%.1f°C > %.1f°C).\n", currentTemp, kCURVE_OPTIMIZER_BLOCK_TEMP_C);
        return -4;
    }
    
    // Format argument: Bits [7:0] = Core Index, Bits [15:8] = Offset (signed 8-bit)
    // NOTE: This payload format is Zen 3 (Vermeer) specific.
    // Zen 4 Raphael uses a per-CCD layout; Zen 5 Granite Ridge uses a different
    // signed-magnitude encoding. smuMailbox.curveOptimizerCmd must be 0x3D AND the
    // detected family must be Vermeer before this path is reachable.
    if (cpuFamily != 0x19 || cpuModel < 0x21 || cpuModel > 0x2F) return -1;
    uint32_t arg = ((uint32_t)core & 0xFF) | (((uint32_t)offset & 0xFF) << 8);
    
    // Send command 0x3D (SetCurveOptimizer) to SMU
    int response = smuSendCmd(smuMailbox.curveOptimizerCmd, arg);
    
    if (response == SMU_RSP_OK) {
        curveOptimizerOffsets[core] = offset;
        IOLog("AMDRyzenCPUPowerManagement: Successfully set Curve Optimizer for Core %d to %d (Offset counts).\n", core, offset);
        return 0;
    } else {
        IOLog("AMDRyzenCPUPowerManagement: SMU Curve Optimizer command failed with response code: 0x%X\n", response);
        if (response == SMU_RSP_TIMEOUT) return -10;
        if (response == SMU_RSP_INVALID_CMD) return -11;
        if (response == SMU_RSP_INVALID_ARGS) return -12;
        if (response == SMU_RSP_BUSY) return -13;
        return -5;
    }
}

void AMDRyzenCPUPowerManagement::updatePackageTemp(){
    float sum = 0;
    for (int i = 0; i < HF_TEMP_SAMPLE_LEN; i++) sum += tempSamples[i];
    float currentTemp = sum * HF_TEMP_SAMPLE_LENREP;
    PACKAGE_TEMPERATURE_perPackage[0] = currentTemp;
    
    // Dynamic CPPC Throttling Logic
    if (cppcActiveMode) {
        if (!cppcThrottled && currentTemp > kTHERMAL_THROTTLE_TEMP_C) {
            cppcThrottled = true;
            IOLog("AMDRyzenCPUPowerManagement: Thermal limit reached (%.1f°C). Throttling CPPC EPP to Power Save.\n", currentTemp);
            applyEPPControl();
        } else if (cppcThrottled && currentTemp < kTHERMAL_THROTTLE_CLEAR_C) {
            cppcThrottled = false;
            IOLog("AMDRyzenCPUPowerManagement: Thermal condition cleared (%.1f°C). Restoring CPPC EPP.\n", currentTemp);
            applyEPPControl();
        }
    }
}

void AMDRyzenCPUPowerManagement::updatePackageEnergy(){
    
    uint64_t ctsc = rdtsc64();

    uint64_t msr_value_buf = 0;
    if (!read_msr(kMSR_PKG_ENERGY_STAT, &msr_value_buf)) {
        IOLog("AMDRyzenCPUPowerManagement::updatePackageEnergy: failed to read MSR 0xC001029B\n");
        return;
    }

    uint32_t energyValue = (uint32_t)(msr_value_buf & 0xffffffff);

    uint32_t energyDelta = energyValue - (uint32_t)lastUpdateEnergyValue;

    // Guard against anomalous wrap-around producing absurd delta values
    if (energyDelta > 0x80000000u) { lastUpdateEnergyValue = energyValue; return; }

    double seconds = (ctsc - pwrLastTSC) / (double)(xnuTSCFreq);
    if (seconds <= 0.0) { pwrLastTSC = ctsc; return; }
    double e = (pwrEnergyUnit * (double)energyDelta) / seconds;
    uniPackagePowerW = e;


    lastUpdateEnergyValue = energyValue;
    pwrLastTSC = ctsc;  // Use the timestamp captured at the start of this function to avoid drift
}

void AMDRyzenCPUPowerManagement::dumpPstate(){
    
    uint8_t len = 0;
    for (uint32_t i = 0; i < kMSR_PSTATE_LEN; i++) {
        uint64_t msr_value_buf = 0;
        bool err = !read_msr(kMSR_PSTATE_0 + i, &msr_value_buf);
        if (err) {
            IOLog("AMDRyzenCPUPowerManagement::dumpPstate failed to read MSR 0xC0010064\n");
            continue;
        }
        
        uint32_t eax = (uint32_t)(msr_value_buf & 0xffffffff);
        
        float clock;
        if (cpuFamily >= 0x1A) {
            // Family 1Ah (Zen 5) uses 12-bit CpuFid.
            int curCpuFid = (int)(eax & 0xfff);
            clock = (float)(curCpuFid * 5.0);
        } else {
            // CpuVid [21:14]
            // CpuDfsId [13:8]
            // CpuFid [7:0]
            int curCpuDfsId = (int)((eax >> 8) & 0x3f);
            int curCpuFid = (int)(eax & 0xff);
            if (curCpuDfsId == 0) {
                static bool loggedDumpPstateDfsZero = false;
                if (!loggedDumpPstateDfsZero) {
                    loggedDumpPstateDfsZero = true;
                    IOLog("AMDRyzenCPUPowerManagement::dumpPstate: curCpuDfsId is zero, clamping clock to 0\n");
                }
                clock = 0.0f;
            } else {
                clock = (float)((float)curCpuFid / (float)curCpuDfsId * 200.0);
            }
        }
        
        PStateDef_perCore[i] = msr_value_buf;
        PStateDefClock_perCore[i] = clock;
        
        if(msr_value_buf & ((uint64_t)1 << 63)) len++;
        //        IOLog("a: %llu", msr_value_buf);
    }
    
    if (len > kMSR_PSTATE_LEN) {
        static bool loggedPStateLenExceeded = false;
        if (!loggedPStateLenExceeded) {
            loggedPStateLenExceeded = true;
            IOLog("AMDRyzenCPUPowerManagement::dumpPstate WARN: Enabled P-States count (%u) exceeds AMD architectural limit (8). Clamping to 8.\n", len);
        }
        len = kMSR_PSTATE_LEN;
    }
    
    PStateEnabledLen = len;
}

void AMDRyzenCPUPowerManagement::reinitHwState() {
    uint32_t cpuid_eax = 0;
    uint32_t cpuid_ebx = 0;
    uint32_t cpuid_ecx = 0;
    uint32_t cpuid_edx = 0;

    CPUInfo::getCpuid(0x80000007, 0, &cpuid_eax, &cpuid_ebx, &cpuid_ecx, &cpuid_edx);
    cpbSupported = (cpuid_edx >> 9) & 0x1;

    // Probe CPPC support: read CAP1 MSR. All Zen families (17h/19h/1Ah) support CPPC,
    // but CPPC writes (ENABLE/REQ MSRs) are disabled in the current baseline.
    // CPPC writes may be enabled in a future profile update once validated.
    uint64_t cppcVal = 0;
    bool msrSuccess = read_msr(kMSR_AMD_CPPC_CAP1, &cppcVal);
    const bool zenFamily = (cpuFamily == 0x17 || cpuFamily == 0x19 || cpuFamily == 0x1A);

    // CPPC is supported if MSR reads successfully or CPU is a known Zen family.
    if (msrSuccess || zenFamily) {
        if (!cppcSupported) {
            cppcSupported = true;
        }
        IOLog("AMDRyzenCPUPowerManagement::reinitHwState: CPPC CAP1 readable (CAP1=0x%llx)\n", cppcVal);
    } else {
        cppcSupported = false;
    }

    // CPPC write paths (ENABLE/REQ) are disabled in the current baseline.
    // cppcActiveMode requires a future profile flag and boot-arg to enable.
    cppcActiveMode = checkKernelArgument("-amdcppcactive");
    // CPPC writes blocked until per-profile cppcWriteAllowed flag is implemented.
    if (cppcActiveMode) {
        cppcActiveMode = false;
        IOLog("AMDRyzenCPUPowerManagement::reinitHwState: CPPC Active Mode blocked — writes disabled in baseline\n");
    }
    
    uint64_t rapl = 0;
    if (read_msr(kMSR_RAPL_PWR_UNIT, &rapl)) {
        uint8_t energyStatusUnits = (rapl >> 8) & 0x1f;
        uint8_t timeUnits = (rapl >> 16) & 0x0f;
        pwrEnergyUnit = 1.0 / (double)(1ULL << energyStatusUnits);
        pwrTimeUnit = 1.0 / (double)(1ULL << timeUnits);
    } else {
        static bool loggedRaplFallback = false;
        if (!loggedRaplFallback) {
            loggedRaplFallback = true;
            IOLog("AMDRyzenCPUPowerManagement::reinitHwState WARN: failed to read MSR_RAPL_POWER_UNIT, using default 1/2^16 energy unit\n");
        }
        pwrEnergyUnit = 1.0 / (double)(1ULL << 16);
        pwrTimeUnit = 1.0 / (double)(1ULL << 10);
    }
    
    dumpPstate();
}

void AMDRyzenCPUPowerManagement::writePstate(const uint64_t *buf){
    if (!buf) {
        static bool loggedNullBuf = false;
        if (!loggedNullBuf) {
            loggedNullBuf = true;
            IOLog("AMDRyzenCPUPowerManagement::writePstate WARN: Null buffer passed\n");
        }
        return;
    }
    
    PStateEnabledLen = 0;
    
    //A bit hacky but at least works for now.
    void* args[] = {this, (void*)buf};


    IOLockLock(rendezvousLock);
    mp_rendezvous(nullptr, [](void *obj) {
        auto v = static_cast<uint64_t*>(((uint64_t**)obj)[1]);
        auto provider = static_cast<AMDRyzenCPUPowerManagement*>(*((AMDRyzenCPUPowerManagement**)obj));

        for (uint32_t i = 0; i < provider->kMSR_PSTATE_LEN; i++) {
            if (i >= 8) {
                static bool loggedIndexBound = false;
                if (!loggedIndexBound) {
                    loggedIndexBound = true;
                    IOLog("AMDRyzenCPUPowerManagement::writePstate WARN: P-state index %u out of bounds [0, 7]\n", i);
                }
                break;
            }
            uint64_t def = v[i];
            
            if (provider->cpuFamily >= 0x1A) {
                uint64_t curCpuFid = (def & 0xfff);
                uint64_t curCpuVid = ((def >> 14) & 0xff);
                if (!def || curCpuFid == 0 || curCpuVid > 0xFF) {
                    static bool loggedInvalidZen5Vals = false;
                    if (!loggedInvalidZen5Vals) {
                        loggedInvalidZen5Vals = true;
                        IOLog("AMDRyzenCPUPowerManagement::writePstate WARN: Invalid Zen 5 P-state values (def=0x%llx, Fid=%llu, Vid=%llu)\n", def, curCpuFid, curCpuVid);
                    }
                    continue;
                }
            } else {
                uint64_t curCpuDfsId = ((def >> 8) & 0x3f);
                uint64_t curCpuFid = (def & 0xff);
                uint64_t curCpuVid = ((def >> 14) & 0xff);
                if (!def || curCpuDfsId == 0 || curCpuFid == 0 || curCpuVid > 0xFF) {
                    static bool loggedInvalidVals = false;
                    if (!loggedInvalidVals) {
                        loggedInvalidVals = true;
                        IOLog("AMDRyzenCPUPowerManagement::writePstate WARN: Invalid P-state values (def=0x%llx, DfsId=%llu, Fid=%llu, Vid=%llu)\n", def, curCpuDfsId, curCpuFid, curCpuVid);
                    }
                    continue;
                }
            }
            
            provider->write_msr(provider->kMSR_PSTATE_0 + i, def);
            
        }
    
        
        if(!pmRyzen_cpu_is_master(cpu_number())) return;
        provider->dumpPstate();

    }, nullptr, args);
    IOLockUnlock(rendezvousLock);

}

bool AMDRyzenCPUPowerManagement::initSuperIO(uint16_t *chipIntel){
    if (!superIOLock) return false;
    IOLockLock(superIOLock);
    if (superIO) { delete superIO; superIO = nullptr; }
    if(!superIO) superIO = ISSuperIONCT668X::getDevice(&savedSMCChipIntel);
    if(!superIO) superIO = ISSuperIONCT67XXFamily::getDevice(&savedSMCChipIntel);
    if(!superIO) superIO = ISSuperIOIT86XXEFamily::getDevice(&savedSMCChipIntel);
    
    *chipIntel = savedSMCChipIntel;
    bool ok = superIO != nullptr;
    IOLockUnlock(superIOLock);
    return ok;
}

uint32_t AMDRyzenCPUPowerManagement::getPMPStateLimit(){
    return pmRyzen_pstatelimit;
}

void AMDRyzenCPUPowerManagement::setPMPStateLimit(uint32_t state){
    pmRyzen_pstatelimit = min(2, state);
    if(state > 0){
        pmRyzen_PState_reset();
    }
}

uint32_t AMDRyzenCPUPowerManagement::getHPcpus(){
    return pmRyzen_hpcpus;
}

void AMDRyzenCPUPowerManagement::evaluateFanCurves() {
    if (!superIOLock) return;
    IOLockLock(superIOLock);
    if (!superIO) {
        IOLockUnlock(superIOLock);
        return;
    }
    
    // 1. Get raw current temperatures
    float cpuTemp = getPackageTemp();
    float gpuTemp = gpuTempC;
    
    uint64_t now = getCurrentTimeNs();
    
    for (int fanIdx = 0; fanIdx < superIO->getNumberOfFans(); fanIdx++) {
        int8_t curveIdx = fanToCurveMap[fanIdx];
        if (curveIdx < 0 || curveIdx >= MAX_FAN_CURVES) {
            continue; // Default BIOS Auto control
        }
        
        FanCurveConfig &config = fanCurves[curveIdx];
        
        // 2. Select temperature source
        float rawSourceTemp = cpuTemp;
        if (config.sourceSensor == 1) {
            rawSourceTemp = gpuTemp > 0.0f ? gpuTemp : cpuTemp; // Fallback to CPU if GPU not updated
        }
        
        // 3. Apply Exponential Moving Average (EMA) for temperature input
        float alpha = 0.2f;
        float prevSmoothed = curveSmoothedTemp[curveIdx];
        float smoothed = (alpha * rawSourceTemp) + ((1.0f - alpha) * prevSmoothed);
        curveSmoothedTemp[curveIdx] = smoothed;
        
        // 4. Map temperature index (0 - 255) with proper rounding
        int tempIdx = (int)(smoothed + 0.5f);
        if (tempIdx < 0) tempIdx = 0;
        if (tempIdx > 255) tempIdx = 255;
        
        // 5. Look up target PWM from LUT
        uint8_t targetPWM = config.lut[tempIdx];
        
        uint8_t currentPWM = lastAppliedPWM[fanIdx];
        uint64_t lastTime = lastPWMUpdateTime[fanIdx];
        
        // 7. Enforce Hysteresis and Ramp Rate Limiting
        if (currentPWM > 0 && targetPWM != 0) {
            double deltaTime = (double)HF_TEMP_SAMPLE_PERIOD / 1000.0;
            if (lastTime > 0 && now > lastTime) {
                deltaTime = (double)(now - lastTime) / 1e9;
            }
            
            // Check temperature delta for hysteresis
            float tempDelta = rawSourceTemp - prevSmoothed;
            if (tempDelta < 0.0f && -tempDelta < (float)config.hysteresis) {
                targetPWM = currentPWM;
            } else {
                // Limit the speed change to config.rampRate
                float deltaPWM = (float)targetPWM - (float)currentPWM;
                float limit = (float)config.rampRate * (float)deltaTime;
                if (limit < 1.0f) limit = 1.0f; // Ensure at least 1 PWM step can change
                
                if (deltaPWM > limit) {
                    targetPWM = (uint8_t)(currentPWM + limit);
                } else if (deltaPWM < -limit) {
                    targetPWM = (uint8_t)(currentPWM - limit);
                }
            }
        }
        
        // 7.5. Apply Thermal Safety Guard (above kTHERMAL_GUARD_TEMP_C, force at least kTHERMAL_GUARD_PWM)
        if (rawSourceTemp >= kTHERMAL_GUARD_TEMP_C) {
            targetPWM = (targetPWM < kTHERMAL_GUARD_PWM) ? kTHERMAL_GUARD_PWM : targetPWM;
        }
        
        // 8. Apply PWM override to the Super I/O chip
        if (targetPWM == 0) {
            superIO->setDefaultFanControl(fanIdx);
            lastAppliedPWM[fanIdx] = 0;
        } else {
            superIO->overrideFanControl(fanIdx, targetPWM);
            lastAppliedPWM[fanIdx] = targetPWM;
        }
        lastPWMUpdateTime[fanIdx] = now;
    }
    IOLockUnlock(superIOLock);
}

EXPORT extern "C" kern_return_t amdryzencpupm_kern_start(kmod_info_t *, void *) {
    // Report success but actually do not start and let I/O Kit unload us.
    // This works better and increases boot speed in some cases.
    PE_parse_boot_argn("liludelay", &ADDPR(debugPrintDelay), sizeof(ADDPR(debugPrintDelay)));
    ADDPR(debugEnabled) = checkKernelArgument("-amdpdbg");
    
    return KERN_SUCCESS;
}

EXPORT extern "C" kern_return_t amdryzencpupm_kern_stop(kmod_info_t *, void *) {
    // It is not safe to unload VirtualSMC plugins!
    return KERN_FAILURE;
}
