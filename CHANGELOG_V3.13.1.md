# CHANGELOG v3.13.1 (2026)

## Overview
Release v3.13.1 represents a comprehensive architectural hardening, memory optimization, and modern UI enhancement for the AMD Ryzen macOS telemetry stack (Zen 1 through Zen 5, HEDT Threadripper, and macOS 13 Ventura up to macOS 26 Tahoe).

---

## 🔒 Security & Panic-Class Fixes
- **UserClient Privilege Escalation Protection (A1 / U1)**: Replaced mock `hasPrivilege()` with authentic root check via `proc_suser` and `kauth_cred_getuid`.
- **String Table Bounds Check (A2 / R2)**: Enforced strict boundary limits on symbol string table parsing in `kernel_resolver.c`.
- **64-bit Mach-O Magic Validation (A3 / R3)**: Added explicit `MH_MAGIC_64` verification prior to resolving kernel functions.
- **IPC Lifecycle & Memory Teardown (A4 / K9 & A7 / K3)**: Implemented strict 6-step teardown sequence in `stop()`, retaining `fIOPCIDevice` and ensuring zero dangling pointers upon unloaded driver sessions.
- **Process Identity Verification & Hardening (D3 / U2)**: Integrated bound-checked executable binary validation in `initWithTask()` for `AMD Power Gadget` and `SMCAMDProcessor` binaries.

---

## ⚡ Performance & Kernel Memory Hardening
- **Cacheline Alignment & Footprint Reduction (B11 / R5)**: Optimized `pmProcessor_t` alignment to `alignas(64)`, eliminating legacy 8KB manual padding arrays and reducing RAM footprint from 265KB to 4KB for 32-thread systems.
- **XNU_MAX_CPU Perimeter Protection (B12 / R6)**: Added perimeter boundary checks avoiding out-of-bounds array access on high-core-count architectures.
- **Power State Race Condition Prevention (B13 / K15)**: Integrated `serviceInitialized` guardrails across timer callbacks and re-synchronized TSC base on sleep/wake transitions.
- **MainActor I/O Offloading (D1 / S1)**: Decoupled all `IOConnectCallMethod` kernel sampling operations off the main thread to a dedicated, high-priority serial queue (`ioQueue`) with skip-if-busy guards.
- **Network Telemetry Hardening (D2 / S2)**: Zeroed heap allocations during interface name parsing and added adaptive low-frequency sampling (5.0s interval when backgrounded).

---

## 🌐 VirtualSMC & Granular Sensor Telemetry
- **Interrupt-Safe PCI Serialization (A5 / K10)**: Switched indirect PCI config lock calls in `getPackageTemp()` and `getCCDTemp()` to workloop-safe simple locks.
- **Zen 3 / Zen 5 Energy & RAPL Scaling (B7 / K6)**: Integrated RAPL Power Unit MSR (`0xC0010299`) decoding with `1ULL << energyStatusUnits` exponent math.
- **Granular per-CCD Temperature Reporting (C2 / S20)**: Enabled individual CCD thermal monitoring in VirtualSMC `TempCore` keys with automatic package temperature fallback.

---

## 🎨 UI Modernization & macOS 26 Tahoe Support
- **Diff-Based Status Bar Rendering (E1 / S14)**: Added threshold-based snapshot tracking to eliminate redundant status bar redraws when metrics fluctuate insignificantly.
- **SF Symbols 7+ Tahoe Glyphs (E2 / S22)**: Modernized sensor icons across status bar widgets and popovers using hierarchical filled SF Symbols (`cpu.fill`, `fan.fill`, `memorycard.fill`).
