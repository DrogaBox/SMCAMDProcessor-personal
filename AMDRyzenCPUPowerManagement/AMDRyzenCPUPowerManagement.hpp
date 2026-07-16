#ifndef AMDRyzenCPUPowerManagement_h
#define AMDRyzenCPUPowerManagement_h

//Support for macOS 10.13
#include "Headers/LegacyHeaders/LegacyIOService.h"

#include <math.h>
#include <IOKit/pci/IOPCIDevice.h>
#include <IOKit/IOTimerEventSource.h>


#include <i386/proc_reg.h>
#include <libkern/libkern.h>
#include <libkern/OSAtomic.h>


#include <Headers/kern_efi.hpp>
#include <Headers/kern_util.hpp>
#include <Headers/kern_cpu.hpp>
#include <Headers/kern_time.hpp>


//#include <Headers/kern_api.hpp>
#define LILU_CUSTOM_KMOD_INIT
#define LILU_CUSTOM_IOKIT_INIT
#include <Headers/plugin_start.hpp>
#include "symresolver/kernel_resolver.h"

#include "SuperIO/ISSuperIONCT668X.hpp"
#include "SuperIO/ISSuperIONCT67XXFamily.hpp"
#include "SuperIO/ISSuperIOIT86XXEFamily.hpp"

#include "Headers/pmRyzenSymbolTable.h"

#include <i386/cpuid.h>

#define OC_OEM_VENDOR_VARIABLE_NAME        u"oem-vendor"
#define OC_OEM_BOARD_VARIABLE_NAME         u"oem-board"

#define BASEBOARD_STRING_MAX 64

#define kNrOfPowerStates 2
#define kIOPMPowerOff 0

extern "C" {
#include "pmAMDRyzen.h"

#include "Headers/osfmk/i386/pmCPU.h"
#include "Headers/osfmk/i386/cpu_topology.h"
    

int cpu_number(void);
void mp_rendezvous_no_intrs(void (*action_func)(void *), void *arg);

void mp_rendezvous(void (*setup_func)(void *),
                  void (*action_func)(void *),
                  void (*teardown_func)(void *),
                  void *arg);

void i386_deactivate_cpu(void);
//    int wrmsr_carefully(uint32_t msr, uint64_t val);


void pmRyzen_wrmsr_safe(void *, uint32_t, uint64_t);
uint64_t pmRyzen_rdmsr_safe(void *, uint32_t);



extern pmRyzen_symtable_t pmRyzen_symtable;
};


/**
 * Offset table: https://github.com/torvalds/linux/blob/master/drivers/hwmon/k10temp.c#L78
 */
typedef struct tctl_offset {
    uint8_t model;
    char const *id;
    int offset;
} TempOffset;


#define MAX_FAN_CURVES 4
struct FanCurveConfig {
    uint8_t lut[256];
    uint8_t sourceSensor; // 0 = CPU, 1 = GPU
    uint8_t hysteresis;   // In °C
    uint8_t rampRate;     // Max PWM change per second
};


static IOPMPowerState powerStates[kNrOfPowerStates] = {
   {1, kIOPMPowerOff, kIOPMPowerOff, kIOPMPowerOff, 0, 0, 0, 0, 0, 0, 0, 0},
   {1, kIOPMPowerOn, kIOPMPowerOn, kIOPMPowerOn, 0, 0, 0, 0, 0, 0, 0, 0}
};


class AMDRyzenCPUPowerManagement : public IOService {
    OSDeclareDefaultStructors(AMDRyzenCPUPowerManagement)
    
public:
    
    char kMODULE_VERSION[12]{};
    
    /**
     *  MSRs supported by AMD 17h/19h/1Ah CPU from:
     *  https://github.com/LibreHardwareMonitor/LibreHardwareMonitor/blob/master/LibreHardwareMonitorLib/Hardware/Cpu/Amd17Cpu.cs
     * and
     * Processor Programming Reference for AMD Family 17h/19h/1Ah CPUs,
     * Linux kernel k10temp driver (drivers/hwmon/k10temp.c)
     */
    
