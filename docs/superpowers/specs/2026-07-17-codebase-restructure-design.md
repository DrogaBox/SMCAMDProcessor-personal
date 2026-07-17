# Codebase Restructure — Design Spec

> **Phase 1:** Decompose `TelemetryModel.swift` (2,888 lines) into focused modules.
> **Phase 2:** Decompose view files (MainDashboardView, DesktopWidgetExtensions, etc.).
> **Phase 3:** Organize kext C++ sources.

**Date:** 2026-07-17
**Status:** Design — pending implementation plan

---

## Architecture

The current codebase has three natural layers, and each will be restructured independently in order:

```
┌─────────────────────────────────────────────────────┐
│                  AMD Power Gadget App                │
│  ┌──────────┐  ┌──────────────┐  ┌────────────────┐ │
│  │ Models   │  │ Views        │  │ Utilities      │ │
│  │ (Phase1) │  │ (Phase2)     │  │ (small files)   │ │
│  └──────────┘  └──────────────┘  └────────────────┘ │
├─────────────────────────────────────────────────────┤
│              AMDRyzenCPUPowerManagement.kext          │
│           (Phase 3 — organization only)              │
├─────────────────────────────────────────────────────┤
│                  SMCAMDProcessor.kext                 │
│              (already well-structured)                │
└─────────────────────────────────────────────────────┘
```

### Guiding principles

1. **One responsibility per file.** If a file has multiple `// MARK:` sections that do different things, each section becomes its own file.
2. **Zero behavior change.** Extraction only — cut, paste, adjust imports/access control, compile. Never rewrite logic during a structural refactor.
3. **Compile after every extraction.** Each file split is followed by `xcodebuild` to confirm the change is safe.
4. **No new dependencies between modules.** The split must not create circular imports or force architectural changes.
5. **`Telemetry/` subdirectory.** All extracted Telemetry modules live under `AMD Power Gadget/Telemetry/`.

---

## Phase 1: TelemetryModel decomposition

### Current state

`TelemetryModel.swift` — 2,888 lines — contains:

| Section | Lines | Responsibility |
|---------|-------|----------------|
| ThresholdPublished | ~30 | Property wrapper for threshold-based UI updates |
| ViewVisibilityModifier | ~20 | SwiftUI view tracking |
| CalculationCache | ~30 | Generic TTL cache |
| PerformanceMonitor | ~40 | Internal perf diagnostics |
| DiagnosticsHelper | ~20 | System info logging |
| CoreSnapshot (struct) | ~15 | CPU core snapshot data |
| RankedPhysicalCore (struct) | ~15 | CPPC ranking data |
| PStateRow (struct) | ~60 | P-state definition row |
| TelemetryPoint (struct) | ~20 | Telemetry history point |
| SystemInfo (struct) | ~30 | System information |
| ChartSizeConfig (struct) | ~25 | Chart size persistence |
| ProcessInfoRow (struct) | ~5 | Process list row |
| **TelemetryModel (class)** | **~2,000** | Main telemetry engine |
| CSVLogger (class) | ~60 | CSV file logging |
| SimpleDeque (struct) | ~45 | Ring buffer |
| MetricHistory (struct) | ~40 | Rolling metric history |
| CaffeinateManager (class) | ~50 | System sleep management |

### Target structure

```
AMD Power Gadget/
├── Telemetry/
│   ├── TelemetryDataTypes.swift
│   │   ├── CoreSnapshot
│   │   ├── RankedPhysicalCore
│   │   ├── PStateRow
│   │   ├── TelemetryPoint
│   │   ├── SystemInfo
│   │   └── ProcessInfoRow
│   ├── TelemetryPerformance.swift
│   │   ├── ThresholdPublished
│   │   ├── ViewVisibilityModifier
│   │   ├── CalculationCache
│   │   ├── PerformanceMonitor
│   │   └── DiagnosticsHelper
│   ├── TelemetrySampling.swift
│   │   ├── MenuSamplingConfig (private)
│   │   ├── SamplingInputSnapshot (private)
│   │   ├── SamplingResult (private)
│   │   ├── AlertEvaluationSnapshot (private)
│   │   ├── AlertEvaluationResult (private)
│   │   └── captureSnapshot(), performBackgroundSample(), 
│   │       applySampleResult(), sample(), evaluateAlerts()
│   ├── TelemetryStorage.swift
│   │   ├── SimpleDeque
│   │   ├── MetricHistory
│   │   └── ChartSizeConfig
│   ├── CSVLogger.swift
│   │   └── CSVLogger (class)
│   └── CaffeinateManager.swift
│       └── CaffeinateManager (class)
├── TelemetryModel.swift
│   └── Remaining: ~1,000 lines
│       ├── @Published properties
│       ├── init(), restartTimer()
│       ├── processSampleData()
│       ├── buildCoreSnapshots()
│       ├── Fan curve management
│       ├── EPP / auto-fan / CPU control methods
│       └── Network / disk / RAM / battery helpers
```

