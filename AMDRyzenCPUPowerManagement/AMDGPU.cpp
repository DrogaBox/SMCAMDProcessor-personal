//
//  AMDGPU.cpp
//  AMDRyzenCPUPowerManagement
//
//  GPU temperature and power monitoring via PCI BAR MMIO.
//  All register addresses are hardware facts from the Linux amdgpu kernel driver
//  (drivers/gpu/drm/amd/display/, drivers/gpu/drm/amd/pm/).
//  Implementation is original — no code copied from SMCRadeonSensors.
//

#include "AMDGPU.hpp"
#include <Headers/kern_iokit.hpp>
#include <libkern/OSAtomic.h>

OSDefineMetaClassAndStructors(AMDGPUDevice, OSObject);

//==============================================================================
// MARK: - Register Address Constants (Hardware Facts)
//==============================================================================
// These are documented register addresses from the AMD GPU programmer's
// reference manuals and the Linux amdgpu kernel driver. They describe the
// hardware interface and are not copyrightable creative expression.

static constexpr UInt32 mmPCIE_INDEX       = 0xC;
static constexpr UInt32 mmPCIE_DATA        = 0xD;
static constexpr UInt32 mmPCIE_INDEX2      = 0xE;
static constexpr UInt32 mmPCIE_DATA2       = 0xF;

static constexpr UInt32 mmSMC_IND_INDEX_0  = 0x80;
static constexpr UInt32 mmSMC_IND_DATA_0   = 0x81;
static constexpr UInt32 mmSMC_IND_INDEX_11 = 0x1AC;
static constexpr UInt32 mmSMC_IND_DATA_11  = 0x1AD;

static constexpr UInt32 ixCG_MULT_THERMAL_STATUS = 0xC0300014;

static constexpr UInt32 THM_BASE          = 0x16600;
static constexpr UInt32 mmTHM_TCON_CUR_TMP = 0;
static constexpr UInt32 CUR_TEMP_RANGE_SEL = 0x80000;
#define GET_TCON_CUR_TEMP(v) (((v) & 0xFFE00000) >> 21)

static constexpr UInt32 mmCG_MULT_THERMAL_STATUS_THM9  = 0x5A;
static constexpr UInt32 mmCG_MULT_THERMAL_STATUS_THM11 = 0x5F;
#define GET_THERMAL_STATUS_CTF_TEMP(v) (((v) & 0x3FE00) >> 9)

// SMU timeouts (microseconds)
static constexpr UInt32 AMDGPU_SMU_POLL_US  = 2000;
static constexpr UInt32 AMDGPU_SMU_TIMEOUT_US = 100000;

// SMU9 mailbox registers (Vega 10/12/20)
static constexpr UInt32 MP_BASE_SMU9            = 0x16000;
static constexpr UInt32 mmMP1_SMN_C2PMSG_66     = 0x282;
static constexpr UInt32 mmMP1_SMN_C2PMSG_82     = 0x292;
static constexpr UInt32 mmMP1_SMN_C2PMSG_90     = 0x29A;

// SMU7 mailbox registers (pre-Vega)
static constexpr UInt32 mmSMC_MESSAGE_0_SMU7    = 0x94;
static constexpr UInt32 mmSMC_RESP_0_SMU7       = 0x95;
static constexpr UInt32 SMC_RESP_0_MASK_SMU7    = 0xFFFF;
static constexpr UInt32 mmSMC_MSG_ARG_0_SMU7    = 0xA4;

// SMU7 PM Status log
static constexpr UInt32 ixSMU_PM_STATUS_95             = 0x3FF7C;
static constexpr UInt32 PPSMC_MSG_PmStatusLogStart_SMU7  = 0x170;
static constexpr UInt32 PPSMC_MSG_PmStatusLogSample_SMU7 = 0x171;

// SMU7/SMU9 power commands
static constexpr UInt32 PPSMC_MSG_GetCurrPkgPwr_SMU7 = 0x282;
static constexpr UInt32 PPSMC_MSG_GetCurrPkgPwr_SMU9 = 0x61;

/**
 * Full memory fence (mfence) for MMIO register access.
 *
 * mfence is required (not just sfence) because:
 * 1. MMIO writes use write-combining buffers that can delay stores
 * 2. We need STORE → LOAD ordering across PCI register pairs (INDEX/DATA)
 * 3. sfence only orders stores; mfence flushes write-combining and orders all ops
 *
 * Pattern: rmmioPtr[INDEX] = reg; memoryBarrier(); val = rmmioPtr[DATA];
 * Without mfence, DATA read could execute before INDEX write completes.
 */