    static constexpr uint32_t kCOFVID_STATUS = 0xC0010071;
    static constexpr uint32_t k17H_M01H_SVI = 0x0005A000;
    static constexpr uint32_t kF17H_M01H_THM_TCON_CUR_TMP = 0x00059800;
    static constexpr uint32_t kF17H_M70H_CCD1_TEMP = 0x00059954;
    static constexpr uint32_t kF17H_TEMP_OFFSET_FLAG = 0x80000;
    static constexpr uint32_t kF18H_TEMP_OFFSET_FLAG = 0x60000;
    static constexpr uint8_t kFAMILY_17H_PCI_CONTROL_REGISTER = 0x60;
    static constexpr uint8_t kFAMILY_1AH_PCI_CONTROL_REGISTER = 0x60;   // Zen 5 — confirm against PPR
    static constexpr uint16_t kAMD_HOST_BRIDGE_VENDOR = 0x1022;
    
    /**
     *  CCD (Core Complex Die) temperature register offsets.
     *  These offsets are added to kF17H_M01H_THM_TCON_CUR_TMP (0x59800)
     *  to get the per-CCD temperature register addresses.
     *
     *  Values sourced from Linux kernel k10temp.c:
     *  - 0x154: Family 17h (Zen/Zen+/Zen2), Family 19h models 00-5Fh (Zen3/3+)
     *  - 0x308: Family 19h models 60-7Fh (Zen4), Family 1Ah (Zen5 Granite Ridge)
     */
    static constexpr uint32_t kZEN_CCD_OFFSET_LEGACY = 0x154;
    static constexpr uint32_t kZEN_CCD_OFFSET_ZEN4_5 = 0x308;
    static constexpr uint8_t  kMAX_CCD_COUNT = 16;
    static constexpr uint32_t kZEN_CCD_TEMP_VALID_BIT = (1 << 11);
    static constexpr uint32_t kZEN_CCD_TEMP_MASK = 0x7FF;
    
    enum SMUResponse : uint32_t {
        SMU_RSP_OK           = 1,
        SMU_RSP_INVALID_CMD  = 0xFF,
        SMU_RSP_INVALID_ARGS = 0xFE,
        SMU_RSP_BUSY         = 0xFD,
        SMU_RSP_TIMEOUT      = 0,
    };
    
    static constexpr uint32_t kMSR_HWCR = 0xC0010015;
    static constexpr uint32_t kMSR_CORE_ENERGY_STAT = 0xC001029A;
    static constexpr uint32_t kMSR_HARDWARE_PSTATE_STATUS = 0xC0010293;
    static constexpr uint32_t kMSR_PKG_ENERGY_STAT = 0xC001029B;
    static constexpr uint32_t kMSR_PSTATE_0 = 0xC0010064;
    static constexpr uint32_t kMSR_PSTATE_LEN = 8;
    static constexpr uint32_t kMSR_PSTATE_STAT = 0xC0010063;
    static constexpr uint32_t kMSR_PSTATE_CTL = 0xC0010062;
    static constexpr uint32_t kMSR_RAPL_PWR_UNIT = 0xC0010299;
    static constexpr uint32_t kMSR_MPERF = 0x000000E7;
    static constexpr uint32_t kMSR_APERF = 0x000000E8;
    static constexpr uint32_t kMSR_PERF_CTL_0 = 0xC0010000;
    static constexpr uint32_t kMSR_PERF_CTR_0 = 0xC0010004;
    static constexpr uint32_t kMSR_PERF_IRPC = 0xC00000E9;
    static constexpr uint32_t kMSR_CSTATE_ADDR = 0xC0010073;
    static constexpr uint32_t kMSR_AMD_CPPC_CAP1 = 0xC00102B0;
    static constexpr uint32_t kMSR_AMD_CPPC_ENABLE = 0xC00102B1;
    static constexpr uint32_t kMSR_AMD_CPPC_CAP2 = 0xC00102B2;
    static constexpr uint32_t kMSR_AMD_CPPC_REQ = 0xC00102B3;
    static constexpr uint32_t kMSR_AMD_CPPC_STATUS = 0xC00102B4;
    
//    static constexpr uint32_t EF = 0x88;
    
    static constexpr uint32_t kEFI_VARIABLE_NON_VOLATILE = 0x00000001;
    static constexpr uint32_t kEFI_VARIABLE_BOOTSERVICE_ACCESS = 0x00000002;
    static constexpr uint32_t kEFI_VARIABLE_RUNTIME_ACCESS = 0x00000004;
    
    

