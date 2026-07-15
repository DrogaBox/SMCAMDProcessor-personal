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
- **v3.24.0 Security Audit Hardening:**
  - Per-Family SMU Mailbox Descriptor: Safe register addressing for Zen 3/4/5; Curve Optimizer writes blocked on Zen 4/5 until AGESA validation
  - Expanded Intel MSR Blocklist: Added 0xE2, 0x1AD, 0x345, 0x610–0x617 to prevent #GP faults on AMD
  - Atomic Instruction Fixes: Corrected `lock incq/decq` → `lock incl/decl` on 32-bit vars; `kextloadAlerts++` → `OSIncrementAtomic`
  - KASLR Symbol Stabilization: Migrated from fragile `printf` reference to stable `&version` symbol
  - SMN Per-Family Register Selection: Family-aware PCI control register offsets for future Zen generation compatibility
  - MWAIT Idle Path Interrupt Fix: Prevented latent scheduler hangs with missing `sti` after MWAIT exit
  - Zen 5 Temperature Offset Safety: Disabled unverified 49°C compensation on Zen 5 until PPR validation
- Privilege model (v3.16.1+): any process may open the UserClient for **read** telemetry; **writes** require root or `-amdpnopchk`. Process name is logged for audit only and is never used for authorization.

### 2. Micro-Architecture & Memory Optimization
- 64-Byte Cache Line Alignment: Applied `alignas(64)` alignment to core data structures (`pmProcessor_t`), isolating per-thread state to L1 cache lines and eliminating false sharing across all 32 logical threads of high-end desktop (HEDT) processors.
- Kernel RAM Footprint Reduction: Reduced per-core memory footprint from 8288 bytes down to 128 bytes, lowering total driver RAM allocation from 265KB to just 4KB on 32-thread architectures.
- XNU_MAX_CPU Perimeter Protection: Built-in perimeter boundary guards across processor indexing loops to prevent out-of-bounds array access on multi-core Ryzen 9 and Threadripper systems.
- Sleep/Wake Race Condition Prevention: `serviceInitialized` guardrails across timer callbacks combined with automatic TSC base re-synchronization upon sleep and wake transitions.

### 3. Precision RAPL Energy & Sensor Telemetry (SMCAMDProcessor.kext)
- Dynamic RAPL Power Scaling: Hardware MSR decoding (`0xC0010299`) with `1ULL << energyStatusUnits` exponent math for accurate package wattage calculations across Zen 3 and Zen 5.
- Granular per-CCD Thermal Monitoring: Direct PCI die register queries exposing individual CCD temperatures (VirtualSMC `TCxC` / `TCxc` keys) with automatic package fallback for multi-die CPUs.
- Expanded Super I/O Fan Support: Native RPM monitoring and hardware PWM fan curve controls for Nuvoton NCT668X/NCT67XX family (including NCT6799D and NCT6701D) and ITE IT86XXE family (including IT8628E, IT8686E, and IT8689E) controllers.

### 4. High-Performance Dashboard & Menu Bar Extra (AMD Power Gadget.app)
- MainActor Serial I/O Offloading: Hardware sampling operations are decoupled off the main thread onto a high-priority serial queue (`ioQueue`) with skip-if-busy guards, guaranteeing smooth 60 FPS UI rendering under max load.
- Diff-Based Rendering Engine: Smart threshold tracking skips redundant menu bar extra redraws (`setNeedsDisplay`) when sensor metrics fluctuate within idle tolerances.
- In-Process Zero-Allocation Network Analytics: Direct CChar ASCII buffer parsing using `sysctl(NET_RT_IFLIST2)` eliminates heap allocations, backed by an adaptive low-frequency background sampling mode.
- macOS 26 Tahoe UI Aesthetics: Designed with native Liquid Glass material vibrancy (`NSVisualEffectView`) and dynamic hierarchical SF Symbols 7+ fill glyphs (`cpu.fill`, `fan.fill`, `memorycard.fill`).
- Hardware-Autonomous CPPC & EPP Control: Native opt-in (`-amdcppcactive`) for CPPC Active Mode, delegating microsecond clock scaling to the internal System Management Unit (SMU) with configurable EPP profiles (Performance, Balanced, Power Save).
- In-App Language Picker: **Themes & Appearance → Language** forces any bundled locale (`en`, `es`, `de`, `it`, …) or System Default; applied at launch via `AppleLanguages` with Apply & Restart.
- Privilege UX Banner: When a write is denied (`kIOReturnNotPrivileged`), the dashboard shows a clear orange banner instead of silent failure (root or `-amdpnopchk` required for controls).

### 5. UserClient privilege model (v3.16.1+ / current: 3.16.2)
- **Reads** (telemetry, fan RPM, temps): any process may open the UserClient — the menu bar app works without root.
- **Writes** (fans, EPP, P-States, Curve Optimizer, SuperIO, …): require **root** or the explicit boot-arg **`-amdpnopchk`**.
- Authorization is **not** based on process name (spoof-resistant). On denial, the dashboard shows a privilege banner (3.16.2). Details: [docs/PRIVILEGE_AND_SECURITY.md](docs/PRIVILEGE_AND_SECURITY.md).

---

## Full documentation

