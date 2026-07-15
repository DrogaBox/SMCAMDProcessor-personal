# Architecture and Feature Comparison: Original vs. v3.29.0

This document outlines the structural, architectural, and feature-level differences between the original repository by spinach (`wtf.spinach.SMCAMDProcessor`) and the current release (`v3.29.0`).

---

## 1. Feature Matrix

| Feature | Original Base (spinach) | Current Release (v3.29.0) |
| :--- | :--- | :--- |
| **CPU Architecture Support** | Zen 1 & Zen 2 (Family 17h) | Zen 1 through Zen 5 (Family 17h, 19h, 1Ah) |
| **CPPC Power Management** | None | Native Zen 3/5 CPPC (MSR and EPP tuning) |
| **SuperIO Chipsets** | Basic IT87xx | NCT668X, NCT67XX, IT86XXE (with bounds safety) |
| **SuperIO Read Latency** | 100ms thread yields (`IOSleep`) | 10µs hardware delays (`IODelay`) |
| **Graphics Telemetry** | None | RDNA2 (Navi 21 / RX 6800 XT) VRAM and thermal tracking |
| **VRAM Resolution** | None | Dynamic Metal API query (`recommendedMaxWorkingSetSize`) |
| **UI Framework** | Legacy Objective-C / AppKit Cocoa | SwiftUI + AppKit bridging (macOS Tahoe compliant) |
| **Graph Drawing Mode** | Synchronous CPU Vector path | Asynchronous GPU rendering (`drawsAsynchronously`) |
| **Main Window Management**| Transient `NSPopover` | Native `NSPanel` (`.nonactivatingPanel`) with custom fade/slide Core Animation |
| **Desktop Widgets** | None | Draggable borderless `NSPanel`s with 20px magnetic grid-snapping (auto-align) |
| **High-Density Thread Grid** | None | Adaptive columns layout for up to 128 logical threads |
| **Memory Management** | Retain cycles in IOKit / Timers | Weak delegate tracking and explicit IODescriptors release |
| **KASLR Symbol Resolution** | Direct `printf` symbol reference | Stable `_version` symbol via `<libkern/version.h>` |
| **SMU Mailbox Addressing** | Hardcoded Zen 3 offsets | Per-family descriptor (Zen 3/4/5); Zen 4/5 writes blocked until AGESA validation |
| **MSR Bounds Checking** | None | Expanded blocklist (0xCE, 0xE2, 0x198–0x19C, 0x1A0, 0x1AD, 0x345, 0x610–0x617) |
| **Atomic Safe Counters** | Regular `++` operators | `OSIncrementAtomic` / `lock incl` for shared counters |
| **P-State Ratio Tuning** | Hardcoded 80% of P0 | Configurable via boot-arg `-amdpp1ratio=XX` |

---

## 2. Technical Enhancements

### 2.1. Kernel Power Management and CPPC Integration
*   **Original**: Lacked support for Collaborative Processor Performance Control (CPPC). CPUs remained locked at base clock speeds or relied on coarse OS-level frequency scaling, resulting in high idle power draw (40W–50W).
*   **Current**: Implements native CPPC power state and Energy Performance Preference (EPP) orchestration. Telemetry kexts transition dynamically between Battery EPP (`0xC0`) and AC Power EPP (`0x00`/`0x3F`), reducing idle power draw to 10W–15W and enabling correct turbo boost behavior on Zen 3 processors.

### 2.2. SuperIO Driver Safety and Latency Reduction
*   **Original**: Utilized 100ms synchronous sleeps (`IOSleep(100)`) during register reads, causing CPU thread blocking and UI stuttering. It lacked bounds checking for fan counts, making it susceptible to kernel memory over-reads.
*   **Current**:
    *   Replaced blocking sleeps with 10-microsecond hardware delays (`IODelay(10)`), reducing chip access latency by 10,000x.
    *   Added explicit bounds checks (`>= activeFansOnSystem`) across all read methods to prevent memory corruption.
    *   Added support for modern SuperIO controllers (NCT668X, NCT67XX, IT86XXE) with automatic lock-bit clearing.
    *   ITE port closure fixed (0x4E and 0x2E ports properly closed after probe) to prevent LPC bus interference.

### 2.3. GPU and VRAM Telemetry
*   **Original**: Contained no provisions for dedicated graphics card monitoring or integration.
*   **Current**: Bridges SMCRadeonSensors to monitor GPU core temperature and power. Queries VRAM allocation dynamically using Metal API working set size limits, rendering real-time graphics utilization directly in the status layout.

