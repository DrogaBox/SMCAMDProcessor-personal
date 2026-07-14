# App Concurrency & i18n Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix 6 findings from the Swift app security audit (A-06, A-07, A-08, A-09, A-10, A-11, A-12) — thread safety, actor isolation, data races, and i18n hardcoded strings.

**Architecture:** The AMD Power Gadget app has two key classes: `TelemetryModel` (MainActor-isolated, handles all UI-bound state) and `ProcessorModel` (singleton mutable class, wraps IOKit calls). `HistoryManager` collects telemetry history. Several views have hardcoded strings that bypass the localisation system.

**Tech Stack:** Swift 6, SwiftUI, Combine, Foundation, IOKit user-space, XNU sysctl

## Global Constraints

- macOS 14 Sonoma through macOS 26 Tahoe (deployment target)
- Use Swift 6 language mode (`-swift-version 6`)
- All user-facing strings must go through `LocalizedStringKey` or `NSLocalizedString`
- Thread-safe access to shared state: prefer `actor` or `os_unfair_lock` over DispatchQueue barriers
- Build with Xcode 16+, `AMD Power Gadget` scheme

---

## File Structure

| File | Role |
|------|------|
| `AMD Power Gadget/ProcessorModel.swift` | IOKit wrapper singleton — migrate to actor (A-07) |
| `AMD Power Gadget/TelemetryModel.swift` | MainActor view model — weak self fix (A-06), context switch reduction (A-12) |
| `AMD Power Gadget/PopoverViews.swift` | Popover views — hardcoded Spanish strings (A-10) |
| `AMD Power Gadget/AppLanguage.swift` | Language helper |
| `AMD Power Gadget/SharedComponents.swift` | Shared UI components |
| `AMD Power Gadget/ChartComponents.swift` | Chart rendering helpers — withUnsafePointer usage (A-11) |
| `AMD Power Gadget/HistoryManager.swift` (embedded in `MainDashboardView.swift`) | History collection — data race (A-08) |
| `AMD Power Gadget/DesktopWidgetExtensions.swift` | Widget helpers |

---

### Task 1: Migrate ProcessorModel from class+DispatchQueue to actor (A-07)

**Files:**
- Modify: `AMD Power Gadget/ProcessorModel.swift` — entire file refactor

**Interfaces:**
- Consumes: `IOKit` C APIs (`IOServiceGetMatchingService`, `IOConnectCallMethod`, etc.) — these are thread-safe and can be called from any thread
- Produces: `actor ProcessorModel` with `nonisolated` IOKit raw-call helpers and `isolated` computed properties; `TelemetryModel` accesses it via `await`

**Problem:** `ProcessorModel` is a `class` singleton with `private let accessQueue = DispatchQueue(...)`. Only `getMetric(forced:)` and `getNumOfCore()` use `accessQueue.sync`. All other properties (`PStateDef`, `PStateDefClock`, `numberOfCores`, `loadIndex`, `cachedMetric`, etc.) are read/written from both `@MainActor` context and `ioQueue` background context without synchronization. This is a Swift 6 data race.

**Solution:** Convert `ProcessorModel` to an `actor`. All mutable state becomes actor-isolated. IOKit calls that produce scalar/non-object values can be `nonisolated` since the IOKit C API is thread-safe. Computed properties that compose multiple reads become async.

- [ ] **Step 1: Rename class to actor, remove DispatchQueue**

```swift
actor ProcessorModel {
    static let shared = ProcessorModel()
    // private let accessQueue = DispatchQueue(...) — REMOVED, actor-isolated now

    private var connect: io_connect_t = 0

    // All mutable state is actor-isolated by default
    private var cachedMetric: [Float] = []
    private var numberOfCores: Int = 0
    private var lastMLoad: Double = 0
    private var PStateDef: [UInt64] = []
    private var PStateCur: Int = 0
    private var instructionDelta: [UInt64] = []
    private var loadIndex: [Float] = []
    private var previousCpuLoadInfo: [processor_cpu_load_info] = []
    private var PStateDefClock: [Float] = []
    private var validPStateLength: Int = 0
    // ... rest of private state
```

