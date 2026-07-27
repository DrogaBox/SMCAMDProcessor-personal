//
//  AMDGPU.hpp
//  AMDRyzenCPUPowerManagement
//
//  GPU temperature and power monitoring via PCI BAR MMIO.
//  All register addresses are hardware facts from the Linux amdgpu driver documentation.
//  Implementation is original — no code copied from SMCRadeonSensors.
//

#pragma once

#include <IOKit/IOService.h>
#include <IOKit/pci/IOPCIDevice.h>

/**
 *  AMD GPU monitoring device.
 *
 *  Reads GPU temperature and power by mapping the PCI BAR and reading
 *  thermal registers directly. Supports AMD dGPUs from GCN 1.0 (Sea Islands)
 *  through RDNA 2/3 (Navi 2x/3x) and all Vega-based iGPUs (Raven, etc.).
 *
 *  Chip family detection is based on the PCI device ID, following the
 *  ranges documented in the Linux amdgpu kernel driver (drivers/gpu/drm/amd/).
 */
class AMDGPUDevice : public OSObject {
    OSDeclareDefaultStructors(AMDGPUDevice);

    /** PCI device for BAR mapping */
    IOPCIDevice *dev{nullptr};

    /** Mapped MMIO region (PCI BAR2 or BAR5) */
    IOMemoryMap *rmmio{nullptr};

    /** Virtual address of the mapped BAR */
    volatile UInt32 *rmmioPtr{nullptr};

    /** Protects multi-step register read/write sequences */
    IOLock *gpuLock{nullptr};

    /**
     *  Chip family identifier.
     *
     *  Mappings:
     *   1 = SeaIslands       (GCN 1.0: Tahiti, Venus, Cape Verde)
     *   2 = SouthernIslands  (GCN 1.1-1.2: Bonaire, Hawaii, Tonga)
     *   3 = VolcanicIslands  (GCN 1.3: Polaris 10/11/12)
     *   4 = ArcticIslands    (GCN 5: Vega 10, Vega 12, Vega 20)
     *   5 = Raven            (GCN 5: Raven, Picasso, Renoir, Cezanne iGPUs)
     *   6 = Navi             (RDNA 1/2/3: Navi 1x, 2x, 3x)
     */
    UInt8 chipFamily{0};

    /** Whether this GPU supports power reading via SMU mailbox */
    bool supportsPower_{false};

    /** Whether this GPU uses THM11 temperature register (Vega 20) */
    bool isTHM11_{false};

    /**
     *  Ensure the PCI BAR is mapped and accessible.
     *  Uses BAR5 for GCN 1.2+, BAR2 for older chips.
     */
    IOReturn ensureRMMIOMapped();

    /**
     *  MMIO register read (pre-GCN 5 / pre-Raven).
     *  Falls back to indexed PCI config for out-of-range addresses.
     */
    UInt32 readReg32(UInt32 reg);

    /**
     *  MMIO register write (pre-GCN 5 / pre-Raven).
     *  Falls back to indexed PCI config for out-of-range addresses.
     */
    void writeReg32(UInt32 reg, UInt32 val);

    /**
     *  SOC15-style MMIO register read (GCN 5 / RDNA+).
     *  Uses PCIE_INDEX2/DATA2 for out-of-range addresses.
     */
    UInt32 soc15ReadReg32(UInt32 reg);

    /**
     *  SOC15-style MMIO register write (GCN 5 / RDNA+).
     *  Uses PCIE_INDEX2/DATA2 for out-of-range addresses.
     */
    void soc15WriteReg32(UInt32 reg, UInt32 val);

    /**
     *  Read an SMC indirect register.
     *  Dispatches to the correct index/data pair based on chip family.
     */
    UInt32 readIndirectSMC(UInt32 reg);

    /**
     *  Write an SMC indirect register.
     *  Dispatches to the correct index/data pair based on chip family.
     */
    void writeIndirectSMC(UInt32 reg, UInt32 val);

    /** Poll SMU7 SMC response register until ready or timeout */
    UInt32 smu7PollResponse();

    // == Temperature reading methods ==

    /** SMU7-style temperature (Sea Islands, Southern Islands, Volcanic Islands) */
    IOReturn smu7GetTemp(UInt16 *data);

    /** THM9 temperature (Arctic Islands, non-THM11) */
    IOReturn thm9GetTemp(UInt16 *data);

    /** THM11 temperature (Vega 20) */
    IOReturn thm11GetTemp(UInt16 *data);

    /** THM10 temperature (Raven, Navi) */
    IOReturn thm10GetTemp(UInt16 *data);

    // == Power reading methods ==

    /** SMU7 power via PM Status log (Sea Islands) */
    IOReturn smu7GetPowerPMStatus(float *data);

    /** SMU7 power via SMC mailbox (Southern Islands, Volcanic Islands) */
    IOReturn smu7GetPowerSMC(float *data);

    /** SMU9 power (Arctic Islands) */
    IOReturn smu9GetPower(float *data);

public:

    /**
     *  Initialize from a matched IOPCIDevice.
     *  Detects chip family from device ID and allocates locks.
     *  Returns false if the GPU is not supported or allocation fails.
     */
    bool initFromDevice(IOPCIDevice *device);

    /** Release all resources */
    void free() APPLE_KEXT_OVERRIDE;

    /**
     *  Read the GPU temperature.
     *  Output in SP78 format (UInt16: signed 8.8 fixed-point).
     */
    IOReturn getTemperature(UInt16 *data);

    /**
     *  Read the GPU power consumption in watts.
     */
    IOReturn getPower(float *data);

    /** Whether this GPU supports power reading */
    bool supportsPower() { return supportsPower_; }
};