| Topic | Link |
|-------|------|
| **Docs index** | **[docs/README.md](docs/README.md)** |
| Installation | [docs/INSTALLATION.md](docs/INSTALLATION.md) · [ES](docs/INSTALLATION_ES.md) |
| Boot arguments | [docs/BOOT_ARGS.md](docs/BOOT_ARGS.md) · [ES](docs/BOOT_ARGS_ES.md) |
| Privilege & security | [docs/PRIVILEGE_AND_SECURITY.md](docs/PRIVILEGE_AND_SECURITY.md) · [ES](docs/PRIVILEGE_AND_SECURITY_ES.md) |
| Features | [docs/FEATURES.md](docs/FEATURES.md) · [ES](docs/FEATURES_ES.md) |
| Troubleshooting | [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) · [ES](docs/TROUBLESHOOTING_ES.md) |
| Architecture | [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) |
| i18n / Crowdin | [docs/I18N_CROWDIN.md](docs/I18N_CROWDIN.md) |
| User manual | [AMD_Power_Gadget_Manual.md](AMD_Power_Gadget_Manual.md) · [ES](AMD_Power_Gadget_Manual_ES.md) |
| Changelog | [CHANGELOG.md](CHANGELOG.md) |

---

## Architectural Evolution & Upgrades

This project represents a major evolutionary leap over the original `wtf.spinach.SMCAMDProcessor` implementation by spinach, addressing critical bottlenecks in hardware access latency, power efficiency, UI performance, and memory leak vulnerabilities.

For a detailed comparative breakdown of features, APIs, and low-level improvements, see:
👉 **[COMPARISON.md](COMPARISON.md)**

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
- Boot arguments (recommended for full app control on a personal machine):
  - **`-amdcppcactive`** — CPPC Active Mode / EPP profiles at boot.
  - **`-amdpnopchk`** — allow non-root UserClient **writes** (fans, EPP, CO, …). Without it, monitoring still works; controls need root or show the privilege banner.
  - **`-amdpdbg`** — verbose kext debug logging (troubleshooting only).

See [docs/BOOT_ARGS.md](docs/BOOT_ARGS.md) and [docs/INSTALLATION.md](docs/INSTALLATION.md) for NVRAM setup (`Add` + `Delete` for `boot-args`).

> [!WARNING]
> `-amdpnopchk` is a deliberate security tradeoff: any local process that can open the UserClient may issue privileged hardware writes. Use only on trusted personal systems.

### App install
Copy `AMD Power Gadget.app` to `/Applications`, clear quarantine if needed (`xattr -cr`), launch once and accept the safety disclaimer.  
Language: **Themes & Appearance → Language → Apply & Restart**.

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

---

## Why This Matters

### For AMD CPU users on macOS

AMD never had native Apple support. While Intel and Apple Silicon users have power management, temperature sensors, and fan control built into the operating system, AMD users rely entirely on kexts like this one for their system to function properly. Without this driver:

- **No CPU telemetry**: You cannot read temperature, frequency, voltage, or power draw from your processor.
- **No fan control**: Fans either run at 100% constantly or fail to respond to actual temperature.
- **No efficient power management**: The CPU stays at high frequencies at all times, increasing power draw and heat.
- **No VirtualSMC sensors**: Apps like iStat Menus, TG Pro, or HWMonitor cannot read any motherboard sensors.

This software **replaces the entire monitoring and control layer** that Apple should have provided for AMD. Without it, a Ryzentosh is a blind, loud, and inefficient system.

### Why the security update was critical (v3.24.0)

The security audit revealed real issues that could cause anything from silent memory corruption to system instability:

1. **Memory corruption on the hot path** (C1): A 64-bit `lock incq` instruction writing to a 32-bit variable could corrupt adjacent memory. Under heavy load, this caused unpredictable crashes.

2. **SMU mailbox per-family** (C2/C3): SMU (System Management Unit) register addresses change between Zen generations. The original code used hardcoded Zen 3 addresses. Running Curve Optimizer on Zen 4 or Zen 5 would write to wrong registers — worst case, requiring a CMOS clear to recover.

3. **Incomplete MSR blocklist** (M4): Intel-specific MSRs were missing from the blocklist, causing `#GP` (General Protection Fault) on AMD CPUs. A malicious or accidental write could trigger an instant kernel panic.

4. **Insufficient SMU timeout** (H2): The 2ms timeout for Curve Optimizer commands was too short. The SMU needs 5–15ms to reconfigure PLLs, causing the driver to report timeouts while the command was still executing — leaving the SMU in an inconsistent state.

5. **Fragile KASLR reference** (M5): Using `printf` as the reference symbol for KASLR slide computation is dangerous because Apple could remove that symbol from the kernel export set in any update. Switching to `_version` ensures the kext continues working on future macOS releases.

6. **Unverified Zen 5 temperature offset** (H3): The 49°C temperature offset flag was unverified for Zen 5. Applying it blindly could report completely wrong temperatures, causing thermal throttle or fan control to trigger at incorrect thresholds.

7. **Atomicity** (M1, M9): Non-atomic operations on shared counters (`hpcpus`, `kextloadAlerts`) were a time bomb in multi-threaded environments. They worked by chance, not by design.

### Commitment to quality

This personal fork is not just "another update". Every line of kernel code runs in the most privileged space of the operating system — **CPU ring 0**. A bug here does not crash an app, it crashes the entire system. That is why:

- **159 files** were audited line by line.
- **34 findings** were identified across Critical to Low severity.
- **4 Critical** and **7 High** findings were fixed before release.
- Every fix was documented with its technical rationale.

Running CPU management software without these fixes is like driving a car without brakes: it works until it does not.

---

## Safety Disclaimer & Liability

> [!CAUTION]
> **WARNING & DISCLAIMER OF LIABILITY:**
> This software interacts directly with low-level CPU hardware registers, Model-Specific Registers (MSRs), and the System Management Unit (SMU) to control CPU voltages, frequencies, and power limits. Incorrect settings can cause system instability, data loss, kernel panics, or permanent hardware damage.
>
> By using this software, you agree that **absolute responsibility rests entirely with the user**. The authors and contributors assume no liability whatsoever for any damage, loss, or side effects to your hardware, software, or personal property—regardless of whether it results in a crashed computer, data corruption, the end of the world, or an alien invasion. Use at your own risk.