    virtual bool init(OSDictionary *dictionary = 0) override;
    virtual void free(void) override;
    
    virtual bool start(IOService *provider) override;
    virtual void stop(IOService *provider) override;
    
    virtual IOReturn setPowerState(unsigned long powerStateOrdinal, IOService* whatDevice) override;
    
    void fetchOEMBaseBoardInfo();
    volatile SInt32 fanUpdateCounter = 0;

    bool read_msr(uint32_t addr, uint64_t *value);
    bool write_msr(uint32_t addr, uint64_t value);
    
    
    void updateClockSpeed(uint8_t physical);
    void calculateEffectiveFrequency(uint8_t physical);
    void updateInstructionDelta(uint8_t physical);
    void applyPowerControl();
    void applyEPPControl();
    
    void setCPBState(bool enabled);
    bool getCPBState();
    
#define HF_TEMP_SAMPLE_SECS 3
#define HF_TEMP_SAMPLE_FREQ 2
#define HF_TEMP_SAMPLE_LEN (HF_TEMP_SAMPLE_SECS * HF_TEMP_SAMPLE_FREQ)
#define HF_TEMP_SAMPLE_LENREP (1.0f / (float)HF_TEMP_SAMPLE_LEN)
#define HF_TEMP_SAMPLE_REP (1.0f / (float)HF_TEMP_SAMPLE_FREQ)
#define HF_TEMP_SAMPLE_PERIOD (int)(HF_TEMP_SAMPLE_REP * 1000.0)
    inline float getPackageTemp();
    float getCCDTemp(uint8_t ccd);
    uint32_t readCCDRegisterRaw(uint8_t ccd);
    void updatePackageTemp();
    
    void updatePackageEnergy();
    
    void registerRequest();
    
    void dumpPstate();
    void reinitHwState();
    void writePstate(const uint64_t *buf);
    
    bool initSuperIO(uint16_t* chipIntel);
    void evaluateFanCurves();
    
    uint32_t getPMPStateLimit();
    void setPMPStateLimit(uint32_t);
    
    uint32_t getHPcpus();
    int setCurveOptimizer(uint8_t core, int8_t offset);
    
    uint32_t totalNumberOfPhysicalCores;
    uint32_t totalNumberOfLogicalCores;
    
    bool cppcSupported {false};
    bool cppcActiveMode {false};
    uint8_t cppcEPPValue {0x3F};
    uint8_t cppcHighestPerf_perCore[CPUInfo::MaxCpus] {};
    bool cppcThrottled {false};
    uint64_t cstateAddrConfig {0};
    
    uint8_t cpuFamily;
    uint8_t cpuModel;
    uint8_t cpuSupportedByCurrentVersion;
    
    uint32_t ccdOffset = kZEN_CCD_OFFSET_LEGACY;
    uint8_t  ccdCount = 0;
    float    ccdTemperatures[kMAX_CCD_COUNT] {};
    char     cpuArchName[16] {};
    pmRyzen_idle_strategy_t cpuIdleStrategy{PMRYZEN_IDLE_STRATEGY_SIMPLE};
    
    // Curve Optimizer (Phase 13)
    int8_t curveOptimizerOffsets[CPUInfo::MaxCpus] {};
    
    //Cache size in KB
    uint32_t cpuCacheL1_perCore;
    uint32_t cpuCacheL2_perCore;
    uint32_t cpuCacheL3;
    
    char boardVendor[BASEBOARD_STRING_MAX]{};
    char boardName[BASEBOARD_STRING_MAX]{};
    bool boardInfoValid = false;
    
    
    /**
     *  Hard allocate space for cached readings.
     */
    float effFreq_perCore[CPUInfo::MaxCpus] {};
    float PACKAGE_TEMPERATURE_perPackage[CPUInfo::MaxCpus];
    
    uint64_t lastMPERF_perCore[CPUInfo::MaxCpus];
    uint64_t lastAPERF_perCore[CPUInfo::MaxCpus];
    uint64_t deltaMPERF_perCore[CPUInfo::MaxCpus];
    
//    uint64_t lastAPERF_PerCore[CPUInfo::MaxCpus];
    
    uint64_t instructionDelta_perCore[CPUInfo::MaxCpus];
    uint64_t lastInstructionDelta_perCore[CPUInfo::MaxCpus];
    