static inline void memoryBarrier() {
    __asm__ volatile("mfence" ::: "memory");
}

//==============================================================================
// MARK: - BAR Mapping
//==============================================================================

IOReturn AMDGPUDevice::ensureRMMIOMapped() {
    if (rmmio != nullptr) {
        return kIOReturnSuccess;
    }

    IOLockLock(gpuLock);

    // GCN 1.2+ (Southern Islands+) uses BAR5; older Sea Islands uses BAR2
    bool useBar5 = (chipFamily >= 2);

    dev->setMemoryEnable(true);
    dev->setBusMasterEnable(true);

    rmmio = dev->mapDeviceMemoryWithRegister(useBar5 ? kIOPCIConfigBaseAddress5
                                                      : kIOPCIConfigBaseAddress2);
    if (rmmio == nullptr || !rmmio->getLength()) {
        IOLog("AMDGPUDevice: Failed to map BAR%d", useBar5 ? 5 : 2);
        OSSafeReleaseNULL(rmmio);
        IOLockUnlock(gpuLock);
        return kIOReturnDeviceError;
    }

    rmmioPtr = reinterpret_cast<volatile UInt32 *>(rmmio->getVirtualAddress());
    if (rmmioPtr == nullptr) {
        IOLog("AMDGPUDevice: Failed to get virtual address for BAR%d", useBar5 ? 5 : 2);
        OSSafeReleaseNULL(rmmio);
        IOLockUnlock(gpuLock);
        return kIOReturnDeviceError;
    }

    IOLog("AMDGPUDevice: BAR%d mapped at %p", useBar5 ? 5 : 2, rmmioPtr);
    IOLockUnlock(gpuLock);
    return kIOReturnSuccess;
}

//==============================================================================
// MARK: - Register Access (Pre-GCN 5 / Pre-Raven)
//==============================================================================

UInt32 AMDGPUDevice::readReg32(UInt32 reg) {
    IOLockLock(gpuLock);
    UInt32 ret;
    if ((reg * sizeof(*rmmioPtr)) < rmmio->getLength()) {
        ret = rmmioPtr[reg];
    } else {
        rmmioPtr[mmPCIE_INDEX] = reg;
        memoryBarrier();
        ret = rmmioPtr[mmPCIE_DATA];
    }
    IOLockUnlock(gpuLock);
    return ret;
}

void AMDGPUDevice::writeReg32(UInt32 reg, UInt32 val) {
    IOLockLock(gpuLock);
    if ((reg * sizeof(*rmmioPtr)) < rmmio->getLength()) {
        rmmioPtr[reg] = val;
    } else {
        rmmioPtr[mmPCIE_INDEX] = reg;
        memoryBarrier();
        rmmioPtr[mmPCIE_DATA] = val;
    }
    IOLockUnlock(gpuLock);
}

//==============================================================================
// MARK: - Register Access (GCN 5 / RDNA+ / SOC15)
//==============================================================================

UInt32 AMDGPUDevice::soc15ReadReg32(UInt32 reg) {
    IOLockLock(gpuLock);
    UInt32 ret;
    if ((reg * sizeof(*rmmioPtr)) < rmmio->getLength()) {
        ret = rmmioPtr[reg];
    } else {
        rmmioPtr[mmPCIE_INDEX2] = reg;
        memoryBarrier();
        ret = rmmioPtr[mmPCIE_DATA2];
    }
    IOLockUnlock(gpuLock);
    return ret;
}

void AMDGPUDevice::soc15WriteReg32(UInt32 reg, UInt32 val) {
    IOLockLock(gpuLock);
    if ((reg * sizeof(*rmmioPtr)) < rmmio->getLength()) {
        rmmioPtr[reg] = val;
    } else {
        rmmioPtr[mmPCIE_INDEX2] = reg;
        memoryBarrier();
        rmmioPtr[mmPCIE_DATA2] = val;
    }
    IOLockUnlock(gpuLock);
}

//==============================================================================
// MARK: - Indirect SMC Register Access
//==============================================================================

UInt32 AMDGPUDevice::readIndirectSMC(UInt32 reg) {
    IOLockLock(gpuLock);
    UInt32 ret;

    if (chipFamily == 2 || chipFamily == 1) {
        // Southern Islands, Sea Islands
        rmmioPtr[mmSMC_IND_INDEX_0] = reg;
        memoryBarrier();
        ret = rmmioPtr[mmSMC_IND_DATA_0];
    } else if (chipFamily == 3) {
        // Volcanic Islands
        rmmioPtr[mmSMC_IND_INDEX_11] = reg;
        memoryBarrier();
        ret = rmmioPtr[mmSMC_IND_DATA_11];
    } else {
        ret = 0xFFFFFFFF;
    }

    IOLockUnlock(gpuLock);
    return ret;
}

