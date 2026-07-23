//
//  ISSuperIOIT86XXEFamily.cpp
//  AMDRyzenCPUPowerManagement
//
//  Created by Maurice on 25.05.20.
//

#include "ISSuperIOIT86XXEFamily.hpp"

ISSuperIOIT86XXEFamily::ISSuperIOIT86XXEFamily(int psel, uint16_t addr, uint16_t chipIntel, uint16_t gpioAddr)
{
    lpcPortSel = psel;
    chipAddr = addr;
    this->gpioAddr = gpioAddr;

    switch (chipIntel)
    {
        case CHIP_IT8688E:
        case CHIP_IT8686E:
        case CHIP_IT8665E:
        case CHIP_IT8689E:
        default:
            activeFansOnSystem = 6;
            break;
    }

    // Enable 16-bit fan tachometer mode for all 6 fans
    writeByte(0x0c, readByte(0x0c) | 0x3f);

    // backup default ctrl mode
    for (int i = 0; i < activeFansOnSystem; i++)
    {
        fanDefaultControlMode[i] = readByte(kFAN_PWM_CTRL_REGS[i]);
        fanDefaultExtControlMode[i] = readByte(kFAN_PWM_CTRL_EXT_REGS[i]);
    }
}

ISSuperIOIT86XXEFamily* ISSuperIOIT86XXEFamily::getDevice(uint16_t* chipIntel)
{

    i386_ioport_t regport = 0;
    uint8_t deviceID = 0, revision = 0;
    bool found = false;
    int portSel = 0;
    IOLog("probe IT86XXE\n");

    for (; portSel < 2; portSel++)
    {
        regport = ISLPCPort::kREGISTER_PORTS[portSel];

        if (regport != 0x2E && regport != 0x4E)
        {
            break;
        }

        // open port
        outb(regport, 0x87);
        outb(regport, 0x01);
        outb(regport, 0x55);

        if (regport == 0x4E)
        {
            outb(regport, 0xAA);
        }
        else
        {
            outb(regport, 0x55);
        }

        deviceID = ISLPCPort::readByte(portSel, ISLPCPort::kCHIP_ID_REG);
        revision = ISLPCPort::readByte(portSel, ISLPCPort::kCHIP_REVISION_REG);

        switch ((deviceID << 8) | revision)
        {
            case CHIP_IT8688E:
            case CHIP_IT8686E:
            case CHIP_IT8665E:
            case CHIP_IT8689E:
                found = true;
                IOLog("IT%X%XE chip identified\n", deviceID, revision);
                break;
            default:
                break;
        }

        if (found)
        {
            break;
        }
        else
        {
            // close port
            if (regport != 0x4E)
            {
                outb(regport, 0x02);
            }
        }
    }

    *chipIntel = (deviceID << 8) | revision;
    if (!found)
        return nullptr;

    IOLog("SMC Chip id:%X revision:%X \n", deviceID, revision);
    ISLPCPort::select(portSel, CHIP_ENVIRONMENT_CONTROLLER_LDN);

    uint16_t devAddr = ISLPCPort::readWord(portSel, ISLPCPort::kBASE_ADDRESS_REGISTER);

    // verify addr
    IODelay(10);
    if (ISLPCPort::readWord(portSel, ISLPCPort::kBASE_ADDRESS_REGISTER) != devAddr)
    {
        IOLog("IT%X%XE address verify failed", deviceID, revision);
        return nullptr;
    }

    ISLPCPort::select(portSel, CHIP_GPIO_LDN);
    uint16_t gpioAddress = ISLPCPort::readWord(portSel, ISLPCPort::kBASE_ADDRESS_REGISTER + 2);

    // verify gpio addr
    IODelay(10);
    if (ISLPCPort::readWord(portSel, ISLPCPort::kBASE_ADDRESS_REGISTER + 2) != gpioAddress)
    {
        IOLog("IT%X%XE gpio address verify failed", deviceID, revision);
        return nullptr;
    }

    // close port
    if (regport == 0x4E) {
        outb(regport, 0xAA);   // ITE 0x4E close sequence
    } else {
        outb(regport, 0x02);   // ITE 0x2E close sequence
    }

    return new ISSuperIOIT86XXEFamily(portSel, devAddr, *chipIntel, gpioAddress);
}

uint8_t ISSuperIOIT86XXEFamily::readByte(uint16_t addr)
{
    outb(chipAddr + CHIP_ADDR_REG_OFFSET, addr & 0xFF);
    return inb(chipAddr + CHIP_DAT_REG_OFFSET);
}

uint16_t ISSuperIOIT86XXEFamily::readWord(uint16_t addr)
{
    return (readByte(addr) << 8) | readByte(addr + 1);
}

void ISSuperIOIT86XXEFamily::writeByte(uint16_t addr, uint8_t val)
{
    outb(chipAddr + CHIP_ADDR_REG_OFFSET, addr & 0xFF);
    outb(chipAddr + CHIP_DAT_REG_OFFSET, val);
}