    float loadIndex_perCore[CPUInfo::MaxCpus];
    
    float PStateStepUpRatio = 0.36;
    float PStateStepDownRatio = 0.05;
    
    uint8_t PStateCur_perCore[CPUInfo::MaxCpus];
    uint8_t PStateCtl = 0;
    uint64_t PStateDef_perCore[8];
    uint8_t PStateEnabledLen = 0;
    float PStateDefClock_perCore[8];
    bool cpbSupported;
    
    
    uint64_t lastUpdateTime;
    uint64_t lastUpdateEnergyValue;
    
    double uniPackagePowerW;   // Average package power in watts (energy delta / time delta)
    
#pragma pack(push, 1)
    struct CPUSensorPacket {
        float packagePowerW;
        float packageTempC;
        uint32_t numLogicalCores; // Assigned total logical cores count per ABI spec
        uint32_t ccdCount;
        float ccdTemperatures[8];
        float coreFrequenciesMHz[64];
    };
#pragma pack(pop)

    // CPU capability profile per family/model
    // Each profile defines what features should be enabled for a given CPU.
    // - pmDispatchAllowed + legacyPstateAllowed = true on Zen 1/2 where
    //   macOS lacks native AMD power management.
    // - pmDispatchAllowed + legacyPstateAllowed = false on Zen 3+ where
    //   macOS AMD Vanilla handles CPPC natively — kext is telemetry-only.
    struct ZenCpuFeatureMap {
        uint32_t family;
        uint32_t modelStart;
        uint32_t modelEnd;
        const char *generationName;
        bool supportsCPPC;
        bool supportsCPPCv2;
        bool legacyPstateAllowed;
        bool pmDispatchAllowed;
    };

    // === Family 17h profiles: need full PM dispatch (macOS has no native AMD PM) ===

    // Zen 1 (Summit Ridge, Whitehaven)
    static constexpr ZenCpuFeatureMap ZEN1_PROFILE = {
        0x17, 0x00, 0x0F, "Zen",
        false, false,           // CPPC: no, CPPCv2: no
        true, true              // legacyPstate: yes, pmDispatch: yes
    };
    // Zen+ (Pinnacle Ridge)
    static constexpr ZenCpuFeatureMap ZEN_PLUS_PROFILE = {
        0x17, 0x10, 0x2F, "Zen+",
        false, false,
        true, true
    };
    // Zen 2 (Matisse, Rome)
    static constexpr ZenCpuFeatureMap ZEN2_PROFILE = {
        0x17, 0x30, 0xFF, "Zen 2",
        false, false,
        true, true
    };

    // === Family 19h+ profiles: telemetry-only (macOS AMD Vanilla handles CPPC) ===

    // Zen 3 Cezanne (mobile)
    static constexpr ZenCpuFeatureMap ZEN3_CEZANNE_PROFILE = {
        0x19, 0x10, 0x1F, "Zen 3 Cezanne",
        true, false,            // CPPC: yes, CPPCv2: no
        false, false            // legacyPstate: no, pmDispatch: no
    };
    // Zen 3 Vermeer (desktop)
    static constexpr ZenCpuFeatureMap ZEN3_VERMEER_PROFILE = {
        0x19, 0x21, 0x2F, "Zen 3 Vermeer",
        true, false,
        false, false
    };
    // Zen 3+ (Rembrandt, Barcelo)
    static constexpr ZenCpuFeatureMap ZEN3_PLUS_PROFILE = {
        0x19, 0x40, 0x5F, "Zen 3+",
        true, false,
        false, false
    };
    // Zen 4 (Raphael, Phoenix)
    static constexpr ZenCpuFeatureMap ZEN4_PROFILE = {
        0x19, 0x60, 0x7F, "Zen 4",
        true, false,
        false, false
    };
    // Zen 5 (Granite Ridge, Strix Point)
    static constexpr ZenCpuFeatureMap ZEN5_PROFILE = {
        0x1A, 0x00, 0xFF, "Zen 5",
        true, false,
        false, false
    };

    // Feature matrix - controlled per-profile
    bool telemetryAllowed {true};
    bool cppcReadAllowed {false};      // CPPC MSRs readable
    bool cppcWriteAllowed {false};     // CPPC requests allowed
    bool legacyPstateAllowed {false};  // Legacy P-state writes
    bool pmDispatchAllowed {false};    // Custom PM dispatch takeover

