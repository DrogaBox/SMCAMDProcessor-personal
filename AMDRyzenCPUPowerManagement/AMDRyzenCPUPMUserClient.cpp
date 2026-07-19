//
//  AMDRyzenCPUPowerManagementUserClient.cpp
//  AMDRyzenCPUPowerManagement
//
//  Created by trulyspinach, modified by Droga (2026) on 2/4/20.
//

#include "AMDRyzenCPUPMUserClient.hpp"

OSDefineMetaClassAndStructors(AMDRyzenCPUPMUserClient, IOUserClient);


bool AMDRyzenCPUPMUserClient::initWithTask(task_t owningTask,
                                             void *securityToken,
                                             UInt32 type,
                                             OSDictionary *properties){
    
    if(!IOUserClient::initWithTask(owningTask, securityToken, type, properties)){
        return false;
    }
    
    token = securityToken;
    fOwningTask = owningTask;
    
    proc_t proc = (proc_t)get_bsdtask_info(owningTask);
    if (!proc) return false;
    
    // Capture binary name for audit logging only — never use it for authorization.
    proc_name(proc_pid(proc), taskProcessBinaryName, sizeof(taskProcessBinaryName));
    taskProcessBinaryName[sizeof(taskProcessBinaryName) - 1] = '\0';
    
    // Authorization model (v3.16.1):
    // - Always allow the UserClient connection so monitoring apps (menu bar) can
    //   open the service as a normal user and read telemetry.
    // - Privilege for WRITE selectors (MSR/SMU/fan/Curve Optimizer) is enforced
    //   per-call via hasPrivilege() — root or boot-arg -amdpnopchk only.
    // - Do NOT return false for non-root here: that makes IOServiceOpen fail and
    //   the GUI shows a false "kext not found" error.
    bool isRoot = (proc_suser(proc) == 0 || kauth_cred_getuid(proc_ucred(proc)) == 0);
    bool isDebugBypass = checkKernelArgument("-amdpnopchk");
    
    if (isRoot || isDebugBypass) {
        IOLog("AMDRyzenCPUPMUserClient: ACCEPTED privileged pid=%d binary='%s' (root=%d debug=%d)\n",
              proc_pid(proc), taskProcessBinaryName, isRoot, isDebugBypass);
    } else {
        IOLog("AMDRyzenCPUPMUserClient: ACCEPTED read-only pid=%d binary='%s' (writes require root or -amdpnopchk)\n",
              proc_pid(proc), taskProcessBinaryName);
    }
    
    return true;
}

bool AMDRyzenCPUPMUserClient::start(IOService *provider){
    IOLog("AMDRyzenCPUPMUserClient::start\n");
    bool success = IOService::start(provider);
    if(success){
        fProvider = OSDynamicCast(AMDRyzenCPUPowerManagement, provider);
    }
    return success;
}

void AMDRyzenCPUPMUserClient::stop(IOService *provider){
    IOLog("AMDRyzenCPUPMUserClient::stop\n");
    fProvider = nullptr;
    IOService::stop(provider);
}

bool AMDRyzenCPUPMUserClient::hasPrivilege(uint32_t selector){
    // Boot-arg bypass: allow writes without root when -amdpnopchk is present
    if (fProvider && fProvider->disablePrivilegeCheck) return true;
    
    // Re-validate root privilege on every call (audit B-1). This adds a small
    // per-call overhead but is negligible for write selectors that are invoked
    // infrequently (user-initiated control changes). It prevents a scenario
    // where a process opens a UserClient connection as root, then drops
    // privileges — the cached flag would incorrectly remain true.
    proc_t proc = (proc_t)get_bsdtask_info(fOwningTask);
    if (proc && (proc_suser(proc) == 0 || kauth_cred_getuid(proc_ucred(proc)) == 0))
        return true;
    
    IOLog("AMDRyzenCPUPMUserClient: DENIED select %u pid=%d binary='%s' (need root or -amdpnopchk)\n",
          selector, proc_selfpid(), taskProcessBinaryName);
    return false;
}

