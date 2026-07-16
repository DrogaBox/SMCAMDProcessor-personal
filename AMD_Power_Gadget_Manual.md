<div class="cover-page">
    <span class="cover-title">AMD Power Gadget</span>
    <span class="cover-subtitle">User Manual & Comprehensive Feature Guide</span>
    <br><br>
    <span style="color: var(--accent-cyan);">Version 3.31.0 (Tahoe Edition)</span>
</div>

## Introduction

Welcome to **AMD Power Gadget** and **SMCAMDProcessor**. This suite provides comprehensive telemetry and power management for AMD Ryzen processors on macOS (Hackintosh).

This manual explains the options available in the application. For deep technical detail (UserClient privilege matrix, architecture, Crowdin), see the **[docs/](docs/README.md)** folder.

---

## 1. System Requirements & OpenCore Setup

### 1.1 Essential Kexts
Ensure the following kexts are present in `EFI/OC/Kexts` and injected under `Kernel → Add`, in this **exact order**:
1. `Lilu.kext` (Must be first)
2. `VirtualSMC.kext` (SMC emulator — do **not** use FakeSMC)
3. `AMDRyzenCPUPowerManagement.kext` (CPU data, SuperIO, UserClient)
4. `SMCAMDProcessor.kext` (Exports data to VirtualSMC for iStat Menus, etc.)

### 1.2 OpenCore Quirks & Boot Arguments
- **ProvideCurrentCpuInfo** (Kernel → Quirks): `True`. Required for AMD core topology.
- **agdpmod=pikera** (boot-args): Radeon RX 6000 (Navi) black-screen workaround (GPU, not this project).

### 1.3 SMCAMDProcessor Custom Boot Arguments

Add under OpenCore **NVRAM → Add → `7C436110-AB2A-4BBB-A880-FE41995C9F82` → boot-args**. Also list `boot-args` under **NVRAM → Delete** for the same GUID so values refresh each boot.

| Argument | Purpose |
|----------|---------|
| **`-amdpnopchk`** | Disables UserClient **write** privilege checks. Menu bar app (non-root) can change fans, EPP, P-States, Curve Optimizer, SuperIO. **Recommended on trusted personal machines** for full GUI control. |
| **`-amdcppcactive`** | Enables CPPC Active Mode at boot so EPP profiles work with the SMU/OS. |
| **`-amdpdbg`** | Verbose kext debug logging (troubleshooting only). |

**Privilege model (v3.16.1+):**
- **Any user** can open the driver connection and **read** telemetry.
- **Writes** require **root** or **`-amdpnopchk`**.
- Without the flag, monitoring works; controls fail and the app shows an orange **privilege banner**.

Full docs: [docs/BOOT_ARGS.md](docs/BOOT_ARGS.md) · [docs/PRIVILEGE_AND_SECURITY.md](docs/PRIVILEGE_AND_SECURITY.md)

> [!WARNING]
> `-amdpnopchk` is a security tradeoff: any local process that opens the UserClient can issue privileged hardware writes. Use only on trusted personal systems.

### 1.4 Install the application
Copy `AMD Power Gadget.app` to `/Applications`. Clear quarantine if Gatekeeper blocks it (`xattr -cr "/Applications/AMD Power Gadget.app"`). On first launch, accept the **safety disclaimer**.

---

## 2. Privilege Banner

If you try Fan Control, EPP, Curve Optimizer, or other writes without root and without `-amdpnopchk`, an orange banner appears:

> This action requires administrator privileges. Run AMD Power Gadget as root, or add the boot argument `-amdpnopchk` for debugging.

**Fix:** add `-amdpnopchk` to OpenCore boot-args and reboot (preferred for a personal Hackintosh), or run the app as root (impractical for a menu bar extra).

---

## 3. Dashboard Tab (Power & Frequencies)

Real-time CPU metrics, charts, and core grid.

### 3.1 Core Metrics & Silicon Quality
- **Core Frequencies**: Real-time clock of each physical/logical core.
- **Silicon Quality Ranking (1. ~ X.)**: Zen 3/4 CPPC quality tags; core `1.` is the best core for Curve Optimizer strategy.
- **Package Power (PPT)**: Package wattage.
- **Tctl / Tdie**: Junction temperatures.
- **HUD toggles**: Show/hide per-core frequency, load, and CCD temp on the grid.

### 3.2 Charts
Frequency, temperature, power, and network charts with average / max / min metadata. Update interval is configurable in preferences.

**v3.31.0+ — Right-click menu:** Each chart has a native context menu (Size, Hide, Show, Move Position) that no longer flickers on telemetry updates. The Size submenu is disabled for the Core Grid chart (fixed-size layout).

**v3.31.0+ — CPU Profile Badge:** Below the stat cards, a compact badge shows the active CPU profile (e.g. "Telemetry-only — Zen 3 Vermeer") with capability chips (e.g. "CPPC", "PM Dispatch", "Legacy P-States").

---

## 4. Profiles Tab (CPU Speed Management)

### 4.1 EPP Profiles (Hardware Autonomous)
Energy Performance Preference via CPPC. Hint the SMU; hardware scales on load.
- **Power Saver** — lower boost priority / acoustics / battery.
- **Balanced** — default.
- **Performance** — higher responsiveness / single-thread boost priority.

Requires CPPC path; prefer **`-amdcppcactive`** at boot. Optional auto-EPP by load and AC/battery switching when available.

