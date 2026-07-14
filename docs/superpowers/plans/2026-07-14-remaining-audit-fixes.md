# Remaining Audit Fixes — Instructions for Another Session

## A-07: Migrate ProcessorModel from class to actor

**Location:** `AMD Power Gadget/ProcessorModel.swift`

**Goal:** Convert `ProcessorModel` from `class` + `DispatchQueue` to a Swift `actor` to eliminate data races.

**Why it was deferred:** This is a large refactor (~40 public methods). Every caller needs `await`. If done wrong, the whole app stops compiling. Needs careful session with test coverage.

### Instructions:

1. **Change declaration:** Replace `class ProcessorModel {` with `actor ProcessorModel {`. Remove the `accessQueue` property — actor isolation replaces it.

2. **Make non-isolated helpers:** Wrap `IOConnectCallMethod` calls that receive scalar values in `nonisolated` helpers that take `connect` as a parameter (since `connect` is actor-isolated). Or simpler: make all public methods `async` — they'll auto-suspend when accessing actor state.

3. **Snapshot pattern:** The app already has a snapshot/result pattern in `TelemetryModel.swift`:
   ```swift
   captureSnapshot() → SamplingInputSnapshot → performBackgroundSample() → SamplingResult → applySampleResult()
   ```
   Move ALL `ProcessorModel.shared.xxx()` calls from `performBackgroundSample()` (which is `nonisolated`) into `captureSnapshot()` (which can `await` the actor). Currently only `getMetric()` and `getLoadIndex()` are in the snapshot — many more remain.

4. **Functions still in performBackgroundSample needing extraction:** 
   - `pm.getNumOfCore()`
   - `pm.getGPUTemp()` / `pm.getGPUPower()` / `pm.getGPUUtilization()` / `pm.getGPUVramUsed()` / `pm.getGPUFanRPM()` (GPU helpers)
   - `pm.getCCDTemperatures()` 
   - `pm.getInstructionDelta()`
   - `pm.kernelGetUInt64()` (fan RPMs and controls)

5. **Ambient calls in TelemetryModel:** `ProcessorModel.shared.xxx()` is called in many places beyond the sample loop — `setCPB()`, `setPPM()`, `setSpeedStep()`, `getPStateDef()`, etc. These will all need `await ProcessModel.shared.xxx()` since the methods become async.

6. **Test:** Run the full `AMDPowerGadgetTests` suite. Many tests call `ProcessorModel.shared.xxx()` and will need `await`.

**Risk:** MEDIUM. Compile errors in ~20-30 call sites. Each is a mechanical fix (add `await`), but missing one breaks the build.

---

## A-12: Context switch reduction in sample loop

**Location:** `AMD Power Gadget/TelemetryModel.swift` — the `sample()` method (~line 1520)

**Goal:** Replace `ioQueue.async { ... Task { @MainActor ... } }` with `Task.detached(priority: .utility) { ... await MainActor.run { ... } }` to reduce context switches from 3 to 2 per tick.

**Dependency:** ✅ Now independent — A-10 (i18n) is done. A-07 (actor) does NOT need to be done first for this change.

### Instructions:

1. **Current flow:**
   ```
   Timer → sample() (MainActor) → captureSnapshot() → ioQueue.async → performBackgroundSample() → Task { @MainActor } → applySampleResult()
   ```
   3 context switches: MainActor → ioQueue → MainActor (via Task)

2. **Target flow:**
   ```
   Timer → sample() (MainActor) → captureSnapshot() → Task.detached(utility) → performBackgroundSample() → await MainActor.run → applySampleResult()
   ```
   2 context switches: MainActor → utility → MainActor (via MainActor.run)

3. **Code change in `sample()`:**
   ```swift
   private func sample() {
       guard !isSampling else { return }
       isSampling = true

       if !smcDriverLoaded { initSMC() }

       let snapshot = captureSnapshot()

       Task.detached(priority: .utility) { [weak self] in
           guard let self = self else { return }
           let result = self.performBackgroundSample(snapshot: snapshot)
           if result == nil {
               await MainActor.run { self.isSampling = false }
               return
           }
           await MainActor.run { [weak self] in
               guard let self = self else { return }
               self.applySampleResult(result!)
           }
       }
   }
   ```

4. **Keep `ioQueue`** for `fetchTopProcesses()` — it's used once every 4 seconds, not every tick.

5. **Test:** Run the test `testSampleDoesNotBlockMainThread` — it should still pass (< 500ms main thread block).

**Risk:** LOW. Isolated change to one method. The `ioQueue` is preserved for other uses.

---

## Overall remaining tasks summary

| Item | File | Effort | Risk | Ready? |
|------|------|--------|------|--------|
| A-07 ProcessorModel → actor | `ProcessorModel.swift` + 20+ callers | 2-3h | Medium | ⏳ Need dedicated session |
| A-12 Context switch reduction | `TelemetryModel.swift` (sample()) | 20min | Low | ✅ Ready |
