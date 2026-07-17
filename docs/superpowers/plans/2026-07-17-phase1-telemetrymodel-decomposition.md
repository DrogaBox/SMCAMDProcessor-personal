# Phase 1: TelemetryModel Decomposition — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split `TelemetryModel.swift` (2,888 lines → ~1,200 lines) into 7 focused files under `AMD Power Gadget/Telemetry/`.

**Architecture:** Pure extraction — cut code from the monolithic file, paste into new files, add imports, build after each extraction. No behavior change, no refactoring.

**Tech Stack:** Swift 6, SwiftUI, IOKit

## Global Constraints

- No logic changes — cut-and-paste only
- Build after EVERY extraction step (compile gate)
- Run full test suite after Phase 1 complete
- New files go into `AMD Power Gadget/Telemetry/` directory
- All new files are `internal` visibility (same module, no `public` needed)

---

### Task 1: Create Telemetry/ directory + TelemetryDataTypes.swift

**Files:**
- Create: `AMD Power Gadget/Telemetry/TelemetryDataTypes.swift`
- Modify: `AMD Power Gadget/TelemetryModel.swift` (remove ~170 lines of struct definitions)

- [ ] **Step 1: Create the directory**

```bash
mkdir -p "AMD Power Gadget/Telemetry"
```

- [ ] **Step 2: Create TelemetryDataTypes.swift** containing:

```swift
// TelemetryDataTypes.swift
// AMD Power Gadget

import Foundation

// MARK: - Data Structures

struct CoreSnapshot: Identifiable {
    let id: Int
    var freqMHz: Float
    var loadPct: Float
    var isLogical: Bool
    var cppcScore: UInt8? = nil
    var cppcScoreEstimated: Bool = false
    var coreRank: Int? = nil
}

struct RankedPhysicalCore: Identifiable {
    let id: Int
    let score: UInt8
    let rank: Int
    let isEstimated: Bool
    
    var rankText: String { "\(rank)." }
    var scoreText: String { (isEstimated ? "~" : "") + String(score) }
}

struct PStateRow: Identifiable {
    let id: Int
    var enabled: UInt32
    var iddDiv: UInt32
    var iddValue: UInt32
    var cpuVid: UInt32
    var cpuDfsId: UInt32
    var cpuFid: UInt32
    var isZen5: Bool = false

    var computedSpeedMHz: Float {
        if isZen5 {
            return Float(cpuFid) * 5.0
        } else {
            guard cpuDfsId > 0 else { return 0 }
            return Float(cpuFid) / Float(cpuDfsId) * 200.0
        }
    }

    var rawValue: UInt64 {
        var r: UInt64 = 0
        r |= UInt64(enabled)  << 63
        r |= (UInt64(iddDiv)   & 0x3)  << 30
        r |= (UInt64(iddValue) & 0xff) << 22
        r |= (UInt64(cpuVid)   & 0xff) << 14
        if isZen5 {
            r |= UInt64(cpuFid) & 0xfff
        } else {
            r |= (UInt64(cpuDfsId) & 0x1f) << 8
            r |=  UInt64(cpuFid)   & 0xff
        }
        return r
    }

    static func from(raw: UInt64, index: Int, cpuFamily: UInt64 = 0) -> PStateRow {
        let zen5 = cpuFamily >= 0x1A
        return PStateRow(
            id:       index,
            enabled:  UInt32(raw >> 63),
            iddDiv:   UInt32((raw >> 30) & 0x3),
            iddValue: UInt32((raw >> 22) & 0xff),
            cpuVid:   UInt32((raw >> 14) & 0xff),
            cpuDfsId: zen5 ? 1 : UInt32((raw >> 8) & 0x1f),
            cpuFid:   zen5 ? UInt32(raw & 0xfff) : UInt32(raw & 0xff),
            isZen5:   zen5
        )
    }
}

struct TelemetryPoint: Identifiable {
    let id: Int
    var time: Double
    var cpuFreqGHz: Double
    var cpuFreqMaxGHz: Double
    var instRetired: UInt64
    var gpuTempC: Double
    var cpuTempC: Double
    var cpuWatts: Double
    var gpuWatts: Double
    var netUploadMBps: Double
    var netDownloadMBps: Double
    var cpuLoad: Double
    var gpuLoad: Double
    var ramUsagePct: Double
    var diskUsagePct: Double
    var diskReadMBps: Double
    var diskWriteMBps: Double
    var fanRPM: Double
}

struct SystemInfo {
    var cpuBrand: String = ""
    var cpuFamily: String = ""
    var cpuModel: String = ""
    var physicalCores: Int = 0
    var logicalCores: Int = 0
    var l1KB: Int = 0
    var l2MB: Int = 0
    var l3MB: Int = 0
    var boardName: String = ""
    var boardVendor: String = ""
    var gpuModel: String = ""
    var ramGB: Int = 0
    var storageGB: Int = 0
    var macOSVersion: String = ""
    var kextVersion: String = ""
    var kextSupported: Bool = false
    var metalVersion: String = ""
    var vdaAcceleration: String = ""
}

struct ProcessInfoRow: Identifiable {
    let id: Int32
    var name: String
    var cpuUsage: Float
}
```

