<div class="cover-page">
    <span class="cover-title">AMD Power Gadget</span>
    <span class="cover-subtitle">User Manual & Comprehensive Feature Guide</span>
    <br><br>
    <span style="color: var(--accent-cyan);">Version 3.15.0</span>
</div>

## Introduction

Welcome to **AMD Power Gadget** and **SMCAMDProcessor**. This suite provides comprehensive telemetry and power management capabilities for AMD Ryzen processors on macOS (Hackintosh).

This manual explains *every single option, slider, and button* available in the application, leaving nothing to guesswork.

---

## 1. System Requirements & OpenCore Setup

### 1.1 Essential Kexts
Ensure the following kexts are present in your `EFI/OC/Kexts` folder and injected in your `config.plist` under `Kernel -> Add`, in this exact order:
1. `Lilu.kext` (Must be first)
2. `VirtualSMC.kext` (SMC emulator - DO NOT use FakeSMC)
3. `AMDRyzenCPUPowerManagement.kext` (Provides raw CPU data and SuperIO access)
4. `SMCAMDProcessor.kext` (Exports data to VirtualSMC for tools like iStat Menus)

### 1.2 OpenCore Quirks & Boot Arguments
- **ProvideCurrentCpuInfo** (Kernel -> Quirks): Set to `True`. Mandatory for macOS to correctly map AMD core topologies.
- **agdpmod=pikera** (boot-args): Required for Radeon RX 6000 series (Navi) to prevent black screens.

---

## 2. Power & Frequencies Tab

This tab provides real-time monitoring of your CPU's internal metrics.

### 2.1 Core Metrics & Silicon Quality
- **Core Frequencies**: Displays the real-time clock speed of each physical and logical core.
- **Silicon Quality Ranking (1. ~ X.)**: Zen 3/4 processors evaluate the quality of the silicon on a per-core basis. The application reads these CPPC tags and ranks your cores. Core `1.` is your absolute best core, capable of sustaining the highest boost frequencies at the lowest voltages. Use this data when tweaking the Curve Optimizer.
- **Package Power Tracking (PPT)**: Shows the total wattage consumed by the CPU package in real time.
- **Tctl / Tdie Temperatures**: The absolute junction temperature of the CPU.

---

## 3. Profiles Tab (CPU Speed Management)

The Profiles tab allows you to fundamentally alter how the CPU scales its frequencies and voltages.

### 3.1 EPP Profiles (Hardware Autonomous)
Energy Performance Preference (EPP) relies on the CPPC (Collaborative Processor Performance Control) interface. Instead of macOS dictating frequencies, you provide a "hint" to the CPU's internal SMU, and the hardware scales autonomously based on live load.
- **Power Saver**: Heavily limits boost clocks to prioritize battery life and acoustics.
- **Balanced**: The default state. Boosts when needed, but aggressively downclocks during idle.
- **Performance**: Keeps the cores highly responsive, maintaining higher base clocks and prioritizing single-thread boost speed over power efficiency.

### 3.2 CPU Speed Profiles (Legacy / Manual P-State)
Older Ryzen processors (or specific manual tuning scenarios) rely on static P-States (Power States).
- **Manual P-State Override**: Selecting a profile here completely restricts the CPU to a specific P-State step (e.g., P0 for max performance, P2 for base clock). The CPU will NOT scale dynamically; it is locked to the selected step.
- **Directly Edit Raw P-State Registers**: A highly advanced feature. Clicking this allows you to manually input the Hex values for Frequency, Voltage (VID), and DID. 
  > **[WARNING]** Requires kext privilege checks disabled. Incorrect VID values will cause instant system shutdown or potential hardware degradation.

---

## 4. Advanced CPU Tuning: Curve Optimizer

The **Curve Optimizer** is the most powerful tool for AMD Ryzen users. It adjusts the voltage/frequency curve dynamically.

- **Per-Core Curve Offsets (-30 to +30)**: Instead of applying a blanket voltage offset, you can assign a unique offset to *each individual physical core*. 
- **How it works**: A negative offset (e.g., `-15`) tells the CPU to use less voltage for a given frequency. Because the CPU runs cooler at a lower voltage, the Precision Boost algorithm automatically allows it to sustain higher boost clocks for longer periods.
- **Strategy**: Apply larger negative offsets (e.g., `-25`) to your lowest-ranked cores, and smaller offsets (e.g., `-10`) to your top-ranked cores (which are already pushed to their voltage limits from the factory).

---

## 5. Fan Control Tab

This tab interfaces with your motherboard's SuperIO controller (e.g., ITE IT8686E) to manage case and CPU fans.

### 5.1 Fan Monitoring & Hiding
- **Fan List**: Shows all detected fans, their RPM, and PWM Throttle percentage.
- **Hide Fan (Eye Slash Icon)**: If your motherboard reports ghost fans or headers like `H_AMP` show erratic values (e.g., `40 RPM` when disconnected), click the eye slash icon to permanently hide it from the UI and Menu Bar.
- **Show All (X hidden)**: Restores any hidden fans.

### 5.2 Quick Presets
- **All Auto (Arrow Circle Icon)**: Returns control of all fans back to the motherboard's BIOS logic.
- **Max Speed (Wind Icon)**: Instantly forces 100% PWM duty cycle on all connected fans (Take Off mode).

### 5.3 Closed-Loop Custom Fan Curves & Protection
Toggle **"Dynamic Next-Gen Fan Curves"** to override the BIOS and manage fans entirely via the macOS kernel.
- **Interactive Editor**: Drag the points on the graph to define your custom temperature-to-PWM curve.
- **256-Step LUT Interpolation**: The software translates your curve into a smooth 256-step Look-Up Table.
- **Smooth Ramping (Hysteresis)**: The kernel evaluates the curve with hysteresis to prevent fans from aggressively ramping up and down during sudden, momentary CPU temperature spikes.

### 5.4 GPU Fan Control (Zero RPM / SPPT)
As stated in the UI, direct software-based GPU fan speed overrides (like drawing curves for your Radeon RX 6800 XT) are **not supported** by the macOS kernel for AMD GPUs.
- **The Solution**: You must extract your vBIOS, use **MorePowerTool (MPT)** on Windows to modify the acoustic limits and Zero RPM toggles, and inject the resulting Soft PowerPlay Table (SPPT) string into OpenCore's `config.plist` under `DeviceProperties`. The UI provides direct links to the SPPT Guide and MPT downloads.

---

## 6. Menu Bar Extra & Preferences

The Menu Bar Extra provides a highly customizable, compact view of your system's vitals directly in the macOS menu bar.

### 6.1 Display Configuration
Click the AMD Power Gadget icon -> **Preferences**:
- **Include CPU/GPU/Fans**: Toggle specific widgets on or off.
- **Peak Tracking**: The Menu Bar dropdown automatically logs the **Peak** and **Minimum** values for all your selected metrics during the current session.

### 6.2 Application Settings
- **Update Interval**: Adjust how frequently the sensors are polled. 1-second intervals provide real-time accuracy; higher intervals save CPU cycles.
- **Theme**: Force Dark Mode, Light Mode, or respect System settings (utilizes Liquid Glass vibrancy).

---

## 7. Driver Dump Utility (Advanced)

If your fans are reading incorrect RPMs, it usually means the 16-bit tachometer registers or the internal clock divisors are misaligned for your specific SuperIO chip revision.
Run `Tools/IT8686E_Dump.sh` as `sudo` to output the raw Hex values of the Environment Controller (EC) registers. Use this to verify if the raw byte from the `FAN_RPM_REGS` needs a multiplier adjustment in the kext source code.
