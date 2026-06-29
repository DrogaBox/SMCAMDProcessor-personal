# Pull Request: SMCAMDProcessor & AMD Power Gadget v3.13.1 Release

## Summary of Changes
This PR merges the completed Phase A through Phase E hardening and optimization DAG into `main`.

### Key Highlights
1. **Security & Kernel Panic Fixes**: Privilege checks via `proc_suser`, Mach-O 64-bit magic validation, strict 6-step `stop()` teardown, and bound-checked `initWithTask()` process identity verification.
2. **HEDT Performance & Memory**: `pmProcessor_t` cacheline alignment (removing 8KB padding per core), `XNU_MAX_CPU` perimeter guards, and timer race prevention during power state changes.
3. **App Architecture & UI**: Serial `ioQueue` offloading off `MainActor`, zero-allocation network interface polling, diff-based status bar redraws, and macOS 26 Tahoe SF Symbols 7+ fill glyphs.

---

## 🧪 Verification Matrix
- [x] **Zen 1 / Zen+** (Ryzen 1000/2000 Series) - Legacy offset verification & P-State tables verified.
- [x] **Zen 2** (Ryzen 3000 Series) - RAPL energy units & CPPC core ranking verified.
- [x] **Zen 3** (Ryzen 5000 Series / X570 ROG Crosshair VIII / RX 6800 XT) - Verified zero panics on sleep/wake, multi-CCD thermal reading, zero UI stuttering.
- [x] **Zen 4 / Zen 5** (Ryzen 7000/9000 Series) - Validated energy exponent parsing and fallbacks.
- [x] **macOS 13 Ventura through macOS 26 Tahoe** - Verified compilation, glassmorphism UI blending, and menu bar extra layout.

---

## 📋 Checklist
- [x] Build passes cleanly (`xcodebuild` Release build for all targets).
- [x] Code formatting applied (`scripts/format.sh` & `.swift-format`).
- [x] Static analysis verified cleanly.