void AMDGPUDevice::writeIndirectSMC(UInt32 reg, UInt32 val) {
    IOLockLock(gpuLock);

    if (chipFamily == 2 || chipFamily == 1) {
        // Southern Islands, Sea Islands
        rmmioPtr[mmSMC_IND_INDEX_0] = reg;
        memoryBarrier();
        rmmioPtr[mmSMC_IND_DATA_0] = val;
    } else if (chipFamily == 3) {
        // Volcanic Islands
        rmmioPtr[mmSMC_IND_INDEX_11] = reg;
        memoryBarrier();
        rmmioPtr[mmSMC_IND_DATA_11] = val;
    }

    IOLockUnlock(gpuLock);
}

//==============================================================================
// MARK: - SMU7 Response Polling
//==============================================================================

UInt32 AMDGPUDevice::smu7PollResponse() {
    UInt32 ret = 0;
    for (UInt32 i = 0; i < AMDGPU_SMU_TIMEOUT_US; i++) {
        ret = readReg32(mmSMC_RESP_0_SMU7) & SMC_RESP_0_MASK_SMU7;
        if (ret != 0) {
            break;
        }
        IODelay(1);
    }
    return ret;
}

//==============================================================================
// MARK: - Temperature Reading (SMU7: Sea/Southern/Volcanic Islands)
//==============================================================================

IOReturn AMDGPUDevice::smu7GetTemp(UInt16 *data) {
    auto ctfTemp = GET_THERMAL_STATUS_CTF_TEMP(readIndirectSMC(ixCG_MULT_THERMAL_STATUS));
    // Clamp to unsigned 9-bit, mark 0x200 bit as invalid (255°C)
    *data = (ctfTemp & 0x200) ? 255 : (ctfTemp & 0x1FF);
    return kIOReturnSuccess;
}

//==============================================================================
// MARK: - Temperature Reading (THM9: Vega 10/Vega 12 non-THM11)
//==============================================================================

IOReturn AMDGPUDevice::thm9GetTemp(UInt16 *data) {
    auto reg = soc15ReadReg32(THM_BASE + mmCG_MULT_THERMAL_STATUS_THM9);
    *data = GET_THERMAL_STATUS_CTF_TEMP(reg) & 0x1FF;
    return kIOReturnSuccess;
}

//==============================================================================
// MARK: - Temperature Reading (THM11: Vega 20)
//==============================================================================

IOReturn AMDGPUDevice::thm11GetTemp(UInt16 *data) {
    auto reg = soc15ReadReg32(THM_BASE + mmCG_MULT_THERMAL_STATUS_THM11);
    *data = GET_THERMAL_STATUS_CTF_TEMP(reg) & 0x1FF;
    return kIOReturnSuccess;
}

//==============================================================================
// MARK: - Temperature Reading (THM10: Raven / Navi)
//==============================================================================

IOReturn AMDGPUDevice::thm10GetTemp(UInt16 *data) {
    auto reg = soc15ReadReg32(THM_BASE + mmTHM_TCON_CUR_TMP);
    UInt32 raw = GET_TCON_CUR_TEMP(reg) / 8;

    // When CUR_TEMP_RANGE_SEL is set, a 49°C negative offset applies.
    // Guard against unsigned underflow: clamp to 0.
    if (reg & CUR_TEMP_RANGE_SEL) {
        *data = (raw > 49) ? (raw - 49) : 0;
    } else {
        *data = raw;
    }
    return kIOReturnSuccess;
}

//==============================================================================
// MARK: - Power Reading (SMU7 via PM Status Log: Sea Islands, chipFamily=1)
//==============================================================================
// The PM Status Log protocol is used on older chips (Sea Islands) where the
// SMC mailbox does not support GetCurrPkgPwr directly.

