
#ifndef SMCAMDProcessor_h
#define SMCAMDProcessor_h


//Support for macOS 10.13
#include "Headers/LegacyHeaders/LegacyIOService.h"
#include <IOKit/IOLib.h>

#include <AMDRyzenCPUPowerManagement.hpp>

#undef EFIAPI   // must place here!
#include <VirtualSMCSDK/kern_vsmcapi.hpp>
#include <VirtualSMCSDK/AppleSmc.h>
#define EFIAPI

class SMCAMDProcessor : public IOService {
    OSDeclareDefaultStructors(SMCAMDProcessor)
    
    /**
     *  VirtualSMC service registration notifier
     */
    IONotifier *vsmcNotifier {nullptr};
    
    static bool vsmcNotificationHandler(void *sensors, void *refCon, IOService *vsmc, IONotifier *notifier);
    
    /**
     *  Registered plugin instance
     */
    VirtualSMCAPI::Plugin vsmcPlugin {
        xStringify(PRODUCT_NAME),
        parseModuleVersion(xStringify(MODULE_VERSION)),
        VirtualSMCAPI::Version,
    };
    
    /**
     *  Key name index mapping — 36 positions (0-9, A-Z).
     *  Used to generate SMC key names like TC0C, TC1C, ..., TCCC, TCDC, etc.
     */
    static constexpr size_t MaxIndexCount = sizeof("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ") - 1;
    static constexpr const char *KeyIndexes = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    
    
    /**
     *  Supported SMC keys
     *
     *  Key naming convention (VirtualSMC standard):
     *  - TCxx = temperature
     *  - PCxx = power
     *  - PSxx = power state
     *
     *  Suffix: C=core, D=die, E=CPU(cpu), F=CPU(fast), G=GPU, H=heatsink,
     *  J=component, P=package, T=thermal zone, p=package(alt), R=reading
     *
     *  Active keys (registered in setupKeysVsmc):
     *  - TC0x: package temperature (SP78)
     *  - PCPR/PSTR: package power (SP96)
     *  - TCxC/TCxc: per-CCD temperature (SP78), index = CCD number
     *
     *  Legacy/unused keys (kept for reference, not registered):
     *  - PC0C/PC0G/PC0R: per-core power (not available on all AMD families)
     *  - PC3C/PCAC/PCEC: additional C-state counters
     *  - PCAM/PCGC/PCGM: GPU power metrics (handled by SMCRadeonSensors)
     *  - PCPC/PCPG: package C-state residency
     *  - PCPT/PCTR: package thermal throttle counters
     *  - TCxD/TCxG/TCxH: additional thermal zones (not exposed by SMU)
     */
    static constexpr SMC_KEY KeyPC0C = SMC_MAKE_IDENTIFIER('P','C','0','C');
    static constexpr SMC_KEY KeyPC0G = SMC_MAKE_IDENTIFIER('P','C','0','G');
    static constexpr SMC_KEY KeyPC0R = SMC_MAKE_IDENTIFIER('P','C','0','R');
    static constexpr SMC_KEY KeyPC3C = SMC_MAKE_IDENTIFIER('P','C','3','C');
    static constexpr SMC_KEY KeyPCAC = SMC_MAKE_IDENTIFIER('P','C','A','C');
    static constexpr SMC_KEY KeyPCAM = SMC_MAKE_IDENTIFIER('P','C','A','M');
    static constexpr SMC_KEY KeyPCEC = SMC_MAKE_IDENTIFIER('P','C','E','C');
    static constexpr SMC_KEY KeyPCGC = SMC_MAKE_IDENTIFIER('P','C','G','C');
    static constexpr SMC_KEY KeyPCGM = SMC_MAKE_IDENTIFIER('P','C','G','M');
    static constexpr SMC_KEY KeyPCPC = SMC_MAKE_IDENTIFIER('P','C','P','C');
    static constexpr SMC_KEY KeyPCPG = SMC_MAKE_IDENTIFIER('P','C','P','G');
    static constexpr SMC_KEY KeyPCPR = SMC_MAKE_IDENTIFIER('P','C','P','R');
    static constexpr SMC_KEY KeyPSTR = SMC_MAKE_IDENTIFIER('P','S','T','R');
    static constexpr SMC_KEY KeyPCPT = SMC_MAKE_IDENTIFIER('P','C','P','T');
    static constexpr SMC_KEY KeyPCTR = SMC_MAKE_IDENTIFIER('P','C','T','R');
    static constexpr SMC_KEY KeyTCxD(size_t i) { return SMC_MAKE_IDENTIFIER('T','C',KeyIndexes[i < MaxIndexCount ? i : 0],'D'); }
    static constexpr SMC_KEY KeyTCxE(size_t i) { return SMC_MAKE_IDENTIFIER('T','C',KeyIndexes[i < MaxIndexCount ? i : 0],'E'); }
    static constexpr SMC_KEY KeyTCxF(size_t i) { return SMC_MAKE_IDENTIFIER('T','C',KeyIndexes[i < MaxIndexCount ? i : 0],'F'); }
    static constexpr SMC_KEY KeyTCxG(size_t i) { return SMC_MAKE_IDENTIFIER('T','C',KeyIndexes[i < MaxIndexCount ? i : 0],'G'); }
    static constexpr SMC_KEY KeyTCxJ(size_t i) { return SMC_MAKE_IDENTIFIER('T','C',KeyIndexes[i < MaxIndexCount ? i : 0],'J'); }
    static constexpr SMC_KEY KeyTCxH(size_t i) { return SMC_MAKE_IDENTIFIER('T','C',KeyIndexes[i < MaxIndexCount ? i : 0],'H'); }
    static constexpr SMC_KEY KeyTCxP(size_t i) { return SMC_MAKE_IDENTIFIER('T','C',KeyIndexes[i < MaxIndexCount ? i : 0],'P'); }
    static constexpr SMC_KEY KeyTCxT(size_t i) { return SMC_MAKE_IDENTIFIER('T','C',KeyIndexes[i < MaxIndexCount ? i : 0],'T'); }
    static constexpr SMC_KEY KeyTCxp(size_t i) { return SMC_MAKE_IDENTIFIER('T','C',KeyIndexes[i < MaxIndexCount ? i : 0],'p'); }
    
    static constexpr SMC_KEY KeyTCxC(size_t i) { return SMC_MAKE_IDENTIFIER('T','C',KeyIndexes[i < MaxIndexCount ? i : 0],'C'); }
    static constexpr SMC_KEY KeyTCxc(size_t i) { return SMC_MAKE_IDENTIFIER('T','C',KeyIndexes[i < MaxIndexCount ? i : 0],'c'); }
    
public:
    
    virtual bool init(OSDictionary *dictionary = 0) override;
    virtual void free(void) override;
    
    virtual bool start(IOService *provider) override;
    virtual void stop(IOService *provider) override;
    
    
private:
    
    bool setupKeysVsmc();
    AMDRyzenCPUPowerManagement *fProvider;
    
};


#endif
