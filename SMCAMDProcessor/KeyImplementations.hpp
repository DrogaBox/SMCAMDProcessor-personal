//
//  KeyImplementations.hpp
//  AMDRyzenCPUPowerManagement
//
//  Created by trulyspinach, modified by Droga (2026) on 2/12/20.
//

#ifndef KeyImplementations_hpp
#define KeyImplementations_hpp


#include "SMCAMDProcessor.hpp"



class AMDRyzenCPUPowerManagement;


class AMDSupportVsmcValue : public VirtualSMCValue {
protected:
    AMDRyzenCPUPowerManagement *provider;
    size_t package;
    size_t core;
public:
    AMDSupportVsmcValue(AMDRyzenCPUPowerManagement *provider, size_t package, size_t core=0) : provider(provider), package(package), core(core) {}
};


class TempPackage : public AMDSupportVsmcValue { using AMDSupportVsmcValue::AMDSupportVsmcValue; protected: SMC_RESULT readAccess() override; };
class TempCore    : public AMDSupportVsmcValue { using AMDSupportVsmcValue::AMDSupportVsmcValue; protected: SMC_RESULT readAccess() override; };

class EnergyPackage: public AMDSupportVsmcValue
{ using AMDSupportVsmcValue::AMDSupportVsmcValue; protected: SMC_RESULT readAccess() override; };

// === GPU sensor value classes ===
// RGPUTempValue: reads GPU temperature via the engine provider's AMDGPUDevice.
// Uses the GPU index (package parameter) to select which GPU.
class RGPUTempValue : public AMDSupportVsmcValue {
    using AMDSupportVsmcValue::AMDSupportVsmcValue;
protected:
    SMC_RESULT readAccess() override;
};

// RGPUPowerValue: reads GPU power consumption in watts.
// Only valid if the GPU supports power reading (gpuSupportsPower).
class RGPUPowerValue : public AMDSupportVsmcValue {
    using AMDSupportVsmcValue::AMDSupportVsmcValue;
protected:
    SMC_RESULT readAccess() override;
};

#endif /* KeyImplementations_hpp */
