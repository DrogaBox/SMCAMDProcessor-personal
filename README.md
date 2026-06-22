# SMCAMDProcessor & AMD Power Gadget (Tahoe Edition)

[![Github release](https://img.shields.io/github/downloads/DrogaBox/SMCAMDProcessor-personal/total.svg?color=pink)](https://github.com/DrogaBox/SMCAMDProcessor-personal/releases)
![Github release](https://img.shields.io/github/repo-size/DrogaBox/SMCAMDProcessor-personal.svg?color=blue)

XNU kernel extensions for power management and monitoring of AMD Zen processors on macOS, coupled with a premium, optimized GUI application: **AMD Power Gadget**.

This fork represents the modernized **Tahoe Edition (2026)**, updated and fully optimized for stability, performance, and rich visual styling under macOS Sonoma (14.0) through macOS Tahoe (15.x / 16.x).

> [!NOTE]
> **Community Disclaimer & Development Context:**
> This modernized fork was developed with the assistance of **Antigravity 2** (an agentic AI coding assistant). We apologize if this approach offends anyone in the community. The decision to use AI support was made because the original source repository has not been updated since 2024, and no other developer had taken over to modernize it. The sole intention of this project is to keep this essential utility functional and up-to-date for the Hackintosh community.

![AMD Power Gadget Tahoe Edition Animated Preview](imgs/ani.gif)

---

## Supported AMD Processors

Full compatibility with all AMD Zen architectures supported by the **AMD Vanilla kernel patches**:

| Architecture | CPUID Family | Models | Example CPUs | Status |
|---|---|---|---|---|
| **Zen** | `17h` | `01h-0Fh` | Ryzen 1000, Threadripper 1000 | Full |
| **Zen+** | `17h` | `10h-2Fh` | Ryzen 2000, Threadripper 2000 | Full |
| **Zen 2** | `17h` | `30h+` | Ryzen 3000, Threadripper 3000 | Full |
| **Zen 3** | `19h` | `00h-0Fh` | Ryzen 5000 | Full |
| **Zen 3+** | `19h` | `40h-5Fh` | Ryzen 6000 Mobile | Full |
| **Zen 4** | `19h` | `10h-1Fh, 60h-7Fh` | Ryzen 7000, Threadripper 7000 | Full |
| **Zen 5** | `1Ah` | `40h-4Fh` | Ryzen 9000 (Granite Ridge) | Full |

> **Note:** Per-CCD temperature monitoring uses architecture-specific SMN register offsets (`0x154` for Zen 1–3, `0x308` for Zen 4–5) matching the Linux kernel `k10temp` driver for accurate thermal reporting across all generations.

### Zen 5 (Family 1Ah) & Newer AMD Processor Support
To support frequency monitoring, P-state customization, and logging diagnostics on newer AMD Zen 5 (Family 1Ah) processors, the following technical changes were implemented:

* **12-bit Multiplier (CpuFid):** In Zen 5, the `CpuFid` multiplier field inside the P-state registers (`MSRC001_0064` / `0xC0010064` through `0xC001006B`) was expanded from 8 bits to 12 bits (bits 0–11).
* **Omission of Divisor (CpuDfsId):** The legacy frequency divisor `CpuDfsId` is no longer utilized by the Zen 5 hardware.
* **New Frequency Formula:** The clock speed is calculated directly as `CpuFid * 5.0 MHz` instead of the legacy Zen 1–4 formula `(CpuFid / CpuDfsId) * 200.0 MHz`.
* **Kext and GUI Sync:** Both the `AMDRyzenCPUPowerManagement` kernel extension and the `AMD Power Gadget` P-State Editor dynamically detect `cpuFamily >= 0x1A` to apply these decoding and encoding rules. In the GUI P-State Editor, the `CpuDfsId` column is dynamically disabled and locked for Zen 5 to prevent invalid values.
* **Kernel Extension Debugging Infrastructure:**
  * Built dedicated `Debug` versions of `AMDRyzenCPUPowerManagement.kext` and `SMCAMDProcessor.kext` to preserve verbose logs.
  * Added the `-amdpdbg` OpenCore boot argument requirement to activate `debugEnabled` at the kernel extension level.
  * Provided instructions to fetch kext logs using the macOS Unified Logging system (e.g. `log show --predicate 'sender == "wtf.spinach.AMDRyzenCPUPowerManagement"' --info --debug --last 10m`) to bypass the quick rollover of the `dmesg` ring buffer on modern macOS releases (Sonoma/Sequoia/Tahoe).
* **Kernel Panic Mitigation:** Replaced fragile `panic()` calls in critical MSR operations (such as `updateClockSpeed`, `updateInstructionDelta`, `setCPBState`, etc.) with safe checks and `IOLog` reporting. If reading/writing a register fails, the kext logs the event and continues execution instead of crashing the operating system.

---

## Key Modernizations (Tahoe Edition)

### Performance & Resource Optimization
* **In-Process Network Telemetry (0% CPU Overhead):** Replaced the resource-heavy, background `/usr/bin/nettop` subprocess loops with a high-performance, in-process network query engine using low-level `sysctl(NET_RT_IFLIST2)` calls. CPU usage dropped from 20% to **literally 0%**, matching professional tools like *iStat Menus*.
* **Memory & Kernel Panic Immunization:** Added safety handlers to automatically de-register and clean up VirtualSMC notifications (`vsmcNotifier->remove()`) when unloading drivers, eliminating kernel dangling-pointer panics. Added float-to-int conversion protections to prevent SwiftUI runtime crashes.
* **Dynamic 32-Thread Monitoring:** Enhanced the Dashboard grid utilizing the Darwin kernel API `host_processor_info` to accurately track and report the usage of up to 32 logical threads (e.g., Ryzen 9 5900XT) in real-time.

### Premium Visual Overhaul
* **Full-Bleed AMD Ryzen "SMC" AppIcon:** Designed a 3D-modeled, full-bleed AMD Ryzen Zen architecture processor icon in high resolution, displaying the acronym **"SMC"** with bold typography and elegant drop shadows.
* **Interactive Menu Bar Preview (`MenuBarPreview`):** Added a real-time status bar layout preview inside the Settings panel that updates instantly as you customize columns, Fahrenheit conversion, or alert colors.
* **Multi-Style Network Charts:** A three-mode interactive graph in the Dashboard featuring:
  * *Bars (Bidirectional)*: A dense, responsive upload/download monitor in the style of *Little Snitch*.
  * *Curves (Overlaid)*: Smoothed Catmull-Rom curves with translucent gradients.
  * *Total*: Combined bandwidth tracking with a horizontal dashed `RuleMark` displaying your dynamic average download speed.

### Configurable Alert Colors & Presets
* **Dynamic Color Alerts (Temperature Only):** Restructured to colorize *only* the temperature readings when active, keeping GHz, Power, Fan, and Memory columns in standard `.labelColor` to avoid distraction.
* **Custom Alert Limits (Text Input):** Replaced the limit slider with a direct text input box supporting thresholds from 30°C (perfect for idle testing) up to 100°C.
* **Editable Preset Lists:** You can type your preferred threshold options directly in the app (e.g. `30, 45, 60, 80, 90`) to dynamically populate the menu bar dropdown menu.

---

## Installation & Setup

`SMCAMDProcessor` is distributed as two separate kernel extensions (Kexts):
1. **`AMDRyzenCPUPowerManagement.kext`**: The core power management and hardware monitoring driver. This kext is **required** to use **AMD Power Gadget**.
2. **`SMCAMDProcessor.kext`**: The VirtualSMC sensor publishing plugin. This publishes CPU temperatures and fan readings to VirtualSMC, enabling third-party system monitors or *HWMonitorSMC2* to read them. It depends on `AMDRyzenCPUPowerManagement.kext` and must be loaded after it.

### OpenCore Configuration Order:
Ensure the kexts are loaded in the correct dependency order in your `config.plist`:
1. `Lilu.kext`
2. `VirtualSMC.kext`
3. **`AMDRyzenCPUPowerManagement.kext`**
4. **`SMCAMDProcessor.kext`**

### AMD Vanilla Patches Requirement:
This kext requires the [AMD Vanilla kernel patches](https://github.com/AMD-OSX/AMD_Vanilla) to be applied in your OpenCore `config.plist`. Ensure:
- OpenCore **0.7.1+** (latest recommended)
- `ProvideCurrentCpuInfo` quirk is **enabled**
- Core count patch matches your CPU's physical core count

---

## Advanced Features

### P-State Editor (Safe Mode Guard)
Includes a modern protection toggle in the Advanced speed shift panel. Controls are locked and rendered translucent (`opacity(0.4)`) until safety is unlocked, preventing accidental hardware setting changes.

### Custom Fan Overrides (SMC Fans)
Features a redesigned AppKit fan speed view that supports dynamic width scaling up to 300px to display full fan names (e.g., "CPU OPT Fan"), alongside custom-drawn sliders aligning track progress with the active accent color.

### CPPC Active Mode & EPP (Hardware-Autonomous Power Management)
Starting in version **3.2.0**, the kernel extension and GUI application support native **CPPC Active Mode (EPP)**, bringing modern hardware-autonomous frequency scaling (matching Windows 11 and Linux `amd_pstate_epp` drivers) to Zen 3 (Ryzen 5000) and newer processors:

* **Hardware-Autonomous Scaling**: In legacy mode, macOS micro-manages clock frequencies by cycling through coarse, static P-states. In CPPC Active Mode, the driver disables legacy P-state overrides and delegates frequency control to the CPU's internal **System Management Unit (SMU)**. The SMU adjusts clock speeds and voltages dynamically in microsecond intervals based on load, thermal, and current metrics.
* **Energy Performance Preference (EPP)**: Allows you to define your power profile preference directly in the hardware register `MSR_AMD_CPPC_REQ` (`0xC00102B3`):
  * **Performance** (`EPP = 0x00`): Prioritizes maximum boost clock speeds and throughput.
  * **Balanced Perf** (`EPP = 0x3F`): The default profile, offering a perfect balance of responsiveness and idle energy savings.
  * **Balanced Power** (`EPP = 0x7F`): Reduces boosting aggressiveness for lower heat and noise.
  * **Power Save** (`EPP = 0xFF`): Locks the CPU at low frequencies for maximum energy savings and cool operation.
* **Boot Opt-In**: To enable CPPC Active Mode on startup, append the `-amdcppcactive` boot argument to your OpenCore `boot-args` in `config.plist`. You can then toggle CPPC Active Mode and change EPP profiles on-the-fly under the **Advanced** tab of the **AMD Power Gadget** application.
* **Driver Communication Sanitization**: The UserClient communication layer (selectors 0–22, 90–94) has been audited and fully sanitized. Input parameter counts, output structure pointers, and array bounds are strictly verified before copying data to prevent buffer overflows or kernel panic stability issues.

---

## Safety & Security
All telemetry queries are performed directly through safe reads on Zen SMN registers (`0x00059800`) mimicking the Linux kernel `k10temp` and FreeBSD `amdtemp` standards. No unsafe MSR registers are written, ensuring full hardware protection and accurate reporting.

## Credits & Legacy Contributors
* **trulyspinach** for the original framework and kext base.
* **aluveitie** for improvements and macOS Sequoia/Tahoe adaptations.
* **mauricelos**, **Lorys89**, **mbarbierato** for SMC SuperIO chip drivers.

## AMD-OSX Community Acknowledgements

This project would not be possible without the extensive research, development, and support provided by the **AMD-OSX** community. Special recognition goes to:

* **Shaneee**: Administrator and core developer of AMD-OSX, whose dedication and technical leadership keep the community thriving.
* **AlGrey**: Developer of the core AMD Vanilla kernel patches, which serve as the foundation for running macOS on Zen processors.
* **Edhawk**: Respected forum moderator and helper, whose continuous support and detailed guides have helped countless users configure their systems.
* **CorpGhost**: Valued forum contributor, widely recognized for motherboard patching, ACPI solutions, and helping users resolve complex configuration issues.
* **Royal**: Discord server moderator and helper, for maintaining the community platform and providing essential support to Ryzentosh users.
* **The AMD-OSX Community**: All the forum moderators, Discord staff, developers, and active testers who contribute their time and feedback to keep the Ryzentosh ecosystem active and stable.

---

## Release v2.1.4 Features & Contributors

Version **2.1.4** brings the most comprehensive modernization yet, featuring a complete SwiftUI status bar NSPopover, extended GPU telemetry (VRAM, Power, and Fan speed), multi-CCD temperature monitoring for Zen 5, localization fixes, and Xcode target optimizations.

### Key Improvements in v2.1.4:
* **SwiftUI NSPopover Menu:** Replaced the legacy text-based status bar menu with a modern, translucent popover panel featuring circular progress rings, linear bars, real-time sparklines, and a list of top CPU-consuming processes.
* **Extended GPU Telemetry:** Added support for GPU VRAM usage, power (W), and fan speed (RPM) telemetry with dual-row rendering for FAN and MEM columns in the Menu Bar.
* **Multi-CCD Temperature Tracking:** Integrated UserClient selector 20 to read active CCD counts and individual CCD temperatures for Zen 4 and Zen 5 processors.
* **Bug Fixes & Stability:** Fixed out-of-bounds guards in the status bar update loops, eliminated duplicate configurations, removed legacy panics from C++ drivers, and resolved scroll resets.
* **Clean Localization:** Fully translated popover and menu elements to English with appropriate localizable files for Spanish interfaces.
* **macOS 13.0 Ventura Support:** Lowered the deployment target to 13.0 to support Ventura through Sequoia and Tahoe.

### Special Thanks to Contributors & Testers:
Special thanks to the AMD-OSX Discord community members who helped test, report bugs, and refine this release:
* **Kackvogel 4K**: For extensive testing on the Ryzen 9 9950X3D under Cinebench workload, verifying lower idle temperatures, and reporting layout localization issues.
* **Can**: For testing the Ryzen 7 9850X3D and identifying the 10GHz+ CPU frequency reporting overflow.
* **MacOSx11**: For identifying and reporting the SMC/fan driver initialization crash on unsupported motherboards.
* **royal**: For the feedback highlighting the correct Xcode native i18n structure to ensure clean English baseline fallbacks.

---

For a detailed, step-by-step development log and walkthrough of all implemented stages, check out [CHANGELOG.md](CHANGELOG.md).


