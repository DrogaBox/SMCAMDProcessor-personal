//
//  ISSuperIOSMCFamily.hpp
//  AMDRyzenCPUPowerManagement
//
//  Created by trulyspinach, modified by Droga (2026) on 5/17/20.
//

#ifndef ISSuperIOSMCFamily_hpp
#define ISSuperIOSMCFamily_hpp

class ISSuperIOSMCFamily {

    
public:
    virtual ~ISSuperIOSMCFamily() = default;
    
    virtual int getNumberOfFans();
    virtual const char *getReadableStringForFan(int fan);
    
    virtual uint32_t getRPMForFan(int fan);
    virtual bool getFanAutoControlMode(int fan);
    virtual uint8_t getFanThrottle(int fan);
    
    virtual void updateFanRPMS();
    virtual void updateFanControl();
    
    virtual void overrideFanControl(int fan, uint8_t thr);
    virtual void setDefaultFanControl(int fan);
    
    virtual uint8_t readReg(uint16_t reg) { return 0; }
    virtual void writeReg(uint16_t reg, uint8_t val) {}
};

#endif /* ISSuperIOSMCFamily_hpp */