IOReturn AMDGPUDevice::smu7GetPowerPMStatus(float *data) {
    // Ensure SMC is ready before sending commands
    smu7PollResponse();

    // Start PM status log
    writeReg32(mmSMC_MESSAGE_0_SMU7, PPSMC_MSG_PmStatusLogStart_SMU7);
    memoryBarrier();

    // Reset the log by reading the status register
    readIndirectSMC(ixSMU_PM_STATUS_95);

    UInt32 value = 0;
    // Sample up to 10 times with 100ms intervals (1 second total max)
    for (size_t i = 0; i < 10; i++) {
        // Ensure previous command completed
        smu7PollResponse();

        // Send sample command
        writeReg32(mmSMC_MESSAGE_0_SMU7, PPSMC_MSG_PmStatusLogSample_SMU7);
        memoryBarrier();

        IOSleep(100);

        value = readIndirectSMC(ixSMU_PM_STATUS_95);
        if (value != 0) {
            break;
        }
    }

    if (value == 0) {
        return kIOReturnError;
    }

    // Convert from 8.24 fractional format: top 24 bits integer, low 8 bits fraction (mW)
    // Formula from Linux amdgpu: power = (value >> 8) + (value & 0xFF) * 0.001
    *data = static_cast<float>((value & 0xFFFFFF00) >> 8)
          + static_cast<float>(value & 0xFF) * 0.001f;
    return kIOReturnSuccess;
}

//==============================================================================
// MARK: - Power Reading (SMU7 via SMC Mailbox: Southern/Volcanic Islands)
//==============================================================================
// Uses the SMU7 SMC mailbox protocol documented in the Linux amdgpu driver.

IOReturn AMDGPUDevice::smu7GetPowerSMC(float *data) {
    // Step 1: Wait for SMC to be ready (previous response consumed)
    UInt32 prevResp = smu7PollResponse();

    // Step 2: Write argument (0 = current package power)
    writeReg32(mmSMC_MSG_ARG_0_SMU7, 0);

    // Step 3: Clear response register
    writeReg32(mmSMC_RESP_0_SMU7, 0);
    memoryBarrier();

    // Step 4: Send command
    writeReg32(mmSMC_MESSAGE_0_SMU7, PPSMC_MSG_GetCurrPkgPwr_SMU7);
    memoryBarrier();

    // Step 5: Wait for response
    UInt32 resp = smu7PollResponse();
    if (resp != 1) {
        // Response not OK — fall back to PM Status log method
        return smu7GetPowerPMStatus(data);
    }

    // Step 6: Read power value from argument register
    UInt32 value = readReg32(mmSMC_MSG_ARG_0_SMU7);

    // Convert from 8.24 fractional format
    *data = static_cast<float>((value & 0xFFFFFF00) >> 8)
          + static_cast<float>(value & 0xFF) * 0.001f;
    return kIOReturnSuccess;
}

//==============================================================================
// MARK: - Power Reading (SMU9: Vega 10/12/20 Arctic Islands)
//==============================================================================
// SMU9 uses a different mailbox protocol via SOC15 MMIO registers.

IOReturn AMDGPUDevice::smu9GetPower(float *data) {
    UInt32 base = MP_BASE_SMU9;

    // Step 1: Wait for previous command to complete
    for (UInt32 i = 0; i < AMDGPU_SMU_TIMEOUT_US; i++) {
        UInt32 rsp = soc15ReadReg32(base + mmMP1_SMN_C2PMSG_90);
        if (rsp != 0) {
            break;
        }
        IODelay(1);
    }

    // Step 2: Write parameter (0 = current package power)
    soc15WriteReg32(base + mmMP1_SMN_C2PMSG_82, 0);

    // Step 3: Clear response register
    soc15WriteReg32(base + mmMP1_SMN_C2PMSG_90, 0);
    memoryBarrier();

    // Step 4: Send message
    soc15WriteReg32(base + mmMP1_SMN_C2PMSG_66, PPSMC_MSG_GetCurrPkgPwr_SMU9);
    memoryBarrier();

    // Step 5: Wait for response with timeout
    UInt32 resp = 0;
    for (UInt32 i = 0; i < AMDGPU_SMU_TIMEOUT_US; i++) {
        resp = soc15ReadReg32(base + mmMP1_SMN_C2PMSG_90);
        if (resp != 0) {
            break;
        }
        IODelay(1);
    }

    if (resp != 1) {
        return kIOReturnError;
    }

    // Step 6: Read power value (in watts)
    UInt32 value = soc15ReadReg32(base + mmMP1_SMN_C2PMSG_82);
    *data = static_cast<float>(value);
    return kIOReturnSuccess;
}

//==============================================================================
// MARK: - Initialization (Device ID Detection)
//==============================================================================