- [ ] **Step 3: Remove the corresponding structs from TelemetryModel.swift**

Remove lines 166-272 (from `// MARK: - Data Structures` through to just before `// MARK: - TelemetryModel`), keeping `ChartSizeConfig`.

- [ ] **Step 4: Build to verify**

```bash
xcodebuild -project SMCAMDProcessor.xcodeproj -scheme "AMD Power Gadget" -configuration Debug build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO 2>&1 | tail -5
```
Expected: BUILD SUCCEEDED (may need pbxproj update first)

---

### Task 2: Extract TelemetryPerformance.swift

**Files:**
- Create: `AMD Power Gadget/Telemetry/TelemetryPerformance.swift`
- Modify: `AMD Power Gadget/TelemetryModel.swift` (remove ~140 lines)

Contains: ThresholdPublished, ViewVisibilityModifier, CalculationCache, PerformanceMonitor, DiagnosticsHelper

---

### Task 3: Extract TelemetryStorage.swift

**Files:**
- Create: `AMD Power Gadget/Telemetry/TelemetryStorage.swift`
- Modify: `AMD Power Gadget/TelemetryModel.swift` (remove ~110 lines)

Contains: SimpleDeque, MetricHistory, ChartSizeConfig

---

### Task 4: Extract CSVLogger.swift

**Files:**
- Create: `AMD Power Gadget/Telemetry/CSVLogger.swift`
- Modify: `AMD Power Gadget/TelemetryModel.swift` (remove ~60 lines)

Contains: CSVLogger class

---

### Task 5: Extract CaffeinateManager.swift

**Files:**
- Create: `AMD Power Gadget/Telemetry/CaffeinateManager.swift`
- Modify: `AMD Power Gadget/TelemetryModel.swift` (remove ~50 lines)

Contains: CaffeinateManager class

---

### Task 6: Extract TelemetrySampling.swift

**Files:**
- Create: `AMD Power Gadget/Telemetry/TelemetrySampling.swift`
- Modify: `AMD Power Gadget/TelemetryModel.swift` (remove ~300 lines)

Contains: SamplingInputSnapshot, SamplingResult, captureSnapshot(), performBackgroundSample(), applySampleResult(), sample(), AlertEvaluationSnapshot, AlertEvaluationResult, evaluateAlerts()

**Special care:** These methods reference TelemetryModel properties. They are extracted as a `private extension TelemetryModel` in the new file.

---

### Task 7: Update Xcode project (pbxproj)

**Files:**
- Modify: `SMCAMDProcessor.xcodeproj/project.pbxproj`

Add all 6 new files to:
- PBXBuildFile section
- PBXFileReference section
- PBXGroup for AMD Power Gadget sources
- PBXSourcesBuildPhase

---

### Task 8: Full build + tests

```bash
xcodebuild -project SMCAMDProcessor.xcodeproj -scheme "AMD Power Gadget" -configuration Debug build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO 2>&1 | tail -10
xcodebuild test -project SMCAMDProcessor.xcodeproj -scheme "AMD Power Gadget" -sdk macosx -destination 'platform=OS X,arch=x86_64' -only-testing:AMDPowerGadgetTests 2>&1 | tail -5
```
