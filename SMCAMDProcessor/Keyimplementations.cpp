//
//  KeyImplementations.cpp
//  AMDRyzenCPUPowerManagement
//
//  Created by trulyspinach, modified by Droga (2026) on 2/12/20.
//

#include "KeyImplementations.hpp"
#include <libkern/OSAtomic.h>


SMC_RESULT TempPackage::readAccess() {
    if (!provider) return SmcError;
    __sync_synchronize();
    uint16_t *ptr = reinterpret_cast<uint16_t *>(data);
    *ptr = VirtualSMCAPI::encodeSp(type, (double)provider->PACKAGE_TEMPERATURE_perPackage[0]);

    return SmcSuccess;
}

SMC_RESULT TempCore::readAccess() {
    if (!provider) return SmcError;
    __sync_synchronize();
    uint16_t *ptr = reinterpret_cast<uint16_t *>(data);
    double temp = (double)provider->getCCDTemp(static_cast<uint8_t>(core));
    if (temp <= 0.0) {
        temp = (double)provider->PACKAGE_TEMPERATURE_perPackage[0];
    }
    *ptr = VirtualSMCAPI::encodeSp(type, temp);

    return SmcSuccess;
}

SMC_RESULT EnergyPackage::readAccess(){
    if (!provider) return SmcError;
    __sync_synchronize();
    if (type == SmcKeyTypeFloat)
        *reinterpret_cast<uint32_t *>(data) = VirtualSMCAPI::encodeFlt(provider->uniPackagePowerW);
    else
        *reinterpret_cast<uint16_t *>(data) = VirtualSMCAPI::encodeSp(type, provider->uniPackagePowerW);
    
    return SmcSuccess;
}

SMC_RESULT RGPUTempValue::readAccess() {
    if (!provider) return SmcError;
    
    UInt16 tempC = 0;
    IOReturn ret = provider->getGPUTemperature(static_cast<uint32_t>(package), &tempC);
    if (ret != kIOReturnSuccess) {
        return SmcError;
    }
    
    __sync_synchronize();
    uint16_t *ptr = reinterpret_cast<uint16_t *>(data);
    *ptr = VirtualSMCAPI::encodeSp(type, (double)tempC);
    
    return SmcSuccess;
}

SMC_RESULT RGPUPowerValue::readAccess() {
    if (!provider) return SmcError;
    
    float powerW = 0.0f;
    IOReturn ret = provider->getGPUPower(static_cast<uint32_t>(package), &powerW);
    if (ret != kIOReturnSuccess) {
        return SmcError;
    }
    
    __sync_synchronize();
    uint16_t *ptr = reinterpret_cast<uint16_t *>(data);
    *ptr = VirtualSMCAPI::encodeSp(type, (double)powerW);
    
    return SmcSuccess;
}