bool AMDGPUDevice::initFromDevice(IOPCIDevice *device) {
    if (device == nullptr) {
        return false;
    }

    dev = device;
    auto deviceID = WIOKit::readPCIConfigValue(dev, WIOKit::kIOPCIConfigDeviceID);

    // === Chip Family Detection ===
    // Device ID ranges sourced from the Linux amdgpu driver (drivers/gpu/drm/amd/amdgpu/).
    // These are hardware identification facts, not copyrightable.

    switch (deviceID) {
    // === Raven iGPUs (GCN 5 / Vega) ===
    case 0x15D8: // Picasso
    case 0x15DD: // Raven
    case 0x15E7: // Barcelo
    case 0x1636: // Renoir
    case 0x1638: // Cezanne
    case 0x164C: // Lucienne
        chipFamily = 5; // Raven
        break;

    // === Vega 20 (Arctic Islands with THM11) ===
    case 0x66A0 ... 0x66AF:
        chipFamily = 4; // Arctic Islands
        isTHM11_ = true;
        break;

    // === Vega 10 (Arctic Islands) ===
    case 0x6860 ... 0x687F:
        chipFamily = 4; // Arctic Islands
        supportsPower_ = true;
        break;

    // === Vega 12 (Arctic Islands) ===
    case 0x69A0 ... 0x69AF:
        chipFamily = 4; // Arctic Islands
        break;

    // === Polaris 10/11/12 (Volcanic Islands / GCN 1.3) ===
    case 0x67C0 ... 0x67FF: // Polaris 10, Polaris 11
    case 0x6980 ... 0x699F: // Polaris 12
        chipFamily = 3; // Volcanic Islands
        supportsPower_ = true;
        break;

    // === Southern Islands (GCN 1.1-1.2) ===
    case 0x6600 ... 0x666F: // Bonaire
    case 0x67A0 ... 0x67BF: // Hawaii
    case 0x6900 ... 0x693F: // Tonga
        chipFamily = 2; // Southern Islands
        supportsPower_ = true;
        break;

    // === Sea Islands (GCN 1.0) ===
    case 0x6780 ... 0x679F: // Tahiti
    case 0x6800 ... 0x683F: // Venus, Cape Verde, Oland, etc.
        chipFamily = 1; // Sea Islands
        supportsPower_ = true;
        break;

    // === Navi (RDNA 1/2/3) ===
    case 0x7310 ... 0x73FF:
        chipFamily = 6; // Navi
        break;

    default:
        IOLog("AMDGPUDevice: Unsupported GPU device ID 0x%04X", deviceID);
        return false;
    }

    // Allocate lock for register access synchronization
    gpuLock = IOLockAlloc();
    if (gpuLock == nullptr) {
        IOLog("AMDGPUDevice: Failed to allocate gpuLock");
        return false;
    }

    IOLog("AMDGPUDevice: Detected chipFamily=%u, supportsPower=%d, isTHM11=%d, deviceID=0x%04X",
          chipFamily, supportsPower_, isTHM11_, deviceID);

    return true;
}

//==============================================================================
// MARK: - Cleanup
//==============================================================================

void AMDGPUDevice::free() {
    if (rmmio) {
        rmmio->release();
        rmmio = nullptr;
    }
    rmmioPtr = nullptr;

    if (gpuLock) {
        IOLockFree(gpuLock);
        gpuLock = nullptr;
    }

    dev = nullptr;
    OSObject::free();
}

//==============================================================================
// MARK: - Public Accessors
//==============================================================================

IOReturn AMDGPUDevice::getTemperature(UInt16 *data) {
    if (data == nullptr) {
        return kIOReturnBadArgument;
    }

    auto ret = ensureRMMIOMapped();
    if (ret != kIOReturnSuccess) {
        return ret;
    }

    switch (chipFamily) {
    case 1: // Sea Islands
    case 2: // Southern Islands
    case 3: // Volcanic Islands
        return smu7GetTemp(data);

    case 4: // Arctic Islands
        if (isTHM11_) {
            return thm11GetTemp(data);
        }
        return thm9GetTemp(data);

    case 5: // Raven
    case 6: // Navi
        return thm10GetTemp(data);

    default:
        return kIOReturnUnsupported;
    }
}

IOReturn AMDGPUDevice::getPower(float *data) {
    if (data == nullptr) {
        return kIOReturnBadArgument;
    }

    if (!supportsPower_) {
        return kIOReturnUnsupported;
    }

    auto ret = ensureRMMIOMapped();
    if (ret != kIOReturnSuccess) {
        return ret;
    }

    switch (chipFamily) {
    case 1: // Sea Islands
        return smu7GetPowerPMStatus(data);

    case 2: // Southern Islands
    case 3: // Volcanic Islands
        return smu7GetPowerSMC(data);

    case 4: // Arctic Islands
        return smu9GetPower(data);

    default:
        return kIOReturnUnsupported;
    }
}