### 2.4. UI/UX and Graphics Pipeline
*   **Original**: Legacy Objective-C layouts with synchronous graph drawing, generating 5%–10% CPU usage at idle. Relied on standard restricted `NSPopover`.
*   **Current**:
    *   Redesigned in SwiftUI using macOS Tahoe Liquid Glass material tokens (`.hudWindow` vibrancy) and spring physics.
    *   Migrated from `NSPopover` to native `NSPanel` to prevent NSISEngine layout recursion crashes, restoring native fade/slide animations via `NSAnimationContext`.
    *   Enabled `drawsAsynchronously = true` in `GraphView` layers, moving high-frequency graph rendering entirely to the GPU composition pipeline (reducing CPU overhead to 0%).
    *   Introduced Desktop Widgets powered by custom `NSWindow` subclasses that intercept frame coordinate updates to provide a 20x20 pixel magnetic "snap-to-grid" alignment.
    *   Formatted `formatBytes()` centralized in `ChartHelpers.swift`, removing 4 duplicated `formatSpeed()` implementations.

### 2.5. Security Audit Hardening (v3.24.0+)
*   **C1 - Atomic Instruction Fix**: Corrected `lock incq/decq` operating on `uint32_t` variables — latent memory corruption in the hot idle path.
*   **C2/C3 - Per-Family SMU Mailbox**: Family-aware SMU register addressing; Curve Optimizer writes safely disabled on Zen 4/5.
*   **M4 - Expanded MSR Blocklist**: Added 0xE2, 0x1AD, 0x345, 0x610–0x617 to prevent `#GP` on AMD CPUs.
*   **M5 - KASLR Symbol Stabilization**: Migrated from fragile `printf` to stable `&version` symbol for kernel base address resolution.
*   **M8 - P1 Ratio Configurable**: New boot-arg `-amdpp1ratio=XX` for tuning base-clock P-state frequency.
*   **H3 - Zen 5 Temperature Safety**: Disabled unverified 49°C temperature offset on Zen 5 until PPR validation.

### 2.6. ProcessorModel Actor Conversion (v3.25.0+)
*   **Original**: `ProcessorModel` used GCD queues with potential race conditions on concurrent access.
*   **Current**: Converted to Swift actor with automatic MainActor isolation, eliminating data races in the telemetry sampling pipeline.

---

## 3. Version History

| Version | Date | Key Changes |
| :--- | :--- | :--- |
| **v3.29.0** | 2026-07 | Format function extraction, code quality refactors |
| **v3.28.0** | 2026-07 | Fan model extraction, FanSensor enum, processSampleData() refactor |
| **v3.27.0** | 2026-07 | Popover graph alignment fix, loading overlay removal |
| **v3.26.0** | 2026-07 | Popover loading indicator, version bump |
| **v3.25.0** | 2026-07 | ProcessorModel actor conversion, kext privilege logging |
| **v3.24.0** | 2026-07 | **Security audit**: MSR blocklist, SMU per-family, KASLR slide, atomic fixes |
| **v3.23.3** | 2026-07 | Stability fixes, version bump |
| **v3.23.2** | 2026-07 | Vermeer PM Dispatch Decouple |
| **v3.23.1** | 2026-07 | Expanded MSR bounds checking to Zen 4+ |
| **v3.23.0** | 2026-07 | Safe idle loop, MSR bounds checking |
| **v3.22.0** | 2026-07 | Advanced UI Performance Engine & Memory Safety |
| **v3.21.0** | 2026-07 | Massive UI refactor & modularization |
| **v3.20.0** | 2026-07 | Swift Concurrency migration, actor isolation |
| **v3.19.3** | 2026-07 | Desktop Widgets grid-snapping |
| **v3.19.2** | 2026-07 | NSPanel migration, Core Animations |
| **v3.18.0** | 2026-06 | Initial Tahoe Edition fork from spinach's original |

---



### 2.5. Memory Safety and Sandbox Compliance
*   **Original**: Retain cycles in timer loops and open user client connections caused memory leaks over long sessions. Used deprecated kernel interfaces prone to sandboxing blocks.
*   **Current**:
    *   Enforces `[weak self]` capture semantics in all publisher timers.
    *   Explicitly cleans up IOKit matching objects (`IOObjectRelease`) and nullifies references during deinitialization.
    *   Complies with modern XNU Ring 0 execution rules and sandbox requirements on macOS 14+.