    // Derived state
    uint32_t zenGeneration = 3;
    bool supportsCPPC = false;
    bool supportsCPPCv2 = false;

    bool disablePrivilegeCheck = false;
    uint16_t savedSMCChipIntel = 0;
    uint16_t kextloadAlerts = 0;
    /// Ensures kunc_alert modal is shown at most once until the user dismisses/clears it.
    /// SInt32 for OSCompareAndSwap (audit R-6).
    SInt32 kextAlertDisplayed = 0;

    kern_return_t (*kunc_alert)(int,unsigned,const char*,const char*,const char*,
                                const char*,const char*,const char*,const char*,const char*,unsigned*) {nullptr};
    
    
    ISSuperIOSMCFamily *superIO{nullptr};
    IOLock *superIOLock{nullptr};   // Protects multi-step SuperIO I/O port sequences from concurrent UserClient calls
    IOLock *smuCmdLock{nullptr};    // Serializes full SMU command sequences (audit R-8)
    IOLock *rendezvousLock{nullptr}; // Serializes all mp_rendezvous calls (timer + UserClient control ops)
    
    static constexpr size_t kMAX_FANS = 16;
    FanCurveConfig fanCurves[MAX_FAN_CURVES];
    int8_t fanToCurveMap[kMAX_FANS]; // Maps each physical fan index to a curve index (-1 = Auto)
    uint8_t lastAppliedPWM[kMAX_FANS];
    uint64_t lastPWMUpdateTime[kMAX_FANS];
    
    static_assert(sizeof(fanToCurveMap) / sizeof(fanToCurveMap[0]) == kMAX_FANS, "fan array size mismatch");
    static_assert(sizeof(lastAppliedPWM) / sizeof(lastAppliedPWM[0]) == kMAX_FANS, "fan array size mismatch");
    static_assert(sizeof(lastPWMUpdateTime) / sizeof(lastPWMUpdateTime[0]) == kMAX_FANS, "fan array size mismatch");
    float gpuTempC;
    float curveSmoothedTemp[MAX_FAN_CURVES];
    
private:
    IOWorkLoop *workLoop;
    IOTimerEventSource *timerEvent_main;
    IOTimerEventSource *timerEvent_tempe;
    
    bool serviceInitialized = false;
    
    uint32_t updateTimeInterval = 1000;
    uint32_t actualUpdateTimeInterval = 1;
    uint32_t timeOfLastUpdate = 0;
    uint32_t estimatedRequestTimeInterval = 0;
    uint32_t timeOfLastMissedRequest = 0;
    
    int tempNextSample = 0;
    float tempSamples[HF_TEMP_SAMPLE_LEN];
    float tempOffset = 0;
    double pwrTimeUnit = 0;
    double pwrEnergyUnit = 0;
    uint64_t pwrLastTSC = 0;
    
    uint64_t xnuTSCFreq = 1;
    int (*wrmsr_carefully)(uint32_t, uint32_t, uint32_t) {nullptr};
    
    CPUInfo::CpuTopology cpuTopology {};
    
    IOPCIDevice *fIOPCIDevice{nullptr};
    IOSimpleLock *pciConfigLock{nullptr};
    
    KernelPatcher *liluKernelPatcher;
    
    bool getPCIService();
    bool wentToSleep{false};
    /// Set by resumeWorkLoop() on S3 wake. The main timer processes it on its
    /// first tick (workLoop thread) so reinitHwState() never runs on the PM thread.
    bool pendingReinit{false};
    
    uint32_t smnRead32(uint32_t addr);
    void smnWrite32(uint32_t addr, uint32_t val);
    int smuSendCmd(uint32_t cmd, uint32_t arg);

    struct SMUMailbox {
        uint32_t msgReg;
        uint32_t argReg;
        uint32_t rspReg;
        uint32_t curveOptimizerCmd;   // 0x3D on Zen 3, 0x55 on Zen 4 (per AGESA), 0x0 (unsupported) otherwise
        bool     supported;
    };
    SMUMailbox smuMailbox{};
    
    void initWorkLoop();
    void stopWorkLoop();
    void resumeWorkLoop();
};
#endif
