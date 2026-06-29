# SMCAMDProcessor & AMD Power Gadget (Tahoe Edition)

[![Github release](https://img.shields.io/github/downloads/DrogaBox/SMCAMDProcessor-personal/total.svg?color=pink)](https://github.com/DrogaBox/SMCAMDProcessor-personal/releases)
![Github release](https://img.shields.io/github/repo-size/DrogaBox/SMCAMDProcessor-personal.svg?color=blue)

High-performance XNU kernel extensions and modern SwiftUI telemetry suite for AMD Zen processors (Zen 1 through Zen 5) on macOS 13 Ventura up to macOS 26 Tahoe.

![AMD Power Gadget Tahoe Edition Animated Preview](imgs/ani.gif)

---

## Overview & Architecture

SMCAMDProcessor and AMD Power Gadget (Tahoe Edition) represent a complete architectural modernization of the AMD Ryzen macOS telemetry stack. Re-engineered from the ground up for enterprise-grade kernel safety, microsecond hardware precision, and native Apple silicon-like software efficiency, this project delivers real-time monitoring and autonomous power management for Ryzentosh systems.

---

## Key Technical Features

### 1. Enterprise Kernel Safety & Hardening (AMDRyzenCPUPowerManagement.kext)
- Authentic XNU Privilege Validation: Replaced mock privilege checks with authentic kernel root verification via `proc_suser` and `kauth_cred_getuid`.
- Boundary-Checked String Tables & Mach-O Verification: Strict bounds checking on symbol table lookups (`kernel_resolver.c`) and explicit `MH_MAGIC_64` header verification prior to function resolution.
- IPC Lifecycle Integrity: Strict 6-step teardown sequence during driver unload (`stop()`), retaining `fIOPCIDevice` and eliminating dangling pointers or memory leaks.
- Client Process Authorization: Bound-checked executable identity validation (`proc_name`) in `initWithTask()` ensuring connection authorization strictly for trusted applications.

### 2. Micro-Architecture & Memory Optimization
- 64-Byte Cache Line Alignment: Applied `alignas(64)` alignment to core data structures (`pmProcessor_t`), isolating per-thread state to L1 cache lines and eliminating false sharing across all 32 logical threads of high-end desktop (HEDT) processors.
- Kernel RAM Footprint Reduction: Reduced per-core memory footprint from 8288 bytes down to 128 bytes, lowering total driver RAM allocation from 265KB to just 4KB on 32-thread architectures.
- XNU_MAX_CPU Perimeter Protection: Built-in perimeter boundary guards across processor indexing loops to prevent out-of-bounds array access on multi-core Ryzen 9 and Threadripper systems.
- Sleep/Wake Race Condition Prevention: `serviceInitialized` guardrails across timer callbacks combined with automatic TSC base re-synchronization upon sleep and wake transitions.

### 3. Precision RAPL Energy & Sensor Telemetry (SMCAMDProcessor.kext)
- Dynamic RAPL Power Scaling: Hardware MSR decoding (`0xC0010299`) with `1ULL << energyStatusUnits` exponent math for accurate package wattage calculations across Zen 3 and Zen 5.
- Granular per-CCD Thermal Monitoring: Direct PCI die register queries exposing individual CCD temperatures (VirtualSMC `TCxC` / `TCxc` keys) with automatic package fallback for multi-die CPUs.
- Expanded Super I/O Fan Support: Native RPM monitoring and hardware PWM fan curve controls for Nuvoton (NCT668X, NCT6796D) and ITE (IT8628E, IT8686E, IT8689E) controllers.

### 4. High-Performance Dashboard & Menu Bar Extra (AMD Power Gadget.app)
- MainActor Serial I/O Offloading: Hardware sampling operations are decoupled off the main thread onto a high-priority serial queue (`ioQueue`) with skip-if-busy guards, guaranteeing smooth 60 FPS UI rendering under max load.
- Diff-Based Rendering Engine: Smart threshold tracking skips redundant menu bar extra redraws (`setNeedsDisplay`) when sensor metrics fluctuate within idle tolerances.
- In-Process Zero-Allocation Network Analytics: Direct CChar ASCII buffer parsing using `sysctl(NET_RT_IFLIST2)` eliminates heap allocations, backed by an adaptive low-frequency background sampling mode.
- macOS 26 Tahoe UI Aesthetics: Designed with native Liquid Glass material vibrancy (`NSVisualEffectView`) and dynamic hierarchical SF Symbols 7+ fill glyphs (`cpu.fill`, `fan.fill`, `memorycard.fill`).
- Hardware-Autonomous CPPC & EPP Control: Native opt-in (`-amdcppcactive`) for CPPC Active Mode, delegating microsecond clock scaling to the internal System Management Unit (SMU) with configurable EPP profiles (Performance, Balanced, Power Save).

---

## Supported AMD Processors

Full compatibility with all AMD Zen architectures supported by the AMD Vanilla kernel patches:

- **Zen (Family 17h, Models 01h-0Fh)**: Ryzen 1000, Threadripper 1000 (Full Compatibility)
- **Zen+ (Family 17h, Models 10h-2Fh)**: Ryzen 2000, Threadripper 2000 (Full Compatibility)
- **Zen 2 (Family 17h, Models 30h+)**: Ryzen 3000, Threadripper 3000 (Full Compatibility)
- **Zen 3 (Family 19h, Models 00h-0Fh)**: Ryzen 5000 (Full Compatibility)
- **Zen 3+ (Family 19h, Models 40h-5Fh)**: Ryzen 6000 Mobile (Full Compatibility)
- **Zen 4 (Family 19h, Models 10h-1Fh, 60h-7Fh)**: Ryzen 7000, Threadripper 7000 (Full Compatibility)
- **Zen 5 (Family 1Ah, Models 40h-4Fh)**: Ryzen 9000 Granite Ridge (Full Compatibility)

---

## Installation & OpenCore Setup

### Kext Loading Order
Ensure the kexts are loaded in the exact dependency order in your OpenCore `config.plist`:
1. `Lilu.kext`
2. `VirtualSMC.kext`
3. `AMDRyzenCPUPowerManagement.kext` (Core driver - Required)
4. `SMCAMDProcessor.kext` (VirtualSMC sensor plugin)

### OpenCore Requirements
- OpenCore 0.7.1 or newer.
- AMD Vanilla kernel patches applied.
- `ProvideCurrentCpuInfo` quirk enabled in `config.plist`.
- Boot argument `-amdcppcactive` (Optional, to enable autonomous CPPC EPP mode on boot).

---

## Credits & Community Acknowledgements

### Original Authors & Contributors
- **trulyspinach** for the original framework and kext base.
- **aluveitie** for improvements and macOS Sequoia/Tahoe adaptations.
- **mauricelos**, **Lorys89**, **mbarbierato** for SMC SuperIO chip drivers.

### AMD-OSX Community Recognition
Special recognition to the AMD-OSX community for research, development, and testing:
- **Shaneee**: Core developer and administrator of AMD-OSX.
- **AlGrey**: Developer of the core AMD Vanilla kernel patches.
- **Edhawk**, **CorpGhost**, **Royal**: Forum moderators, ACPI experts, and community support leaders.
- **AMD-OSX Discord Community Testers**: Special thanks to fabiosun, Kackvogel 4K, Can, and MacOSx11 for extensive hardware testing across Zen 4 and Zen 5 silicon.
