#include "SMCAMDProcessor.hpp"


#include "KeyImplementations.hpp"

OSDefineMetaClassAndStructors(SMCAMDProcessor, IOService);

// Ensures sensor objects are released if VirtualSMCAPI::addKey fails,
// preventing memory leaks on registration failure (audit K-1).
static bool addKeySafe(VirtualSMCAPI::Key key, OSObject *node,
                       VirtualSMCAPI::Value value, OSObject *sensor) {
    if (VirtualSMCAPI::addKey(key, node, value))
        return true;
    if (sensor)
        sensor->release();
    return false;
}


bool SMCAMDProcessor::setupKeysVsmc(){
    
    vsmcNotifier = VirtualSMCAPI::registerHandler(vsmcNotificationHandler, this);
    
    bool suc = true;
    size_t keyCount = 0;
    
    if (fProvider) {
        // === Temperature keys (SP78 format) ===
        // TC0x keys: package temperature reported by the SMU (index 0)
        {
            auto *s = new TempPackage(fProvider, 0);
            suc &= addKeySafe(KeyTCxE(0), vsmcPlugin.data, VirtualSMCAPI::valueWithSp(0, SmcKeyTypeSp78, s), s);
            keyCount++;
        }
        {
            auto *s = new TempPackage(fProvider, 0);
            suc &= addKeySafe(KeyTCxF(0), vsmcPlugin.data, VirtualSMCAPI::valueWithSp(0, SmcKeyTypeSp78, s), s);
            keyCount++;
        }
        {
            auto *s = new TempPackage(fProvider, 0);
            suc &= addKeySafe(KeyTCxP(0), vsmcPlugin.data, VirtualSMCAPI::valueWithSp(0, SmcKeyTypeSp78, s), s);
            keyCount++;
        }
        {
            auto *s = new TempPackage(fProvider, 0);
            suc &= addKeySafe(KeyTCxT(0), vsmcPlugin.data, VirtualSMCAPI::valueWithSp(0, SmcKeyTypeSp78, s), s);
            keyCount++;
        }
        {
            auto *s = new TempPackage(fProvider, 0);
            suc &= addKeySafe(KeyTCxp(0), vsmcPlugin.data, VirtualSMCAPI::valueWithSp(0, SmcKeyTypeSp78, s), s);
            keyCount++;
        }
        
        // === Energy keys (SP96/Float format) ===
        // PCPR/PSTR: package power reported by RAPL MSR
        {
            auto *s = new EnergyPackage(fProvider, 0);
            suc &= addKeySafe(KeyPCPR, vsmcPlugin.data, VirtualSMCAPI::valueWithSp(0, SmcKeyTypeSp96, s), s);
            keyCount++;
        }
        {
            auto *s = new EnergyPackage(fProvider, 0);
            suc &= addKeySafe(KeyPSTR, vsmcPlugin.data, VirtualSMCAPI::valueWithSp(0, SmcKeyTypeSp96, s), s);
            keyCount++;
        }
        
        // === Per-CCD temperature keys (SP78 format) ===
        // TCxC/TCxc: individual Core Complex Die temperatures, iterating over ccdCount
        uint8_t count = fProvider->ccdCount > 0 ? fProvider->ccdCount : 1;
        for (size_t ccd = 0; ccd < count; ccd++) {
            {
                auto *s = new TempCore(fProvider, 0, ccd);
                suc &= addKeySafe(KeyTCxC(ccd), vsmcPlugin.data, VirtualSMCAPI::valueWithSp(0, SmcKeyTypeSp78, s), s);
                keyCount++;
            }
            {
                auto *s = new TempCore(fProvider, 0, ccd);
                suc &= addKeySafe(KeyTCxc(ccd), vsmcPlugin.data, VirtualSMCAPI::valueWithSp(0, SmcKeyTypeSp78, s), s);
                keyCount++;
            }
        }
        IOLog("SMCAMDProcessor::setupKeysVsmc: registering %zu CCDs\n", size_t(count));
    } else {
        IOLog("SMCAMDProcessor::setupKeysVsmc: fProvider is null, skipping key registration\n");
    }
    
    if(!suc){
        IOLog("SMCAMDProcessor::setupKeysVsmc: VirtualSMCAPI::addKey returned false (registered %zu/%zu keys). \n", keyCount, keyCount);
    } else {
        IOLog("SMCAMDProcessor::setupKeysVsmc: registered %zu VirtualSMC keys successfully. \n", keyCount);
    }
    
    return suc;
}

bool SMCAMDProcessor::vsmcNotificationHandler(void *sensors, void *refCon, IOService *vsmc, IONotifier *notifier) {
    if (sensors && vsmc) {
        IOLog("SMCAMDProcessor: got vsmc notification\n");
        auto &plugin = static_cast<SMCAMDProcessor *>(sensors)->vsmcPlugin;
        auto ret = vsmc->callPlatformFunction(VirtualSMCAPI::SubmitPlugin, true, sensors, &plugin, nullptr, nullptr);
        if (ret == kIOReturnSuccess) {
            IOLog("SMCAMDProcessor: submitted plugin\n");
            return true;
        } else if (ret != kIOReturnUnsupported) {
            IOLog("SMCAMDProcessor: plugin submission failure %X\n", ret);
        } else {
            IOLog("SMCAMDProcessor: plugin submission to non vsmc\n");
        }
    } else {
        IOLog("SMCAMDProcessor: got null vsmc notification\n");
    }
    return false;
}

bool SMCAMDProcessor::init(OSDictionary *dictionary){
    return IOService::init(dictionary);
}

void SMCAMDProcessor::free(void){
    IOService::free();
}

bool SMCAMDProcessor::start(IOService *provider){
    
    if(!IOService::start(provider))
        return false;
    
    fProvider = OSDynamicCast(AMDRyzenCPUPowerManagement, provider);
    if(!fProvider)
        return false;
    
    
    IOLog("SMCAMDProcessor: inited, registering VirtualSMC keys...\n");
    
    setupKeysVsmc();
    
    return true;
}

void SMCAMDProcessor::stop(IOService *provider){
    if (vsmcNotifier) {
        vsmcNotifier->remove();
        vsmcNotifier = nullptr;
    }
    fProvider = nullptr;
    IOService::stop(provider);
}