### Extraction order (safe — compile after each)

| Step | Extract to file | Lines removed from TelemetryModel |
|------|----------------|-----------------------------------|
| 1 | `TelemetryDataTypes.swift` | ~170 (structs only) |
| 2 | `TelemetryPerformance.swift` | ~140 (property wrappers + utilities) |
| 3 | `TelemetryStorage.swift` | ~110 (SimpleDeque, MetricHistory, ChartSizeConfig) |
| 4 | `CSVLogger.swift` | ~60 |
| 5 | `CaffeinateManager.swift` | ~50 |
| 6 | `TelemetrySampling.swift` | ~280 (captureSnapshot, performBackgroundSample, etc.) |
| 7 | Update pbxproj | — (add all new files to Xcode project) |

After all 7 steps: `TelemetryModel.swift` goes from 2,888 → ~1,200 lines.

### TelemetrySampling.swift — special care

The sampling pipeline (`captureSnapshot()`, `performBackgroundSample()`, `applySampleResult()`, `sample()`, `evaluateAlerts()`) uses private types (`SamplingInputSnapshot`, `SamplingResult`, `MenuSamplingConfig`, `AlertEvaluationSnapshot`, `AlertEvaluationResult`) that reference `TelemetryModel` properties.

**Design decision:** These types stay in `TelemetrySampling.swift` as `internal` structs. The methods are extracted as a `private extension TelemetryModel` in that file. This keeps the coupling explicit while reducing line count in the main file.

Alternative considered (rejected): Making the types nested inside `TelemetryModel` — that would put them back in the main file or require a separate file per type.

### What stays in TelemetryModel.swift

After all extractions, `TelemetryModel.swift` retains:
- All `@Published` properties (~80)
- `init()`, `buildSystemInfo()`, `initSMC()`, `restartTimer()`
- `processSampleData()` — the orchestrator
- `buildCoreSnapshots()` — core snapshot builder
- `updateInstRetired()` — instruction counter
- `updateDiskThroughput()`, `updateNetworkStats()`, `updateTopProcesses()`
- `updateMemoryPressure()`, `getBatteryStatus()`
- `updateCPUControls()`, `evaluateAutoEPP()`, `evaluatePowerSourceSwitching()`
- Fan curve methods (`updateKextCurves()`, `updateKextMappings()`, etc.)
- CSV logging orchestration
- `updateSwapPolling()`, `updateIPPolling()`, `updateUptimePolling()`
- `updateRankedPhysicalCores()`, `fetchCurveOptimizerOffsets()`, etc.

---

## Phase 2: View decomposition (outline)

After Phase 1 is complete and verified. Main targets:

| Current file | Lines | Target |
|-------------|-------|--------|
| `MainDashboardView.swift` | 1,636 | Extract reusable components to `Views/Dashboard/` |
| `DesktopWidgetExtensions.swift` | 1,266 | Extract widget types to `Views/Widgets/` |
| `ChartDetailViews.swift` | 1,101 | Extract chart components to `Views/Charts/` |
| `AdvancedViews.swift` | 1,050 | Extract settings sections to `Views/Settings/` |
| `PopoverViews.swift` | 1,028 | Extract popover sections to `Views/Popover/` |

**Approach:** Same as Phase 1 — extract one component at a time, compile after each.

---

## Phase 3: Kext organization (outline)

Minimal structural changes:

| File | Action |
|------|--------|
| `AMDRyzenCPUPowerManagement.cpp` | Group methods by function (init, telemetry, control, SMC) with clear `#pragma mark` sections |
| `AMDRyzenCPUPowerManagement.hpp` | Group property declarations by function |
| `pmAMDRyzen.c` / `.h` | Already well-structured — add `#pragma mark` sections |

No code extraction — only comment markers and reordering within existing files.

---

## Risk mitigation

| Risk | Mitigation |
|------|-----------|
| Xcode project file conflict | Update pbxproj only once at the end of each phase |
| Broken imports | After each extraction, full build before committing |
| Method visibility changes | Extracted methods are `internal` or `private extension TelemetryModel` — never `public` |
| Lost git history | `git mv` for rename-style moves where possible; commit after each successful build |
| Regression in behavior | Run full test suite after each phase |