### 4.2 CPU Speed Profiles (Legacy / Manual P-State)
- **Manual P-State Override**: Lock to a step (e.g. P0 max, P2 base). No dynamic scaling.
- **Directly Edit Raw P-State Registers**: Hex FID/VID/DID. **Privileged.** Incorrect VID can shut down or damage silicon.

---

## 5. Advanced CPU Tuning: Curve Optimizer

- Per-core offsets **[-30, +30]** (physical cores).
- Negative offset undervolts for a given frequency (often higher sustained boost if stable).
- Strategy: larger negative offsets on lower-ranked cores; conservative on top cores.
- UI locked behind a **safety switch**; optional HUD (freq / load / CCD).
- Requires privilege (root or `-amdpnopchk`) and SMU support (typically Zen 3+).

> [!CAUTION]
> Aggressive Curve Optimizer settings can cause panics, reboots, or hardware stress. You assume all risk.

---

## 6. Fan Control Tab

Interfaces with motherboard SuperIO (Nuvoton NCT668X/NCT67XX, ITE IT86XXE, including NCT6799D / NCT6701D / IT8686E / IT8689E, etc.).

### 6.1 Fan Monitoring & Hiding
- List: RPM and PWM %.
- **Hide Fan**: Ghost headers / erratic channels.
- **Show All (X hidden)**: Restore hidden fans.
- Custom labels (e.g. rename `AUX_3` → `Pump`).

### 6.2 Quick Presets
- **All Auto**: BIOS control.
- **Max Speed**: 100% PWM on controlled fans.

### 6.3 Dynamic Next-Gen Fan Curves
Toggle to evaluate curves **in the kernel**:
- Interactive graph (drag points; double-click add/delete).
- 256-step LUT, EMA, hysteresis, ramp rate.
- Thermal floor: at **85 °C**, PWM forced to at least **80 %** (after hysteresis/ramp).
- Temp source: CPU or **GPU** (app injects GPU °C; values clamped 0–120 °C).
- Map each fan to a curve or BIOS Auto.

### 6.4 GPU Fan Control (Zero RPM / SPPT)
macOS does **not** allow direct AMD GPU fan PWM override. Use **MorePowerTool** + Soft PowerPlay Table (SPPT) in OpenCore `DeviceProperties`. The UI links to SPPT/MPT guides.

---

## 7. Themes & Appearance (including Language)

### 7.1 Language
- **System Default** — follow macOS preferred languages.
- **Specific language** — force a bundled locale (`English`, `Español`, `Deutsch`, `Italiano`, …).
- Preference is stored and applied at launch (`AppleLanguages`).
- After changing language, confirm **Apply & Restart**. The UI does **not** hot-reload all strings.

See [docs/I18N_CROWDIN.md](docs/I18N_CROWDIN.md).

### 7.2 Visual themes
Dark / Light / System, custom theme JSON where available, chart style options, Liquid Glass materials on supported macOS versions.

---

## 8. Telemetry, Analysis & Advanced

### 8.1 Telemetry
Configurable history charts, continuous logging, CSV export. Optional background daemon `amdtelemetryd` continues JSONL history when the GUI is closed (skips if the app is open).

### 8.2 Analysis
Session max/min for load, temps, memory, power, clocks over the selected timeframe.

### 8.3 Advanced
CPB / PPM / LPM toggles, alert thresholds, raw diagnostics. Privileged writes need root or `-amdpnopchk`.

### 8.4 Menu Bar / Popover / Desktop Widgets
Toggle which sensors appear in the menu bar extra; peak/min tracking for the session; update interval.

---

## 9. Menu Bar Extra & Preferences

Click the AMD Power Gadget icon:
- **Include CPU/GPU/Fans** widgets.
- **Peak Tracking** for selected metrics.
- **Update Interval**: 1 s for real-time; higher values save CPU.

---

## 10. System Info

CPU brand, board/chipset where available, cache topology, driver connection status.

**v3.31.0+ — CPU Profile:** Displays the active CPU profile name (e.g. "Zen 3 Vermeer"), operating mode ("Telemetry-only" vs "Full PM Dispatch"), and supported capabilities (CPPC, Legacy P-States, PM Dispatch). This data comes from the kext's per-family profile table via IOKit selector 26.

---

## 11. Safety Disclaimer

On first launch a modal blocks the main UI until you accept (`disclaimer_accepted`). Incorrect MSR/SMU/SuperIO settings can cause instability, data loss, panics, or hardware damage. **You use this software at your own risk.**

---

## 12. Troubleshooting (short)

| Problem | Action |
|---------|--------|
| “No AMDRyzenCPUPowerManagement Found!” | Check `kextstat`; OC order; update kext+app ≥ 3.16.1 |
| Orange privilege banner | Add `-amdpnopchk` or accept read-only |
| Language unchanged | Apply & Restart |
| Fan RPM wrong / 0 | Update kext; hide ghost fans; see docs |

Full guide: [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

---

## 13. Further documentation

| Doc | Content |
|-----|---------|
| [docs/README.md](docs/README.md) | Index of all docs |
| [docs/INSTALLATION.md](docs/INSTALLATION.md) | Install / verify / build |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Stack diagram |
| [CHANGELOG.md](CHANGELOG.md) | Release notes |
| [COMPARISON.md](COMPARISON.md) | vs original spinach project |

---

## 14. Driver Dump Utility (Advanced)

If fan RPM registers look wrong for your SuperIO revision, use SuperIO diagnostic sources under `scratch/` (`dump_sio`, `write_sio`) or board-specific dump scripts when provided. Prefer current release kexts before patching registers by hand.
