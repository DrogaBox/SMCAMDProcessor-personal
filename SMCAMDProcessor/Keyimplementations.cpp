//
//  KeyImplementations.cpp
//  AMDRyzenCPUPowerManagement
//
//  Created by trulyspinach, modified by Droga (2026) on 2/12/20.
//

#include "KeyImplementations.hpp"


SMC_RESULT TempPackage::readAccess() {
    uint16_t *ptr = reinterpret_cast<uint16_t *>(data);
    *ptr = VirtualSMCAPI::encodeSp(type, (double)provider->PACKAGE_TEMPERATURE_perPackage[0]);

    return SmcSuccess;
}

SMC_RESULT TempCore::readAccess() {
    uint16_t *ptr = reinterpret_cast<uint16_t *>(data);
    double temp = 0.0;
    if (provider) {
        temp = (double)provider->getCCDTemp(static_cast<uint8_t>(core));
        if (temp <= 0.0) {
            temp = (double)provider->PACKAGE_TEMPERATURE_perPackage[0];
        }
    }
    *ptr = VirtualSMCAPI::encodeSp(type, temp);

    return SmcSuccess;
}

SMC_RESULT EnergyPackage::readAccess(){
    if (type == SmcKeyTypeFloat)
        *reinterpret_cast<uint32_t *>(data) = VirtualSMCAPI::encodeFlt(provider->uniPackageEnergy);
    else
        *reinterpret_cast<uint16_t *>(data) = VirtualSMCAPI::encodeSp(type, provider->uniPackageEnergy);
    
    return SmcSuccess;
}
