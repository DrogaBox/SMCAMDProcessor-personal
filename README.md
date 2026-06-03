# SMCAMDProcessor & AMD Power Gadget (Tahoe Edition)

[![Github release](https://img.shields.io/github/downloads/trulyspinach/SMCAMDProcessor/total.svg?color=pink)](https://github.com/trulyspinach/SMCAMDProcessor/releases)
![Github release](https://img.shields.io/github/repo-size/trulyspinach/SMCAMDProcessor.svg?color=blue)

XNU kernel extensions for power management and monitoring of AMD Zen processors on macOS, coupled with a premium, optimized GUI application: **AMD Power Gadget**.

This fork represents the modernized **Tahoe Edition (2026)**, updated and fully optimized for stability, performance, and rich visual styling under macOS Sonoma (14.0) through macOS Tahoe (15.x / 16.x).

![AMD Power Gadget Tahoe Edition Animated Preview](imgs/ani.gif)

---

## 🧬 Supported AMD Processors

Full compatibility with all AMD Zen architectures supported by the **AMD Vanilla kernel patches**:

| Architecture | CPUID Family | Models | Example CPUs | Status |
|---|---|---|---|---|
| **Zen** | `17h` | `01h-0Fh` | Ryzen 1000, Threadripper 1000 | ✅ Full |
| **Zen+** | `17h` | `10h-2Fh` | Ryzen 2000, Threadripper 2000 | ✅ Full |
| **Zen 2** | `17h` | `30h+` | Ryzen 3000, Threadripper 3000 | ✅ Full |
| **Zen 3** | `19h` | `00h-0Fh` | Ryzen 5000 | ✅ Full |
| **Zen 3+** | `19h` | `40h-5Fh` | Ryzen 6000 Mobile | ✅ Full |
| **Zen 4** | `19h` | `10h-1Fh, 60h-7Fh` | Ryzen 7000, Threadripper 7000 | ✅ Full |
| **Zen 5** | `1Ah` | `40h-4Fh` | Ryzen 9000 (Granite Ridge) | ✅ Full |

> **Note:** Per-CCD temperature monitoring uses architecture-specific SMN register offsets (`0x154` for Zen 1–3, `0x308` for Zen 4–5) matching the Linux kernel `k10temp` driver for accurate thermal reporting across all generations.

---

## 🚀 Key Modernizations (Tahoe Edition)

### 🖥️ Performance & Resource Optimization
* **In-Process Network Telemetry (0% CPU Overhead):** Replaced the resource-heavy, background `/usr/bin/nettop` subprocess loops with a high-performance, in-process network query engine using low-level `sysctl(NET_RT_IFLIST2)` calls. CPU usage dropped from 20% to **literally 0%**, matching professional tools like *iStat Menus*.
* **Memory & Kernel Panic Immunization:** Added safety handlers to automatically de-register and clean up VirtualSMC notifications (`vsmcNotifier->remove()`) when unloading drivers, eliminating kernel dangling-pointer panics. Added float-to-int conversion protections to prevent SwiftUI runtime crashes.
* **Dynamic 32-Thread Monitoring:** Enhanced the Dashboard grid utilizing the Darwin kernel API `host_processor_info` to accurately track and report the usage of up to 32 logical threads (e.g., Ryzen 9 5900XT) in real-time.

### 🎨 Premium Visual Overhaul
* **Full-Bleed AMD Ryzen "SMC" AppIcon:** Designed a 3D-modeled, full-bleed AMD Ryzen Zen architecture processor icon in high resolution, displaying the acronym **"SMC"** with bold typography and elegant drop shadows.
* **Interactive Menu Bar Preview (`MenuBarPreview`):** Added a real-time status bar layout preview inside the Settings panel that updates instantly as you customize columns, Fahrenheit conversion, or alert colors.
* **Multi-Style Network Charts:** A three-mode interactive graph in the Dashboard featuring:
  * *Barras (Bidireccional)*: A dense, responsive upload/download monitor in the style of *Little Snitch*.
  * *Curvas (Superpuestas)*: Suavizada Catmull-Rom curves with translucent gradients.
  * *Total*: Combined bandwidth tracking with a horizontal dashed `RuleMark` displaying your dynamic average download speed.

### 🛠️ Configurable Alert Colors & Presets
* **Dynamic Color Alerts (Temperature Only):** Restructured to colorize *only* the temperature readings when active, keeping GHz, Power, Fan, and Memory columns in standard `.labelColor` to avoid distraction.
* **Custom Alert Limits (Text Input):** Replaced the limit slider with a direct text input box supporting thresholds from 30°C (perfect for idle testing) up to 100°C.
* **Editable Preset Lists:** You can type your preferred threshold options directly in the app (e.g. `30, 45, 60, 80, 90`) to dynamically populate the menu bar dropdown menu.

---

## 📦 Installation & Setup

`SMCAMDProcessor` is distributed as two separate kernel extensions (Kexts):
1. **`AMDRyzenCPUPowerManagement.kext`**: The core power management and hardware monitoring driver. This kext is **required** to use **AMD Power Gadget**.
2. **`SMCAMDProcessor.kext`**: The VirtualSMC sensor publishing plugin. This publishes CPU temperatures and fan readings to VirtualSMC, enabling third-party apps like *Stats* or *HWMonitorSMC2* to read them. It depends on `AMDRyzenCPUPowerManagement.kext` and must be loaded after it.

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

## ⚙️ Advanced Features

### P-State Editor (Safe Mode Guard)
Includes a modern protection toggle in the Advanced speed shift panel. Controls are locked and rendered translucent (`opacity(0.4)`) until safety is unlocked, preventing accidental hardware setting changes.

### Custom Fan Overrides (SMC Fans)
Features a redesigned AppKit fan speed view that supports dynamic width scaling up to 300px to display full fan names (e.g., "CPU OPT Fan"), alongside custom-drawn sliders aligning track progress with the active accent color.

---

## 🛡️ Safety & Security
All telemetry queries are performed directly through safe reads on Zen SMN registers (`0x00059800`) mimicking the Linux kernel `k10temp` and FreeBSD `amdtemp` standards. No unsafe MSR registers are written, ensuring full hardware protection and accurate reporting.

## 📝 Credits & Legacy Contributors
* **trulyspinach** for the original framework and kext base.
* **aluveitie** for improvements and macOS Sequoia/Tahoe adaptations.
* **mauricelos**, **Lorys89**, **mbarbierato** for SMC SuperIO chip drivers.