int ISSuperIOIT86XXEFamily::getNumberOfFans()
{
    return activeFansOnSystem;
}

const char* ISSuperIOIT86XXEFamily::getReadableStringForFan(int fan)
{
    if (fan < 0 || fan >= activeFansOnSystem || fan >= 6)
        return nullptr;
    return kFAN_READABLE_STRS[fan];
}

uint32_t ISSuperIOIT86XXEFamily::getRPMForFan(int fan)
{
    if (fan < 0 || fan >= activeFansOnSystem)
        return 0;
    return fanRPMs[fan];
}

bool ISSuperIOIT86XXEFamily::getFanAutoControlMode(int fan)
{
    if (fan < 0 || fan >= activeFansOnSystem)
        return 0;
    // kFAN_PWM_CTRL_REGS[fan] (0x15-0x17): bit 7 = SmartGuardian mode
    // In SmartGuardian mode: fan is controlled by SmartGuardian firmware (Auto).
    // In Manual mode (bit 7 = 0): fan is overridden by software.
    return (fanControlMode[fan] & 0x80) != 0;
}

uint8_t ISSuperIOIT86XXEFamily::getFanThrottle(int fan)
{
    if (fan < 0 || fan >= activeFansOnSystem)
        return 0;
    return fanThrottles[fan];
}

void ISSuperIOIT86XXEFamily::updateFanRPMS()
{
    for (int i = 0; i < activeFansOnSystem; i++)
    {
        int value = readByte(kFAN_RPM_REGS[i]);
        value |= readByte(kFAN_RPM_EXT_REGS[i]) << 8;

        if (value > 0x3f)
        {
            fanRPMs[i] = (value < 0xffff) ? 1.35e6f / (value * 2) : 0;
        }
        else
        {
            fanRPMs[i] = 0;
        }
        
        // Track peak RPM for PWM estimation in Auto mode
        if ((uint32_t)fanRPMs[i] > fanPeakRPMs[i]) {
            fanPeakRPMs[i] = (uint16_t)fanRPMs[i];
        }
    }
}

void ISSuperIOIT86XXEFamily::updateFanControl()
{
    for (int i = 0; i < activeFansOnSystem; i++)
    {
        // kFAN_PWM_CTRL_REGS: contains the PWM control mode byte (bit 7 = SmartGuardian/auto)
        fanControlMode[i] = readByte(kFAN_PWM_CTRL_REGS[i]);
        // kFAN_PWM_CTRL_EXT_REGS: contains the PWM duty cycle register.
        // In manual mode (bit 7 clear): this register holds the user-set duty cycle.
        // In SmartGuardian mode (bit 7 set): this register may not reflect the
        // actual PWM being output — SmartGuardian controls the fan independently.
        fanThrottles[i]   = readByte(kFAN_PWM_CTRL_EXT_REGS[i]);
        
        // Fallback: if the register reports 0 but the fan is clearly spinning
        // (RPM > 100), the chip is in SmartGuardian mode and doesn't update
        // the ext register. Estimate the throttle from RPM/peakRPM ratio
        // so the UI slider shows the real fan speed in Auto mode.
        if (fanThrottles[i] == 0 && fanRPMs[i] > 100 && fanPeakRPMs[i] > 200) {
            uint32_t est = (uint32_t)((uint64_t)fanRPMs[i] * 255 / fanPeakRPMs[i]);
            fanThrottles[i] = est > 255 ? 255 : (uint8_t)est;
        }
    }
}

void ISSuperIOIT86XXEFamily::overrideFanControl(int fan, uint8_t thr)
{
    if (fan < 0 || fan >= activeFansOnSystem)
        return;
    if (fan < 3) {
        writeByte(kFAN_MAIN_CTRL_REG, (readByte(kFAN_MAIN_CTRL_REG) | (1 << fan)));
    } else {
        writeByte(0x14, (readByte(0x14) | (1 << (fan - 3))));
    }
    writeByte(kFAN_PWM_CTRL_REGS[fan], (fanDefaultControlMode[fan] & 0x7F));
    writeByte(kFAN_PWM_CTRL_EXT_REGS[fan], thr);
}

void ISSuperIOIT86XXEFamily::setDefaultFanControl(int fan)
{
    if (fan < 0 || fan >= activeFansOnSystem)
        return;
    // Clear override bit (restore BIOS automatic control)
    if (fan < 3) {
        writeByte(kFAN_MAIN_CTRL_REG, readByte(kFAN_MAIN_CTRL_REG) & ~(1 << fan));
    } else {
        writeByte(0x14, readByte(0x14) & ~(1 << (fan - 3)));
    }
    writeByte(kFAN_PWM_CTRL_REGS[fan], fanDefaultControlMode[fan]);
    writeByte(kFAN_PWM_CTRL_EXT_REGS[fan], fanDefaultExtControlMode[fan]);
}
