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

### Para usuarios de CPU AMD en macOS

AMD nunca tuvo soporte nativo de Apple. Mientras que los usuarios de Intel y Apple Silicon tienen power management, sensores de temperatura, y control de ventiladores integrados en el sistema operativo, los usuarios de AMD dependen completamente de kexts como este para que su sistema funcione correctamente. Sin este driver:

- **No hay telemetría de CPU**: No sabés temperatura, frecuencia, voltaje ni consumo de tu procesador.
- **No hay control de ventiladores**: Los fans quedan al 100% todo el tiempo o no responden a la temperatura real.
- **No hay power management eficiente**: El CPU se queda en frecuencias altas constantemente, aumentando el consumo y la temperatura.
- **No hay sensor VirtualSMC**: Apps como iStat Menus, TG Pro o HWMonitor no pueden leer ningún sensor de la placa.

Este software **reemplaza toda la capa de monitoreo y control** que Apple debería haber provisto para AMD. Sin él, un Ryzentosh es un sistema ciego, ruidoso e ineficiente.

### Por qué fue crítica la actualización de seguridad (v3.24.0)

El audit de seguridad reveló problemas reales que podían causar desde corrupción de memoria silenciosa hasta inestabilidad del sistema:

1. **Corrupción de memoria en el hot path** (C1): Una instrucción `lock incq` de 64 bits escribiendo sobre una variable de 32 bits podía corromper variable contigua. En condiciones de alta carga, esto causaba crashes impredecibles.

2. **SMU mailbox específico por familia** (C2/C3): Los registros del SMU (System Management Unit) cambian entre generaciones Zen. El código original usaba direcciones hardcodeadas para Zen 3. Si alguien ejecutaba Curve Optimizer en un Zen 4 o Zen 5, podía escribir en registros incorrectos y —en el peor caso— requerir un CMOS clear para recuperar el sistema.

3. **MSR blocklist incompleto** (M4): Faltaban MSRs Intel que causan `#GP` (General Protection Fault) en AMD. Una app maliciosa o incluso una llamada accidental podía generar un kernel panic instantáneo.

4. **Timeout de SMU insuficiente** (H2): El timeout de 2ms para comandos Curve Optimizer es demasiado corto. El SMU necesita 5-15ms para reconfigurar el PLL. Esto causaba que el driver reportara timeout aunque el comando se estuviera ejecutando correctamente, dejando el SMU en estado inconsistente.

5. **Referencia de KASLR frágil** (M5): Usar `printf` como símbolo de referencia para calcular el KASLR slide es peligroso porque Apple puede eliminar ese símbolo del kernel en cualquier actualización. Cambiarlo a `_version` garantiza que el kext siga funcionando en futuras versiones de macOS.

6. **Temperatura de Zen 5 sin verificar** (H3): El flag de offset de temperatura (49°C) no estaba verificado para Zen 5. Aplicarlo ciegamente podía mostrar temperaturas completamente erróneas, causando que el thermal throttle o el control de ventiladores actuaran incorrectamente.

7. **Atomicidad** (M1, M9): Operaciones no atómicas en contadores compartidos (`hpcpus`, `kextloadAlerts`) son una bomba de tiempo en sistemas multi-thread. Funcionaban por casualidad, no por diseño.

### El compromiso con la calidad

Este fork personal no es solo un "update más". Cada línea de código kernel corre en el espacio más privilegiado del sistema operativo — **ring 0 del CPU**. Un bug acá no crashea una app, crashea todo el sistema. Por eso:

- Se auditaron **159 archivos** línea por línea.
- Se identificaron **34 hallazgos** de severidad Critical a Low.
- Se corrigieron **4 hallazgos Critical** y **7 High** antes del release.
- Se documentó cada fix con su justificación técnica.

Usar software de gestión de CPU sin estas correcciones es como manejar un auto sin frenos: funciona hasta que deja de funcionar.

---

## Safety Disclaimer & Liability

> [!CAUTION]
> **WARNING & DISCLAIMER OF LIABILITY:**
> This software interacts directly with low-level CPU hardware registers, Model-Specific Registers (MSRs), and the System Management Unit (SMU) to control CPU voltages, frequencies, and power limits. Incorrect settings can cause system instability, data loss, kernel panics, or permanent hardware damage.
>
> By using this software, you agree that **absolute responsibility rests entirely with the user**. The authors and contributors assume no liability whatsoever for any damage, loss, or side effects to your hardware, software, or personal property—regardless of whether it results in a crashed computer, data corruption, the end of the world, or an alien invasion. Use at your own risk.
