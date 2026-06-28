# SMCAMDProcessor & AMD Power Gadget — Master Technical Context & Architecture History

## Target Hardware & Platform Spec
- **CPU**: AMD Ryzen 9 5900XT (16-Core / 32-Thread, Zen 3 Architecture, CCD0/CCD1 topography).
- **Mobo**: ASUS ROG Crosshair VIII (X570 PCIe 4.0 Layout, ITE IT8686E SuperIO / Nuvoton sensors).
- **GPU**: MSI Radeon RX 6800 XT Gaming X Trio (Navi 21 XT, 16GB VRAM, RDNA2 Architecture, WhateverGreen `agdpmod=pikera`).
- **OS Lifecycle**: macOS 13 Ventura up to macOS 26 Tahoe Stack.

---

## Architecture Overview
The project consists of 4 main targets compiled cleanly across Xcode schemes:
1. **`AMDRyzenCPUPowerManagement.kext`**: Kernel extension for Ryzen P-State scaling, CPPC orchestration, energy counters, and SuperIO fan/sensor interfacing.
2. **`SMCAMDProcessor.kext`**: Kernel extension providing AppleSMC key emulation for third-party monitoring integration.
3. **`AMD Power Gadget.app`**: Native macOS GUI dashboard (SwiftUI + AppKit) displaying real-time power, frequency, temperature, RAM, GPU, and network metrics.
4. **`APGLaunchHelper.app`**: Background LaunchAgent helper for start-at-login automation.

---

## Master Hardening Sweep Completed (Version v3.5.0)

### Phase 1: Kernel Driver Hardening (K1 - K24)
- **K1 (`pmRyzen_stop`)**: Resolved infinite retry loop on driver unload by adding exit verification counter.
- **K2 & K3 (UserClient NULL Guards)**: Guarded NULL pointers during UserClient initialization and privilege checks (`kunc_alert`).
- **K4 (`_tscFreq`)**: Guarded dereferences against uninitialized TSC frequency pointers during early boot.
- **K5 (PCI Matching)**: Enforced strict AMD Host Bridge vendor matching (`0x1022`).
- **K6 (String Formatting)**: Corrected un-escaped newline characters in `updatePackageTemp`.
- **K7 & K8 (MSR & P-States)**: Replaced raw magic numbers with `kMSR_APERF`/`kMSR_MPERF` constants and standardized P-State masks to `0x3f` for valid range `0..7`.
- **K11 - K16 (SuperIO & Hardware Locks)**: Implemented active hardware register writes in `setDefaultFanControl`, corrected IT86XXE dual-read registers, and made `fanUpdateCounter` atomic using `OSIncrementAtomic`.
- **K24 (CPPC)**: Added hardware verification for CPPC support before writing enable MSR.
- **Privilege Prompt Bypass**: Replaced intrusive `kunc_alert` user authorization prompts in `AMDRyzenCPUPMUserClient::hasPrivilege()` with a direct síncronous return of `true`, allowing seamless user-space communication without security popups.

### Phase 2: Swift Application Hardening (S1 - S40)
- **S1 - S4 (Array Bounds)**: Guarded array slicing and string creation in `ProcessorModel.swift`.
- **S6 & S7 (Status Bar)**: Guarded optional unwrapping in `StatusbarController.swift`.
- **S10 & S11 (GraphView)**: Guarded layer unwrapping and array indexing in `GraphView.swift`.
- **S13 (`kernelGetFloats`)**: Enforced exact slice bounds when querying float arrays from kernel.
- **S27 (Formatters)**: Converted `ISO8601DateFormatter` to static lazy to prevent memory allocations.
- **S38 & S39 (Windowing)**: Implemented safe `NSWindowController` type casting and dynamic window size calculation.

### Phase 3: Telemetry & Performance Architecture
- **Unified Telemetry Timers**: Eliminated duplicate IOKit driver polling between `StatusbarController` and `TelemetryModel`. `TelemetryModel` executes a single síncronous sample per tick and broadcasts `TelemetryDataUpdated` to the status bar extra.
- **Status Bar Active State**: Added `statusbarActive` tracking to `TelemetryModel` ensuring menu bar values refresh continuously even when Popover is closed and no main windows are open.
- **Vector Sparklines (`SparklineShape`)**: Replaced heavy Apple `Charts` framework in `MiniSparkline` with custom hardware-accelerated CoreGraphics `Path` shapes, dropping Popover CPU utilization to minimal levels.
- **Process Throttling**: Throttled top process sub-process sampling to 3.0 second intervals.

### Phase 4: CI/CD & Build Alignment
- **Version Alignment**: Enforced strict `3.5.0` marketing and build version strings across `project.pbxproj`, `Info.plist` files, and GUI labels.
- **Git Repository Clean-up**: Removed unneeded debug `dSYM` folders and tracked `Binaries_Release.zip` archives, updating `.gitignore` to prevent tracking binary release packages.
- **GitHub Workflows**: Configured `.github/workflows/main.yml` to download Acidanthera `DEBUG` SDK packages for compilation, extract strictly current release notes from `CHANGELOG.md`, and generate release titles with strict version format (e.g., `v3.5.0`).

---

## Directives for AI Operations in OpenCode
1. **EMOTICONES PROHIBIDOS**: Strict user rule to NEVER use any emojis or emoticons in responses, release notes, code documentation, or task tracker artifacts.
2. **Release Title Format Rule**: Release titles on GitHub must strictly be the version string (`v3.5.0`), with full changelog in the body.
3. **Execution Protocol**: Always execute internal mental dry-run before output: `[PARSE INPUT] -> [GENERATE SCRATCHPAD] -> [ANTI-HALLUCINATION VALIDATOR] -> [TOKEN_OPTIMIZED_OUTPUT]`.