IOReturn AMDRyzenCPUPMUserClient::externalMethod(uint32_t selector, IOExternalMethodArguments *arguments,
                                                 IOExternalMethodDispatch *dispatch,
                                                   OSObject *target, void *reference){
    AMDRyzenCPUPowerManagement *provider = fProvider;
    if (!provider) return kIOReturnNotReady;
    
    // Surface kext-load alerts at most once across concurrent UserClient connections.
    // OSCompareAndSwap makes the check-and-set atomic (audit R-6).
    if (provider->kextloadAlerts && provider->kunc_alert) {
        if (OSCompareAndSwap(0, 1, &provider->kextAlertDisplayed)) {
            unsigned int rf = 0;
            
            char buf[128];
            snprintf(buf, 128,
                     "Kext alert detected: %d",
                     provider->kextloadAlerts);
            
            (*(provider->kunc_alert))(0, 0, NULL, NULL, NULL,
                          "AMDRyzenCPUPowerManagement", buf, "Ok", "Ok and Clear Alert", "WTF?", &rf);
            if (rf == 1) {
                provider->kextloadAlerts = 0;
                OSCompareAndSwap(1, 0, &provider->kextAlertDisplayed);
            }
        }
    }
    
    provider->registerRequest();
    
    switch (selector) {
            
        //Get PStateDef raw values for core 0
        case 0: {
            arguments->scalarOutputCount = 0;
            
            uint32_t requiredSize = (provider->kMSR_PSTATE_LEN) * sizeof(uint64_t);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;
            
            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }

            uint64_t *dataOut = (uint64_t*) arguments->structureOutput;
            uint32_t copyCount = (maxLen / sizeof(uint64_t) < provider->kMSR_PSTATE_LEN) ? (maxLen / sizeof(uint64_t)) : provider->kMSR_PSTATE_LEN;
            
            for(uint32_t i = 0; i < copyCount; i++){
                dataOut[i] = provider->PStateDef_perCore[i];
            }
            
            break;
        }
            
            
        //Get PStateDef floating point clock values for core 0
        case 1: {
            arguments->scalarOutputCount = 0;
            
            uint32_t requiredSize = (provider->kMSR_PSTATE_LEN) * sizeof(float);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;

            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }

            float *dataOut = (float*) arguments->structureOutput;
            uint32_t copyCount = (maxLen / sizeof(float) < provider->kMSR_PSTATE_LEN) ? (maxLen / sizeof(float)) : provider->kMSR_PSTATE_LEN;
            
            for(uint32_t i = 0; i < copyCount; i++){
                dataOut[i] = provider->PStateDefClock_perCore[i];
            }
            
            break;
        }
            
        case 2: {
            uint32_t numPhyCores = provider->totalNumberOfPhysicalCores;

            arguments->scalarOutputCount = 1;
            arguments->scalarOutput[0] = numPhyCores;
            
            uint32_t requiredSize = numPhyCores * sizeof(float);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;

            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }

            float *dataOut = (float*) arguments->structureOutput;
            uint32_t copyCount = (maxLen / sizeof(float) < numPhyCores) ? (maxLen / sizeof(float)) : numPhyCores;

            for(uint32_t i = 0; i < copyCount; i++){
                dataOut[i] = provider->effFreq_perCore[i];
            }
            
            break;
        }
        
        case 3: {
            arguments->scalarOutputCount = 0;
            
            uint32_t requiredSize = 1 * sizeof(float);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;

            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }
            
            float *dataOut = (float*) arguments->structureOutput;
            if (maxLen >= sizeof(float)) {
                dataOut[0] = provider->PACKAGE_TEMPERATURE_perPackage[0];
            }
            break;
        }
        
        //Get all data like this: [power, temp, pstateCur, clock_core_1, 2, 3 .....]
        //Yes, i am too lazy to write a struct
        case 4: {
            uint32_t numPhyCores = provider->totalNumberOfPhysicalCores;
            arguments->scalarOutputCount = 1;
            arguments->scalarOutput[0] = numPhyCores;
            
            uint32_t requiredSize = (numPhyCores + 3) * sizeof(float);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;

            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }

            uint32_t copyLen = (maxLen < requiredSize) ? maxLen : requiredSize;
            float *dataOut = (float*) arguments->structureOutput;
            
            if (copyLen >= 1 * sizeof(float)) dataOut[0] = (float)provider->uniPackagePowerW;
            if (copyLen >= 2 * sizeof(float)) dataOut[1] = provider->PACKAGE_TEMPERATURE_perPackage[0];
            if (copyLen >= 3 * sizeof(float)) dataOut[2] = (float)provider->PStateCtl;
            
            uint32_t copyCount = (copyLen > 3 * sizeof(float)) ? (copyLen - 3 * sizeof(float)) / sizeof(float) : 0;
            for(uint32_t i = 0; i < copyCount; i++){
                dataOut[i + 3] = provider->effFreq_perCore[i];
            }
            
            break;
        }
            
        //Get per core raw load index
        case 5: {
            arguments->scalarOutputCount = 0;
            
            uint32_t requiredSize = 1 * sizeof(uint64_t);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;

            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }

            uint64_t *dataOut = (uint64_t*) arguments->structureOutput;
            
            if (maxLen >= sizeof(uint64_t)) {
                dataOut[0] = 0;
                uint32_t numLogCores = provider->totalNumberOfLogicalCores;
                if (numLogCores > CPUInfo::MaxCpus) {
                    numLogCores = CPUInfo::MaxCpus;
                }
                for(uint32_t i = 0; i < numLogCores; i++){
                    dataOut[0] += provider->instructionDelta_perCore[i];
                }
            }
            
            break;
        }
            
        //Get per core load index
        case 6: {
            arguments->scalarOutputCount = 0;
            
            uint32_t requiredSize = (provider->totalNumberOfPhysicalCores) * sizeof(float);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;

            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }

            float *dataOut = (float*) arguments->structureOutput;
            
            int lcpu_percore = 1;
            if (provider->totalNumberOfPhysicalCores > 0) {
                lcpu_percore = provider->totalNumberOfLogicalCores / provider->totalNumberOfPhysicalCores;
            }
            if (lcpu_percore <= 0) {
                lcpu_percore = 1;
            }
            
            uint32_t copyCount = (maxLen / sizeof(float) < provider->totalNumberOfPhysicalCores) ? (maxLen / sizeof(float)) : provider->totalNumberOfPhysicalCores;
            
            for(uint32_t i = 0; i < copyCount; i++){
                float l = pmRyzen_avgload_pcpu(i * lcpu_percore);
                dataOut[i] = l;
            }
            
            break;
        }
            
        //Get basic CPUID
        //[Family, Model, Physical, Logical, L1_perCore, L2_perCore, L3]
        case 7: {
            arguments->scalarOutputCount = 0;
            
            uint32_t requiredSize = (8) * sizeof(uint64_t);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;

            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }

            uint64_t *dataOut = (uint64_t*) arguments->structureOutput;
            uint32_t copyCount = (maxLen / sizeof(uint64_t) < 8) ? (maxLen / sizeof(uint64_t)) : 8;
            
            if (copyCount > 0) dataOut[0] = (uint64_t)provider->cpuFamily;
            if (copyCount > 1) dataOut[1] = (uint64_t)provider->cpuModel;
            if (copyCount > 2) dataOut[2] = (uint64_t)provider->totalNumberOfPhysicalCores;
            if (copyCount > 3) dataOut[3] = (uint64_t)provider->totalNumberOfLogicalCores;
            if (copyCount > 4) dataOut[4] = (uint64_t)provider->cpuCacheL1_perCore;
            if (copyCount > 5) dataOut[5] = (uint64_t)provider->cpuCacheL2_perCore;
            if (copyCount > 6) dataOut[6] = (uint64_t)provider->cpuCacheL3;
            if (copyCount > 7) dataOut[7] = (uint64_t)provider->cpuSupportedByCurrentVersion;
            
            break;
        }
        
        //Get AMDRyzenCPUPowerManagement Version String
        case 8: {
            arguments->scalarOutputCount = 0;
            
            uint32_t requiredSize = sizeof(xStringify(MODULE_VERSION));
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;
            
            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }
            
            char *dataOut = (char*) arguments->structureOutput;
            uint32_t copyLen = (maxLen < requiredSize) ? maxLen : requiredSize;
            for (uint32_t i = 0; i < copyLen; i++) {
                dataOut[i] = xStringify(MODULE_VERSION)[i];
            }
            
            break;
        }
        
        //Get PState
        case 9: {
            arguments->scalarOutputCount = 0;
            
            uint32_t requiredSize = 1 * sizeof(uint64_t);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;
            
            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }
            
            uint64_t *dataOut = (uint64_t*) arguments->structureOutput;

            if (maxLen >= sizeof(uint64_t)) {
                dataOut[0] = provider->PStateCtl;
            }
            
            break;
        }
        
        //Set PState
        case 10: {
            if(!hasPrivilege(10)) return kIOReturnNotPrivileged;
            arguments->scalarOutputCount = 0;
            arguments->structureOutputSize = 0;
            
            if(arguments->scalarInputCount != 1)
                return kIOReturnBadArgument;
            
            // controlLock protects PStateCtl + applyPowerControl as an atomic
            // critical section against concurrent UserClient calls (audit K-2).
            if (provider->controlLock) IOLockLock(provider->controlLock);
            provider->PStateCtl = (uint8_t)arguments->scalarInput[0];
            provider->applyPowerControl();
            if (provider->controlLock) IOLockUnlock(provider->controlLock);
            break;
        }

        // Zero-copy streaming structured telemetry packet (Task 1.2)
        case 100: {
            arguments->scalarOutputCount = 0;
            uint32_t requiredSize = sizeof(AMDRyzenCPUPowerManagement::CPUSensorPacket);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;
            
            if (!arguments->structureOutput || maxLen < requiredSize) {
                return kIOReturnBadArgument;
            }
            
            AMDRyzenCPUPowerManagement::CPUSensorPacket *packet = (AMDRyzenCPUPowerManagement::CPUSensorPacket*) arguments->structureOutput;
            packet->packagePowerW = (float)provider->uniPackagePowerW;
            packet->packageTempC = provider->PACKAGE_TEMPERATURE_perPackage[0];
            packet->numLogicalCores = provider->totalNumberOfLogicalCores;
            packet->ccdCount = provider->ccdCount;
            for (uint32_t i = 0; i < 8; i++) {
                packet->ccdTemperatures[i] = (i < provider->ccdCount) ? provider->ccdTemperatures[i] : 0.0f;
            }
            for (uint32_t i = 0; i < 64 && i < provider->totalNumberOfLogicalCores; i++) {
                uint32_t phys = (provider->totalNumberOfPhysicalCores > 0)
                    ? (i % provider->totalNumberOfPhysicalCores) : i;
                packet->coreFrequenciesMHz[i] = provider->effFreq_perCore[phys];
            }
            break;
        }
            
        //Get CPB
        case 11: {
            arguments->scalarOutputCount = 0;
            
            uint32_t requiredSize = 2 * sizeof(uint64_t);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;
            
            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }
            
            uint64_t *dataOut = (uint64_t*) arguments->structureOutput;

            if (maxLen >= sizeof(uint64_t)) {
                dataOut[0] = (uint64_t)provider->cpbSupported;
            }
            if (maxLen >= 2 * sizeof(uint64_t)) {
                dataOut[1] = (uint64_t)provider->getCPBState();
            }
            break;
        }
        
        //Set CPB
        case 12: {
            if(!hasPrivilege(12)) return kIOReturnNotPrivileged;
            arguments->scalarOutputCount = 0;
            arguments->structureOutputSize = 0;
            
            if(arguments->scalarInputCount != 1)
                return kIOReturnBadArgument;
            
            if(!provider->cpbSupported)
                return kIOReturnNoDevice;
            
            provider->setCPBState(arguments->scalarInput[0]==1?true:false);
            
            break;
        }
            
        //Get PPM
        case 13: {
            arguments->scalarOutputCount = 0;
                
            uint32_t requiredSize = 1 * sizeof(uint64_t);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;
                
            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }
            
            uint64_t *dataOut = (uint64_t*) arguments->structureOutput;

            if (maxLen >= sizeof(uint64_t)) {
                dataOut[0] = (uint64_t)(provider->getPMPStateLimit() == 0 ? 0 : 1);
            }
            break;
        }
            
        //Set PPM
        case 14: {
            if(!hasPrivilege(14)) return kIOReturnNotPrivileged;
            arguments->scalarOutputCount = 0;
            arguments->structureOutputSize = 0;
                
            if(arguments->scalarInputCount != 1)
                return kIOReturnBadArgument;
                
            boolean_t enabled = arguments->scalarInput[0]==1?true:false;
            
            provider->setPMPStateLimit(enabled ? 1 : 0);
            
            break;
        }
            
        //Set PStateDef
        case 15: {
            if(!hasPrivilege(15))
                return kIOReturnNotPrivileged;
            
            if(arguments->scalarInputCount != 8)
                return kIOReturnBadArgument;
            
            
            provider->writePstate(arguments->scalarInput);
            
            break;
        }
            
        //get board info
        case 16: {
            //Let's give that one more try :)
            if(!provider->boardInfoValid)
                provider->fetchOEMBaseBoardInfo();
            
            arguments->scalarOutputCount = 1;
            arguments->scalarOutput[0] = provider->boardInfoValid ? 1 : 0;
            
            uint32_t requiredSize = 128;
            uint32_t maxLen = arguments->structureOutputSize;
            uint32_t copyLen = maxLen < requiredSize ? maxLen : requiredSize;
            arguments->structureOutputSize = copyLen;
            
            if (!arguments->structureOutput || maxLen == 0) {
                return kIOReturnBadArgument;
            }
            
            char *dataOut = (char*) arguments->structureOutput;
            memset(dataOut, 0, copyLen);
            
            if (copyLen > 0) {
                size_t vendorCopy = copyLen < 64 ? copyLen : 64;
                strlcpy(dataOut, provider->boardVendor, vendorCopy);
            }
            if (copyLen > 64) {
                size_t nameCopy = (copyLen - 64) < 64 ? (copyLen - 64) : 64;
                strlcpy(dataOut + 64, provider->boardName, nameCopy);
            }
            
            break;
        }
            
        case 17: {
            arguments->scalarOutputCount = 0;
                
            uint32_t requiredSize = 1 * sizeof(uint64_t);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;
                
            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }
            
            uint64_t *dataOut = (uint64_t*) arguments->structureOutput;

            if (maxLen >= sizeof(uint64_t)) {
                dataOut[0] = (uint64_t)(provider->getHPcpus());
            }
            break;
        }
        
        //Get LPM
        case 18: {
            arguments->scalarOutputCount = 0;
                
            uint32_t requiredSize = 1 * sizeof(uint64_t);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;
                
            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }
            
            uint64_t *dataOut = (uint64_t*) arguments->structureOutput;

            if (maxLen >= sizeof(uint64_t)) {
                dataOut[0] = (uint64_t)(provider->getPMPStateLimit() == 2 ? 1 : 0);
            }
            break;
        }
            
        //Set LPM
        case 19: {
            if(!hasPrivilege(19)) return kIOReturnNotPrivileged;
            arguments->scalarOutputCount = 0;
            arguments->structureOutputSize = 0;
                
            if(arguments->scalarInputCount != 1)
                return kIOReturnBadArgument;
                
            boolean_t enabled = arguments->scalarInput[0]==1?true:false;
            
            provider->setPMPStateLimit(enabled ? 2 : 1);
            
            break;
        }
            
        //Get CCD temperatures
        case 20: {
            uint32_t ccdCount = provider->ccdCount;
            arguments->scalarOutputCount = 1;
            arguments->scalarOutput[0] = ccdCount;
            
            uint32_t requiredSize = ccdCount * sizeof(float);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;

            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }

            float *dataOut = (float*) arguments->structureOutput;
            uint32_t copyCount = (maxLen / sizeof(float) < ccdCount) ? (maxLen / sizeof(float)) : ccdCount;
            
            if (provider->controlLock) IOLockLock(provider->controlLock);
            for(uint32_t i = 0; i < copyCount; i++){
                dataOut[i] = provider->ccdTemperatures[i];
            }
            if (provider->controlLock) IOLockUnlock(provider->controlLock);
            
            break;
        }
        
        // Get CPPC Highest Performance values per logical core
        case 21: {
            uint32_t numLogicalCores = provider->totalNumberOfLogicalCores;

            arguments->scalarOutputCount = 1;
            arguments->scalarOutput[0] = provider->cppcSupported ? 1 : 0;
            
            uint32_t requiredSize = numLogicalCores * sizeof(uint8_t);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;

            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }
            
            uint8_t *dataOut = (uint8_t*) arguments->structureOutput;
            uint32_t copyLen = (maxLen < requiredSize) ? maxLen : requiredSize;
            
            for(uint32_t i = 0; i < copyLen; i++) {
                dataOut[i] = provider->cppcHighestPerf_perCore[i];
            }
            break;
        }

        // Get C-State address configuration
        case 22: {
            arguments->scalarOutputCount = 1;
            arguments->scalarOutput[0] = provider->cstateAddrConfig;
            
            break;
        }
        
        // Get CPPC Active Mode status and current EPP value
        case 23: {
            arguments->scalarOutputCount = 2;
            arguments->scalarOutput[0] = provider->cppcActiveMode ? 1 : 0;
            arguments->scalarOutput[1] = provider->cppcEPPValue;
            
            break;
        }
        
        // Set CPPC Active Mode status
        case 24: {
            if (!hasPrivilege(24))
                return kIOReturnNotPrivileged;
                
            if (arguments->scalarInputCount != 1)
                return kIOReturnBadArgument;
                
            // controlLock protects cppcActiveMode + applyEPPControl as an atomic
            // critical section against concurrent UserClient calls (audit K-2).
            if (provider->controlLock) IOLockLock(provider->controlLock);
            provider->cppcActiveMode = (arguments->scalarInput[0] == 1);
            if (provider->cppcActiveMode) {
                provider->applyEPPControl();
            }
            if (provider->controlLock) IOLockUnlock(provider->controlLock);
            
            break;
        }
        
        // Set CPPC EPP Value
        case 25: {
            if (!hasPrivilege(25))
                return kIOReturnNotPrivileged;
                
            if (arguments->scalarInputCount != 1)
                return kIOReturnBadArgument;
                
            // controlLock protects cppcEPPValue + applyEPPControl as an atomic
            // critical section against concurrent UserClient calls (audit K-2).
            if (provider->controlLock) IOLockLock(provider->controlLock);
            provider->cppcEPPValue = (uint8_t)arguments->scalarInput[0];
            if (provider->cppcActiveMode) {
                provider->applyEPPControl();
            }
            if (provider->controlLock) IOLockUnlock(provider->controlLock);
            
            break;
        }
        
        // Get CPU profile info: architecture name + capability flags.
        // Structure output: cpuArchName (16 bytes) packed as chars,
        // followed by capability flags as uint64.
        // Flags bit layout:
        //   bit 0: pmDispatchAllowed
        //   bit 1: legacyPstateAllowed
        //   bit 2: supportsCPPC
        //   bits 3-7: reserved
        case 26: {
            arguments->scalarOutputCount = 0;
            
            uint32_t nameSize = 16;
            uint32_t flagsSize = sizeof(uint64_t);
            uint32_t requiredSize = nameSize + flagsSize;
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;
            
            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }
            
            char *dataOut = (char*) arguments->structureOutput;
            memset(dataOut, 0, maxLen);
            
            // Copy architecture name (first 16 bytes)
            uint32_t nameCopy = (maxLen < nameSize) ? maxLen : nameSize;
            if (nameCopy > 0) {
                strlcpy(dataOut, provider->cpuArchName, nameCopy);
            }
            
            // Pack capability flags into uint64 after the name
            if (maxLen >= nameSize + flagsSize) {
                uint64_t flags = 0;
                if (provider->pmDispatchAllowed)    flags |= (1ULL << 0);
                if (provider->legacyPstateAllowed)  flags |= (1ULL << 1);
                if (provider->supportsCPPC)         flags |= (1ULL << 2);
                memcpy(dataOut + nameSize, &flags, flagsSize);
            }
            
            break;
        }
        
        //Try load SMC driver
        case 90: {
            arguments->scalarOutputCount = 0;
            uint32_t requiredSize = 2 * sizeof(uint64_t);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;
            
            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }
            
            uint64_t *dataOut = (uint64_t*) arguments->structureOutput;
            
            // Snapshot under superIOLock (audit R-1). initSuperIO also takes the lock
            // (non-recursive) so we must not hold it across that call.
            if (provider->superIOLock) {
                IOLockLock(provider->superIOLock);
                if (provider->superIO != nullptr) {
                    if (maxLen >= sizeof(uint64_t)) {
                        dataOut[0] = (uint64_t)(1);
                    }
                    if (maxLen >= 2 * sizeof(uint64_t)) {
                        dataOut[1] = (uint64_t)(provider->savedSMCChipIntel);
                    }
                    IOLockUnlock(provider->superIOLock);
                    break;
                }
                IOLockUnlock(provider->superIOLock);
            }
            
            uint16_t ci = 0;
            bool found = provider->initSuperIO(&ci);
            
            if (maxLen >= sizeof(uint64_t)) {
                dataOut[0] = (uint64_t)(found ? 1 : 0);
            }
            if (maxLen >= 2 * sizeof(uint64_t)) {
                dataOut[1] = (uint64_t)(ci);
            }
            
            break;
        }
        
        //SMC load number of fans
        case 91: {
            if (!provider->superIOLock)
                return kIOReturnNoDevice;

            uint32_t requiredSize = 1 * sizeof(uint64_t);
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;
            
            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }
            
            uint64_t *dataOut = (uint64_t*) arguments->structureOutput;
            
            IOLockLock(provider->superIOLock);
            if (!provider->superIO) {
                IOLockUnlock(provider->superIOLock);
                return kIOReturnNoDevice;
            }
            uint32_t numFans = (uint32_t)provider->superIO->getNumberOfFans();
            IOLockUnlock(provider->superIOLock);
            
            if (maxLen >= sizeof(uint64_t)) {
                dataOut[0] = (uint64_t)numFans;
            }
            break;
        }
        
        //SMC load readable desc for fan
        case 92: {
            if (!provider->superIOLock)
                return kIOReturnNoDevice;

            arguments->scalarOutputCount = 0;
                
            if(arguments->scalarInputCount != 1)
                return kIOReturnBadArgument;
            
            uint32_t maxLen = arguments->structureOutputSize;
            if (!arguments->structureOutput || maxLen == 0) {
                arguments->structureOutputSize = 0;
                return kIOReturnBadArgument;
            }
            
            char *dataOut = (char*) arguments->structureOutput;
            char localBuf[64] = {0};
            
            IOLockLock(provider->superIOLock);
            if (!provider->superIO) {
                IOLockUnlock(provider->superIOLock);
                return kIOReturnNoDevice;
            }
            const char *str = provider->superIO->getReadableStringForFan((int)arguments->scalarInput[0]);
            if (!str) {
                str = "";
            }
            // Copy under lock so the SuperIO object cannot be deleted mid-read.
            strlcpy(localBuf, str, sizeof(localBuf));
            IOLockUnlock(provider->superIOLock);
            
            strlcpy(dataOut, localBuf, maxLen);
            arguments->structureOutputSize = (uint32_t)strlen(dataOut);
            
            break;
        }
            
        //SMC fan rpms
        case 93: {
            if (!provider->superIOLock)
                return kIOReturnNoDevice;
            
            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }
            
            uint64_t *dataOut = (uint64_t*) arguments->structureOutput;
            uint32_t maxLen = arguments->structureOutputSize;
            
            IOLockLock(provider->superIOLock);
            if (!provider->superIO) {
                IOLockUnlock(provider->superIOLock);
                return kIOReturnNoDevice;
            }
            
            uint32_t numFans = (uint32_t)provider->superIO->getNumberOfFans();
            uint32_t requiredSize = numFans * sizeof(uint64_t);
            arguments->structureOutputSize = requiredSize;
            
            UInt32 currentCount = (UInt32)OSIncrementAtomic(&provider->fanUpdateCounter);
            if ((currentCount % 4) == 0) {
                provider->superIO->updateFanRPMS();
            }
            uint32_t copyCount = (maxLen / sizeof(uint64_t) < numFans) ? (maxLen / sizeof(uint64_t)) : numFans;
            for (uint32_t i = 0; i < copyCount; i++) {
                dataOut[i] = provider->superIO->getRPMForFan(i);
            }
            IOLockUnlock(provider->superIOLock);
            
            break;
        }
        
        //SMC fan throttles and control mode
        case 94: {
            if (!provider->superIOLock)
                return kIOReturnNoDevice;
            
            if (!arguments->structureOutput) {
                return kIOReturnBadArgument;
            }
            
            uint64_t *dataOut = (uint64_t*) arguments->structureOutput;
            uint32_t maxLen = arguments->structureOutputSize;
            
            IOLockLock(provider->superIOLock);
            if (!provider->superIO) {
                IOLockUnlock(provider->superIOLock);
                return kIOReturnNoDevice;
            }
            
            uint32_t numFans = (uint32_t)provider->superIO->getNumberOfFans();
            uint32_t requiredSize = numFans * sizeof(uint64_t);
            arguments->structureOutputSize = requiredSize;
            
            UInt32 snap94 = (UInt32)provider->fanUpdateCounter;
            if ((snap94 % 4) == 0) {
                provider->superIO->updateFanControl();
            }
            uint32_t copyCount = (maxLen / sizeof(uint64_t) < numFans) ? (maxLen / sizeof(uint64_t)) : numFans;
            for (uint32_t i = 0; i < copyCount; i++) {
                dataOut[i] = provider->superIO->getFanThrottle(i) << 8 | (provider->superIO->getFanAutoControlMode(i) ? 1 : 0);
            }
            IOLockUnlock(provider->superIOLock);
            
            break;
        }
        
        //SMC fan override control
        case 95: {
            if(!hasPrivilege(95))
                return kIOReturnNotPrivileged;
            
            if(arguments->scalarInputCount != 2)
                return kIOReturnBadArgument;
            
            if (!provider->superIOLock)
                return kIOReturnNoDevice;
            
            int fanSel = (int)arguments->scalarInput[0];
            uint8_t pwm = (uint8_t)arguments->scalarInput[1];
            
            IOLockLock(provider->superIOLock);
            if (!provider->superIO) {
                IOLockUnlock(provider->superIOLock);
                return kIOReturnNoDevice;
            }
            if (fanSel < 0 || fanSel >= provider->superIO->getNumberOfFans()) {
                IOLockUnlock(provider->superIOLock);
                return kIOReturnBadArgument;
            }
            provider->superIO->overrideFanControl(fanSel, pwm);
            IOLockUnlock(provider->superIOLock);
            
            break;
        }
        
        //SMC fan default control
        case 96: {
            if(!hasPrivilege(96))
                return kIOReturnNotPrivileged;
            
            if(arguments->scalarInputCount != 1)
                return kIOReturnBadArgument;
            
            if (!provider->superIOLock)
                return kIOReturnNoDevice;
            
            int fanSel = (int)arguments->scalarInput[0];
            
            IOLockLock(provider->superIOLock);
            if (!provider->superIO) {
                IOLockUnlock(provider->superIOLock);
                return kIOReturnNoDevice;
            }
            if (fanSel < 0 || fanSel >= provider->superIO->getNumberOfFans()) {
                IOLockUnlock(provider->superIOLock);
                return kIOReturnBadArgument;
            }
            provider->superIO->setDefaultFanControl(fanSel);
            IOLockUnlock(provider->superIOLock);
            
            break;
        }
        
        //SMC Secret Undocumented feature (⁎⁍̴̛ᴗ⁍̴̛⁎) - Capped at 80% PWM (0xC8) for hardware safety
        case 97: {
            if(!hasPrivilege(97))
                return kIOReturnNotPrivileged;
            
            if(arguments->scalarInputCount != 1)
                return kIOReturnBadArgument;
            
            if (!provider->superIOLock)
                return kIOReturnNoDevice;
            
            IOLockLock(provider->superIOLock);
            if (!provider->superIO) {
                IOLockUnlock(provider->superIOLock);
                return kIOReturnNoDevice;
            }
            int numFan = provider->superIO->getNumberOfFans();
            for (int i = 0; i < numFan; i++) {
                if(arguments->scalarInput[0])
                    provider->superIO->overrideFanControl(i, 0xC8);
                else
                    provider->superIO->setDefaultFanControl(i);
            }
            IOLockUnlock(provider->superIOLock);
            
            break;
        }
        
        // Read raw SuperIO register
        case 98: {
            if (!provider || !provider->superIOLock)
                return kIOReturnNoDevice;
            
            if(arguments->scalarInputCount != 1)
                return kIOReturnBadArgument;
            
            uint16_t reg = (uint16_t)arguments->scalarInput[0];
            uint64_t *dataOut = (uint64_t*) arguments->structureOutput;
            uint32_t maxLen = arguments->structureOutputSize;
            
            if (!arguments->structureOutput || maxLen < sizeof(uint64_t))
                return kIOReturnBadArgument;
            
            IOLockLock(provider->superIOLock);
            if (!provider->superIO) {
                IOLockUnlock(provider->superIOLock);
                return kIOReturnNoDevice;
            }
            uint8_t val = provider->superIO->readReg(reg);
            IOLockUnlock(provider->superIOLock);
            
            dataOut[0] = val;
            arguments->structureOutputSize = sizeof(uint64_t);
            break;
        }
        
        // Write raw SuperIO register
        case 99: {
            if (!provider || !provider->superIOLock)
                return kIOReturnNoDevice;
            
            if(!hasPrivilege(99))
                return kIOReturnNotPrivileged;
            
            if(arguments->scalarInputCount != 2)
                return kIOReturnBadArgument;
            
            uint16_t reg = (uint16_t)arguments->scalarInput[0];
            uint8_t val = (uint8_t)arguments->scalarInput[1];
            
            IOLockLock(provider->superIOLock);
            if (!provider->superIO) {
                IOLockUnlock(provider->superIOLock);
                return kIOReturnNoDevice;
            }
            provider->superIO->writeReg(reg, val);
            IOLockUnlock(provider->superIOLock);
            
            break;
        }
        
        // Update fan curve LUT and parameters
        case 101: {
            if(!provider)
                return kIOReturnNoDevice;
            if(!provider->superIOLock)
                return kIOReturnNoDevice;
            
            if(!hasPrivilege(101))
                return kIOReturnNotPrivileged;
                
            #pragma pack(push, 1)
            struct FanCurveInput {
                uint32_t curveIndex;
                uint32_t sourceSensor;
                uint32_t hysteresis;
                uint32_t rampRate;
                uint8_t lut[256];
            };
            #pragma pack(pop)
            
            if (!arguments->structureInput || arguments->structureInputSize != sizeof(FanCurveInput)) {
                return kIOReturnBadArgument;
            }
            
            const FanCurveInput *input = (const FanCurveInput*) arguments->structureInput;
            uint32_t idx = input->curveIndex;
            if (idx >= MAX_FAN_CURVES) {
                return kIOReturnBadArgument;
            }
            
            IOLockLock(provider->superIOLock);
            provider->fanCurves[idx].sourceSensor = (uint8_t)input->sourceSensor;
            provider->fanCurves[idx].hysteresis   = (uint8_t)input->hysteresis;
            provider->fanCurves[idx].rampRate     = (uint8_t)input->rampRate;
            memcpy(provider->fanCurves[idx].lut, input->lut, 256);
            IOLockUnlock(provider->superIOLock);
            
            break;
        }
        
        // Map physical fan to curve
        case 102: {
            if(!provider)
                return kIOReturnNoDevice;
            
            if(!hasPrivilege(102))
                return kIOReturnNotPrivileged;
                
            if (arguments->scalarInputCount != 2) {
                return kIOReturnBadArgument;
            }
            
            int fanIdx = (int)arguments->scalarInput[0];
            int curveIdx = (int)arguments->scalarInput[1];
            
            if (fanIdx < 0 || fanIdx >= 16 || curveIdx < -1 || curveIdx >= MAX_FAN_CURVES) {
                return kIOReturnBadArgument;
            }
            if (!provider->superIOLock) {
                return kIOReturnNoDevice;
            }
            
            IOLockLock(provider->superIOLock);
            if (provider->superIO && fanIdx >= provider->superIO->getNumberOfFans()) {
                IOLockUnlock(provider->superIOLock);
                return kIOReturnBadArgument;
            }
            provider->fanToCurveMap[fanIdx] = (int8_t)curveIdx;
            // If mapping to Auto, restore default fan control
            if (curveIdx == -1 && provider->superIO) {
                provider->superIO->setDefaultFanControl(fanIdx);
            }
            IOLockUnlock(provider->superIOLock);
            
            break;
        }
        
        // Set GPU temperature (used by the app for fan-curve source).
        // Privilege required: root or boot-arg -amdpnopchk.
        // Process-name authorization was removed (audit A-01).
        // The menu-bar process should run with -amdpnopchk or as root.
        // Temperature is clamped to a safe [0, 120] °C range to prevent abuse.
        case 103: {
            if(!provider)
                return kIOReturnNoDevice;
            
            if(arguments->scalarInputCount != 1)
                return kIOReturnBadArgument;
            
            if (!hasPrivilege(103))
                return kIOReturnNotPrivileged;
            
            float t = (float)arguments->scalarInput[0];
            if (t < 0.0f) t = 0.0f;
            if (t > 120.0f) t = 120.0f;
            provider->gpuTempC = t;
            
            break;
        }
        
        // Get Curve Optimizer Offsets (Phase 13)
        case 110: {
            if(!provider)
                return kIOReturnNoDevice;
            
            uint32_t requiredSize = CPUInfo::MaxCpus;
            uint32_t maxLen = arguments->structureOutputSize;
            arguments->structureOutputSize = requiredSize;
            
            if (!arguments->structureOutput || maxLen < requiredSize) {
                return kIOReturnBadArgument;
            }
            
            memcpy(arguments->structureOutput, provider->curveOptimizerOffsets, requiredSize);
            break;
        }
        
        // Set Curve Optimizer Offset (Phase 13)
        case 111: {
            if(!provider)
                return kIOReturnNoDevice;
            
            if(!hasPrivilege(111))
                return kIOReturnNotPrivileged;
                
            if(arguments->scalarInputCount != 2)
                return kIOReturnBadArgument;
                
            uint8_t core = (uint8_t)arguments->scalarInput[0];
            int8_t offset = (int8_t)arguments->scalarInput[1];
            
            int rc = provider->setCurveOptimizer(core, offset);
            if (rc < 0) {
                // Map setCurveOptimizer error codes to IOReturn values.
                // -1 unsupported, -2/-3 bad args, -4 not ready,
                // -10 SMU timeout, -11 invalid SMU cmd, -12 invalid SMU args, -13 SMU busy.
                if (rc == -1 || rc == -11) return kIOReturnUnsupported;
                if (rc == -2 || rc == -3 || rc == -12) return kIOReturnBadArgument;
                if (rc == -4) return kIOReturnNotReady;
                if (rc == -10) return kIOReturnTimeout;
                if (rc == -13) return kIOReturnBusy;
                return kIOReturnError;
            }
            break;
        }
        
        default: {
            IOLog("AMDRyzenCPUPMUserClient::externalMethod: invalid selector %u\n", selector);
            return kIOReturnUnsupported;
        }
    }
    
    return kIOReturnSuccess;
}