- [ ] **Step 2: Make the IOKit raw-call helper `nonisolated`**

```swift
    /// IOKit method calls are thread-safe (the MIG subsystem serializes internally).
    nonisolated func kernelGetFloats(count: Int, selector: UInt32) -> [Float] {
        var scalarOut: UInt64 = 0
        var scalarOutCount: UInt32 = 1
        var output = [Float](repeating: 0, count: count)
        var outputSize = MemoryLayout<Float>.size * count

        let status = IOConnectCallMethod(connect, selector, nil, 0, nil, 0,
                                         &scalarOut, &scalarOutCount,
                                         &output, &outputSize)
        guard status == KERN_SUCCESS else {
            logKernelError(status)
            return []
        }
        let valid = min(count, outputSize / MemoryLayout<Float>.size)
        return Array(output.prefix(valid))
    }
```

Wait — `connect` is actor-isolated so it can't be accessed from `nonisolated`. We need to either:
   a) Make the raw `connect` value available (e.g., store it in a separate nonisolated cache), or
   b) Make all IOKit methods `isolated` (they'll need `await` from callers)

Option (b) is simpler and safer. All IOKit calls from `TelemetryModel` already go through `await` or `ioQueue.async`.

- [ ] **Step 3: Update `initDriver()` and `closeDriver()` to be actor methods**

```swift
    func initDriver() -> Bool {
        let serviceObject = IOServiceGetMatchingService(kIOMainPortDefault,
                                                        IOServiceMatching("AMDRyzenCPUPowerManagement"))
        if serviceObject == 0 {
            return false
        }
        let status = IOServiceOpen(serviceObject, mach_task_self_, 0, &connect)
        IOObjectRelease(serviceObject)
        if status != KERN_SUCCESS {
            NSLog("ProcessorModel: IOServiceOpen failed status=0x%08x", status)
            return false
        }
        return true
    }

    func closeDriver() {
        if connect != 0 {
            IOServiceClose(connect)
            connect = 0
        }
    }
```

- [ ] **Step 4: Update `loadMetric()`, `loadLoadIndex()` etc. — keep as actor methods (implicitly isolated)**

```swift
    private func loadMetric() {
        var scalerOut: UInt64 = 0
        var outputCount: UInt32 = 1
        let maxStrLength = 67
        var outputStr: [Float] = [Float](repeating: 0, count: maxStrLength)
        var outputStrCount: Int = MemoryLayout<Float>.size * maxStrLength
        let res = IOConnectCallMethod(connect, 4, nil, 0, nil, 0,
                                      &scalerOut, &outputCount,
                                      &outputStr, &outputStrCount)
        if res != KERN_SUCCESS {
            logKernelError(res)
            return
        }
        numberOfCores = Int(scalerOut)
        let endIdx = min(numberOfCores + 2, outputStr.count - 1)
        cachedMetric = outputStr.count > 0 && endIdx >= 0 ? Array(outputStr[0...endIdx]) : []
        if outputStr.count > 2 { PStateCur = Int(outputStr[2]) }
        lastMLoad = Date().timeIntervalSince1970
    }
```

- [ ] **Step 5: Make public methods `async` since callers must await**

```swift
    func getMetric(forced: Bool) -> [Float] {
        if forced || (Date().timeIntervalSince1970 - lastMLoad >= 1.0) {
            loadMetric()
        }
        return cachedMetric
    }

    func getNumOfCore() -> Int { numberOfCores }

    func getLoadIndex() -> [Float] {
        loadLoadIndex()
        return loadIndex
    }
```

These are automatically `async` because actor methods are async from the caller's perspective.

- [ ] **Step 6: Update all callers in `TelemetryModel.swift` to use `await`**

In `TelemetryModel.swift`, the `performBackgroundSample` function calls `ProcessorModel.shared`. Since this runs `nonisolated private func performBackgroundSample(...)`, it needs to get a reference to `ProcessorModel.shared` and await its methods:

```swift
nonisolated private func performBackgroundSample(snapshot: SamplingInputSnapshot) -> SamplingResult? {
    // Before: let pm = ProcessorModel.shared
    // After — but we can't await inside a sync closure.
    // Solution: pass a Task or collect data synchronously before entering background
}
```

Actually, since `performBackgroundSample` is `nonisolated` and called from `ioQueue.async`, we can't `await` inside it directly. The proper approach:

**Alternative approach — snapshot pattern**: Collect all the IOKit data in the `captureSnapshot()` method (which runs on `@MainActor`) and pass the plain values through the snapshot. This is already partially done in the existing code (`SamplingInputSnapshot`). The remaining IOKit calls in `performBackgroundSample` should be moved to the snapshot phase.

Let me design a cleaner boundary:

`captureSnapshot()` (runs on MainActor, awaiting ProcessorModel as needed) → `SamplingInputSnapshot` (plain data, no actor refs) → `performBackgroundSample(snapshot:)` (pure computation, no actor access) → `SamplingResult` (plain data) → `applySampleResult(_:)` (MainActor)

This pattern already exists — it just needs the remaining `ProcessorModel.shared` calls inside `performBackgroundSample` to be moved to the snapshot phase.

- [ ] **Step 7: Move IOKit calls from performBackgroundSample into captureSnapshot**

In `TelemetryModel.swift`, `performBackgroundSample` currently calls:
```swift
let pm = ProcessorModel.shared
let metric = pm.getMetric(forced: true)
let loadIndex = pm.getLoadIndex()
```

These should be computed in `captureSnapshot` and passed via `SamplingInputSnapshot`:

Add to `SamplingInputSnapshot`:
```swift
struct SamplingInputSnapshot {
    // ... existing fields ...
    let metric: [Float]
    let loadIndex: [Float]
}
```

Compute in `captureSnapshot`:
```swift
private func captureSnapshot() -> SamplingInputSnapshot {
    // ... existing config setup ...
    let metric = ProcessorModel.shared.getMetric(forced: true)
    let loadIndex = ProcessorModel.shared.getLoadIndex()

    return SamplingInputSnapshot(
        // ... existing fields ...
        metric: metric,
        loadIndex: loadIndex
    )
}
```

This requires `captureSnapshot` to be `async` since it calls actor methods:

```swift
private func captureSnapshot() async -> SamplingInputSnapshot {
```

And the callers become:
```swift
private func sample() {
    guard !isSampling else { return }
    isSampling = true

    Task { @MainActor [weak self] in
        guard let self = self else { return }
        if !smcDriverLoaded { initSMC() }
        let snapshot = await self.captureSnapshot()

        ioQueue.async {
            guard let result = self.performBackgroundSample(snapshot: snapshot) else {
                self.isSampling = false
                return
            }
            self.applySampleResult(result)
        }
    }
}
```

- [ ] **Step 8: Commit**

```bash
git add AMD\ Power\ Gadget/ProcessorModel.swift AMD\ Power\ Gadget/TelemetryModel.swift
git commit -m "refactor(app): migrate ProcessorModel to actor (A-07)

Convert ProcessorModel from class+DispatchQueue to Swift actor.
All mutable state is now actor-isolated, eliminating data races
identified in audit A-07. IOKit calls remain thread-safe through
the MIG subsystem. Moved IOKit fetch calls into captureSnapshot
snapshot phase, keeping performBackgroundSample as pure computation.

Generated with Codebuff 🤖
Co-Authored-By: Codebuff <noreply@codebuff.com>
"
```

---

### Task 2: Fix weak self in Task { @MainActor } capture (A-06)

**Files:**
- Modify: `AMD Power Gadget/TelemetryModel.swift` — ~line 1535 and ~line 2205 (two locations)

**Interfaces:**
- Consumes: `TelemetryModel.fetchTopProcesses()` (static method) and `TelemetryModel.topProcesses` (published property)
- Produces: consistent `[weak self]` capture in all `Task { @MainActor }` blocks

**Problem:** In two places, `Task { @MainActor in self?.topProcesses = list }` uses `self` from the outer scope's weak capture, but the `Task` block doesn't explicitly capture `[weak self]`. This is functionally correct (the weak outer ref is captured by the closure), but inconsistent with the codebase's pattern and fragile if code is refactored.

- [ ] **Step 1: Find and fix location 1 (fetchTopProcesses)**

In `TelemetryModel.swift`:

```swift
// BEFORE:
ioQueue.async { [weak self] in
    let list = TelemetryModel.fetchTopProcesses()
    Task { @MainActor in
        self?.topProcesses = list
    }
}

// AFTER:
ioQueue.async { [weak self] in
    let list = TelemetryModel.fetchTopProcesses()
    Task { @MainActor [weak self] in
        self?.topProcesses = list
    }
}
```

- [ ] **Step 2: Find and fix location 2 (any other Task { @MainActor } without [weak self])**

Search for `Task { @MainActor` throughout `TelemetryModel.swift` and ensure every occurrence has `[weak self]`. There should be at least the one in `sample()`:

```swift
// In performBackgroundSample return path:
Task { @MainActor [weak self] in
    self?.isSampling = false
}
```

Verify this already has `[weak self]` — if not, add it.

- [ ] **Step 3: Build the app target to verify**

```bash
xcodebuild -target AMD\ Power\ Gadget -configuration Debug 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add AMD\ Power\ Gadget/TelemetryModel.swift
git commit -m "fix(app): explicit [weak self] in Task @MainActor captures (A-06)

Add explicit [weak self] capture lists to all Task { @MainActor } blocks
in TelemetryModel. Was relying on outer scope weak refs; explicit capture
is more robust against refactoring.

Generated with Codebuff 🤖
Co-Authored-By: Codebuff <noreply@codebuff.com>
"
```

---

### Task 3: Fix HistoryManager data race (A-08)

**Files:**
- Modify: `AMD Power Gadget/MainDashboardView.swift` — the `HistoryManager` class embedded inside the file (~line 2500-2700)

**Interfaces:**
- Consumes: `TelemetryModel.shared` (MainActor) for snapshot data via `sampleCurrentTelemetry()`
- Produces: `historyData` array accessed from both `sampleCurrentTelemetry()` (MainActor) and `downsampledData(for:)` (called from Analysis tab, which could be background)

**Problem:** `HistoryManager` is a plain `class` with `@Published var historyData: [HistoryDataPoint]`. `sampleCurrentTelemetry()` runs on `@MainActor` (`Task { @MainActor in ... }`), but `performDownsample(data:hours:)` is a static method called from `Task.detached(priority: .userInitiated)` in `AnalysisContentView`. While the static method gets a copy of the data via parameter, `downsampledData(for:)` accesses `self.historyData` without synchronization. Also `pruneOldData()` is called from both paths.

**Solution:** Annotate `HistoryManager` with `@MainActor` since all UI-bound observation of its `@Published` property happens on the main thread. The `performDownsample` static method receives a `[HistoryDataPoint]` parameter (value type, thread-safe by copy), so it's safe from background threads.

- [ ] **Step 1: Mark HistoryManager as @MainActor**

Add `@MainActor` to the class declaration:

```swift
@MainActor
class HistoryManager: ObservableObject {
```

- [ ] **Step 2: Remove the explicit MainActor.run in sampleCurrentTelemetry (now redundant)**

```swift
func sampleCurrentTelemetry() {
    // Was: Task { @MainActor in ... }
    // Now runs on MainActor directly since class is @MainActor
    let model = TelemetryModel.shared
    let point = HistoryDataPoint(
        timestamp: Date(),
        cpuLoad: model.cpuLoadAvg,
        cpuTemp: model.cpuTempC,
        ramUsage: model.ramUsagePct,
        gpuTemp: model.gpuTempC,
        gpuLoad: model.gpuLoadPct,
        cpuWatts: model.cpuWatts,
        cpuFreqAvg: model.cpuFreqAvgGHz
    )
    self.historyData.append(point)
    self.pruneOldData()
    self.saveData()
}
```

- [ ] **Step 3: Keep `performDownsample(data:hours:)` as `nonisolated static`**

It already receives data as a parameter copy, so it's safe:

```swift
nonisolated static func performDownsample(data: [HistoryDataPoint], hours: Int) -> [HistoryDataPoint] {
    // ... existing code, no self access ...
}
```

- [ ] **Step 4: Update callers of HistoryManager**

In `AppDelegate.swift` `applicationWillTerminate()`:
```swift
HistoryManager.shared.flushToDisk()  // Runs on MainActor — fine since AppDelegate is @MainActor
```

In `AppDelegate.swift` `applicationDidFinishLaunching()`:
```swift
_ = HistoryManager.shared  // Fine on MainActor
```

- [ ] **Step 5: Build the app target**

```bash
xcodebuild -target AMD\ Power\ Gadget -configuration Debug 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Commit**

```bash
git add AMD\ Power\ Gadget/MainDashboardView.swift AMD\ Power\ Gadget/AppDelegate.swift
git commit -m "fix(app): annotate HistoryManager as @MainActor (A-08)

HistoryManager's @Published var historyData is accessed from the main
thread for UI observation. Adding @MainActor eliminates data races
between sampleCurrentTelemetry() and pruneOldData(). The static
performDownsample method already receives data-by-copy and is safe.

Generated with Codebuff 🤖
Co-Authored-By: Codebuff <noreply@codebuff.com>
"
```

---

### Task 4: Add outputStrCount validation in ProcessorModel (A-09)

**Files:**
- Modify: `AMD Power Gadget/ProcessorModel.swift` — the `init()` method and `kernelGetString` method

**Interfaces:**
- Consumes: `IOConnectCallMethod` return values
- Produces: safe `String(cString:)` construction with guard

**Problem:** `String(cString: Array(outputStr[0...min(outputStrCount - 1, outputStr.count - 1)]))` will crash if `outputStrCount <= 0` because `0...(-1)` is an invalid range.

- [ ] **Step 1: Add validation guard**

In the `init()` method where `AMDRyzenCPUPowerManagementVersion` is read:

```swift
// Before:
AMDRyzenCPUPowerManagementVersion = outputStrCount > 0 ? String(cString: Array(outputStr[0...min(outputStrCount - 1, outputStr.count - 1)])) : ""

// Already safe — the ternary checks outputStrCount > 0 first.
```

Actually this is already safe — the ternary guards it. But the pattern in `kernelGetString` may not be. Let me check:

In `kernelGetString`:
```swift
if res != KERN_SUCCESS || outbuffersize <= 0 {
    return ""
}
var validBytes = Array(outputStr.prefix(outbuffersize))
if validBytes.isEmpty || validBytes.last != 0 {
    validBytes.append(0)
}
return String(cString: validBytes)
```

This is safe because `outbuffersize <= 0` returns `""` early, and `validBytes` will have at least 1 element (the appended 0).

The `init()` version in the current code is:
```swift
AMDRyzenCPUPowerManagementVersion = outputStrCount > 0 ? String(cString: Array(outputStr[0...min(outputStrCount - 1, outputStr.count - 1)])) : ""
```

This is already safe. The issue may have been in a previous version. The finding was a false positive on the current codebase. Mark as **not actionable**.

- [ ] **Step 2: Add a comment noting the safe pattern for future readers**

```swift
// Safe: outputStrCount > 0 guards invalid range. The kernel always
// returns a valid C string with null terminator for selector 8.
AMDRyzenCPUPowerManagementVersion = outputStrCount > 0 ? String(cString: Array(outputStr[0...min(outputStrCount - 1, outputStr.count - 1)])) : ""
```

- [ ] **Step 3: Commit**

```bash
git add AMD\ Power\ Gadget/ProcessorModel.swift
git commit -m "docs(app): add safety comment for String(cString:) pattern (A-09)

The existing nil-length check (outputStrCount > 0) already prevents
invalid range crashes. Added comment to clarify the guard for future
readers.

Generated with Codebuff 🤖
Co-Authored-By: Codebuff <noreply@codebuff.com>
"
```

---

### Task 5: Localize hardcoded Spanish strings in PopoverViews (A-10)

**Files:**
- Modify: `AMD Power Gadget/PopoverViews.swift` — `PopoverProfilesView` (~line 460-510)
- Modify: `AMD Power Gadget/en.lproj/Localizable.strings` — add English keys
- Modify: `AMD Power Gadget/es.lproj/Localizable.strings` — add Spanish translations
- Modify: (other locale `.lproj` files as discovered)

**Interfaces:**
- Consumes: `NSLocalizedString` / `LocalizedStringKey` pattern already established in the codebase
- Produces: `PopoverProfilesView` uses `LocalizedStringKey` for all user-facing strings

**Problem:** `PopoverProfilesView` has these hardcoded Spanish strings:
- `"Ahorro"`
- `"Eq. Ahorro"`
- `"Eq. Rend."`
- `"Rendimiento"`
- `"Controles Avanzados"`
- Section labels and descriptions in the Settings tab

- [ ] **Step 1: Replace hardcoded Spanish with LocalizedStringKey**

In `PopoverViews.swift`, `PopoverProfilesView`:

```swift
HStack {
    Text("Ahorro")
        .font(.system(size: 9))
        .foregroundColor(sliderValue.wrappedValue == 0 ? theme.text : theme.subtext)
    Spacer()
    Text("Eq. Ahorro")
    // ...
```

Replace ALL user-facing strings with `LocalizedStringKey`:

```swift
HStack {
    Text(LocalizedStringKey("Power Save"))
        .font(.system(size: 9))
        .foregroundColor(sliderValue.wrappedValue == 0 ? theme.text : theme.subtext)
    Spacer()
    Text(LocalizedStringKey("Balanced Power"))
    // ...
```

Full mapping:
| Hardcoded (Spanish) | LocalizedStringKey (English) |
|---|---|
| `"Ahorro"` | `"Power Save"` |
| `"Eq. Ahorro"` | `"Balanced Power"` |
| `"Eq. Rend."` | `"Balanced Perf"` |
| `"Rendimiento"` | `"Performance"` |
| `"Controles Avanzados"` | `"Advanced Controls"` |
| `"Perfiles"` (tab label) | Already `LocalizedStringKey("Perfiles")` |  

- [ ] **Step 2: Add English keys to `en.lproj/Localizable.strings`**

```strings
/* Popover EPP slider labels */
"Power Save" = "Power Save";
"Balanced Power" = "Balanced Power";
"Balanced Perf" = "Balanced Perf";
"Performance" = "Performance";
"Advanced Controls" = "Advanced Controls";
```

- [ ] **Step 3: Add Spanish translations to `es.lproj/Localizable.strings`**

```strings
/* Popover EPP slider labels */
"Power Save" = "Ahorro";
"Balanced Power" = "Eq. Ahorro";
"Balanced Perf" = "Eq. Rend.";
"Performance" = "Rendimiento";
"Advanced Controls" = "Controles Avanzados";
```

- [ ] **Step 4: Also fix the Settings tab in PopoverSettingsView**

Search `PopoverSettingsView` for hardcoded strings:

```swift
Text("ACTIVE MONITORS")
Text("SHORTCUT APPLICATION")
Text("POPOVER SETTINGS")
```

These headers should use `LocalizedStringKey`:

```swift
Text(LocalizedStringKey("Active Monitors"))
Text(LocalizedStringKey("Shortcut Application"))
```

And add to both locale files.

- [ ] **Step 5: Build the app target**

```bash
xcodebuild -target AMD\ Power\ Gadget -configuration Debug 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Commit**

```bash
git add AMD\ Power\ Gadget/PopoverViews.swift \
       AMD\ Power\ Gadget/en.lproj/Localizable.strings \
       AMD\ Power\ Gadget/es.lproj/Localizable.strings
git commit -m "fix(app): localize hardcoded Spanish strings in popover views (A-10)

Replace hardcoded Spanish EPP slider labels (Ahorro, Eq. Ahorro, etc.)
and Settings headers (ACTIVE MONITORS) with LocalizedStringKey. Add
English source strings and Spanish translations to respective .strings
files for Crowdin sync.

Generated with Codebuff 🤖
Co-Authored-By: Codebuff <noreply@codebuff.com>
"
```

---

### Task 6: Replace withUnsafePointer with Data(bytes:) in updateKextCurves (A-11)

**Files:**
- Modify: `AMD Power Gadget/TelemetryModel.swift` — `updateKextCurves()` method (~line 1850)

**Interfaces:**
- Consumes: `FanCurve` struct with `sourceSensor`, `hysteresis`, `rampRate`, `lut`
- Produces: `Data` blob sent to kext via `kernelSetStruct(selector:data:)`

**Problem:** The `updateKextCurves()` method uses `withUnsafePointer` + `UnsafeBufferPointer` to pack struct fields into Data. This is idiomatically fragile — if Swift's lifetime semantics change, the pointer may become invalid before the buffer copy completes.

- [ ] **Step 1: Replace the unsafe pointer pattern with `Data(bytes:count:)`**

Before:
```swift
withUnsafePointer(to: &curveIndex) { ptr in
    data.append(UnsafeBufferPointer(start: ptr, count: 1))
}
```

After:
```swift
withUnsafePointer(to: curveIndex) { ptr in
    data.append(UnsafeBufferPointer(start: ptr, count: 1))
}
// Or better, use the modern pattern:
var curveIndex = UInt32(idx)
data.append(Data(bytes: &curveIndex, count: MemoryLayout<UInt32>.size))
```

Full replacement for the method:

```swift
func updateKextCurves() {
    guard smcDriverLoaded else { return }
    for (idx, curve) in customCurves.enumerated() {
        guard idx < 4 else { break }
        var data = Data()

        var curveIndex = UInt32(idx)
        data.append(Data(bytes: &curveIndex, count: MemoryLayout<UInt32>.size))

        var sourceSensor = UInt32(curve.sourceSensor)
        data.append(Data(bytes: &sourceSensor, count: MemoryLayout<UInt32>.size))

        var hysteresis = UInt32(round(curve.hysteresis))
        data.append(Data(bytes: &hysteresis, count: MemoryLayout<UInt32>.size))

        var rampRate = UInt32(round(curve.rampRate))
        data.append(Data(bytes: &rampRate, count: MemoryLayout<UInt32>.size))

        let lut = curve.generateLUT()
        data.append(Data(lut))

        _ = noteKernelWriteStatus(ProcessorModel.shared.kernelSetStruct(selector: 101, data: data))
    }
}
```

- [ ] **Step 2: Build the app target**

```bash
xcodebuild -target AMD\ Power\ Gadget -configuration Debug 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add AMD\ Power\ Gadget/TelemetryModel.swift
git commit -m "refactor(app): replace withUnsafePointer with Data(bytes:) (A-11)

Replace idiomatically fragile withUnsafePointer+UnsafeBufferPointer
pattern in updateKextCurves() with the modern Data(bytes:count:)
initializer. Same behavior, clearer lifetime semantics.

Generated with Codebuff 🤖
Co-Authored-By: Codebuff <noreply@codebuff.com>
"
```

---

### Task 7: Reduce context switches in sample loop (A-12)

**Files:**
- Modify: `AMD Power Gadget/TelemetryModel.swift` — the `sample()` method (~line 1520-1550)

**Interfaces:**
- Consumes: `captureSnapshot()` (async, on MainActor), `performBackgroundSample(snapshot:)` (pure computation), `applySampleResult(_:)` (MainActor)
- Produces: streamlined sampling path: `captureSnapshot` → `performBackgroundSample` → `applySampleResult`, all within a single structured concurrency Task

**Problem:** The current sample path does 3 context switches: (1) Timer fires on main runloop, (2) main thread dispatches to ioQueue (DispatchQueue), (3) background queue dispatches back to MainActor via Task. With a 0.1s interval, this is significant overhead.

**Solution:** Use `async` sampling within a single `Task` on the main actor. The heavy IOKit calls are async (await) and don't block the main thread. Replace `ioQueue.async` with `Task.detached(priority: .utility)` and then `await MainActor.run`.

- [ ] **Step 1: Rewrite the `sample()` method to reduce context switches**

```swift
private func sample() {
    guard !isSampling else { return }
    isSampling = true

    if !smcDriverLoaded {
        initSMC()
    }

    // Collect the snapshot (MainActor + awaits ProcessorModel actor)
    let snapshot = captureSnapshot()

    // Offload computation to utility priority task
    Task.detached(priority: .utility) { [weak self] in
        guard let result = self?.performBackgroundSample(snapshot: snapshot) else {
            await MainActor.run { self?.isSampling = false }
            return
        }
        await MainActor.run { [weak self] in
            guard let self = self else { return }
            self.applySampleResult(result)
            self.isSampling = false
        }
    }
}
```

Wait — `captureSnapshot()` is not `async` currently. But with the ProcessorModel actor migration (Task 1), it needs to be `async`. So this becomes:

```swift
private func sample() {
    guard !isSampling else { return }
    isSampling = true

    // Start a structured concurrency Task on the MainActor
    Task { @MainActor [weak self] in
        guard let self = self else { return }

        if !self.smcDriverLoaded {
            self.initSMC()
        }

        let snapshot = await self.captureSnapshot()

        // Offload to utility thread via Task.detached
        Task.detached(priority: .utility) { [weak self] in
            guard let self = self else { return }
            let result = self.performBackgroundSample(snapshot: snapshot)
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.applySampleResult(result)
                self.isSampling = false
            }
        }
    }
}
```

This eliminates the `ioQueue` dependency entirely. The `captureSnapshot()` becomes `async` (to await the `ProcessorModel` actor):

```swift
private func captureSnapshot() async -> SamplingInputSnapshot {
    // ... existing config setup ...
    let metric = await ProcessorModel.shared.getMetric(forced: true)
    let loadIndex = await ProcessorModel.shared.getLoadIndex()
    // ... rest unchanged ...
}
```

- [ ] **Step 2: Remove the ioQueue usage and the isSampling guard modification**

The `ioQueue` property can be kept for other uses (like `fetchTopProcesses`), but the main sampling no longer needs it.

- [ ] **Step 3: Build the app target**

```bash
xcodebuild -target AMD\ Power\ Gadget -configuration Debug 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add AMD\ Power\ Gadget/TelemetryModel.swift
git commit -m "perf(app): reduce context switches in sample loop (A-12)

Replace ioQueue.async + Task { @MainActor } pattern with a single
structured-concurrency Task: captureSnapshot (async), then
Task.detached(utility) for background computation, then
MainActor.run for UI update. Reduces context switches from 3 to 2.

Generated with Codebuff 🤖
Co-Authored-By: Codebuff <noreply@codebuff.com>
"
```
