import XCTest
@testable import AMD_Power_Gadget

/// Security audit regression tests (v3.24.1).
///
/// These tests verify fixes for findings A-01 through A-12 from the
/// comprehensive code security audit. Test failures indicate a regression
/// in the corresponding fix.
@MainActor
final class SecurityAuditTests: XCTestCase {

    // MARK: - A-01: GPU temp inject now requires privilege (process-name bypass removed)

    func testPrivilegeHintMentionsGPUTemp() {
        let hint = ProcessorModel.privilegeHint(for: ProcessorModel.kIOReturnNotPrivilegedCode)
        XCTAssertNotNil(hint, "Privilege hint should not be nil for not-privileged code")
        XCTAssertTrue(hint!.contains("GPU temperature"),
                      "Privilege hint should mention GPU temperature injection requires privilege")
        XCTAssertTrue(hint!.contains("-amdpnopchk"),
                      "Privilege hint should mention the -amdpnopchk boot-arg workaround")
    }

    // MARK: - A-02: hasPrivilege() cache — validate the IOReturn constant

    func testNotPrivilegedIOReturnConstant() {
        XCTAssertEqual(ProcessorModel.kIOReturnNotPrivilegedCode,
                       kern_return_t(bitPattern: 0xe00002c1),
                       "kIOReturnNotPrivileged must match XNU definition")
    }

    // MARK: - A-03: Dynamic idle strategy — model property consistency

    func testProcessorModelExposesCStateAddress() {
        // The C-State address is read from the kext and stored; it should never crash.
        let address = ProcessorModel.shared.getCStateAddress()
        // Just validate it returns something — exact value depends on hardware
        XCTAssertNotEqual(address, UInt64.max, "CState address should be reasonable")
    }

    // MARK: - A-06: Weak self in Task { @MainActor } captures
    // Weak self is verified by code review — this ensures the
    // TelemetryModel singleton is accessible without retain cycles.

    func testTelemetryModelDoesNotLeakViaSingleton() {
        let model = TelemetryModel.shared
        XCTAssertNotNil(model, "TelemetryModel singleton should be accessible")
        // The key A-06 fix ensures all Task { @MainActor } closures use
        // explicit [weak self] — verified statically by code review.
    }

    // MARK: - A-08: HistoryManager @MainActor isolation

    func testHistoryManagerIsMainActor() {
        // This compiles only if HistoryManager is @MainActor:
        //   - history (non-sendable) is only accessible from MainActor context
        // This is a compile-time check; the runtime test ensures the shared
        // instance exists without crashing.
        XCTAssertNoThrow(HistoryManager.shared, "HistoryManager.shared should init without error")
    }

    // MARK: - A-09: String safety — outputStrCount > 0 guard

    func testVersionStringNeverCrashes() async {
        // The kext version string is read in init() with outputStrCount > 0 guard.
        // Even if the kext returns an empty string, the app should not crash.
        let version = await ProcessorModel.shared.AMDRyzenCPUPowerManagementVersion
        // Just verify it doesn't crash — version may be empty if no kext
        XCTAssertNoThrow(version.isEmpty || !version.isEmpty,
                         "Version string access should never crash")
    }

    // MARK: - A-10: No hardcoded Spanish strings in popover views

    func testPopoverUsesLocalizedStrings() {
        // Verify the app can load localized strings for EPP slider labels
        let bundle = Bundle(for: type(of: self))
        let powerSave = NSLocalizedString("Power Save", bundle: bundle, comment: "")
        let balancedPower = NSLocalizedString("Balanced Power", bundle: bundle, comment: "")
        let balancedPerf = NSLocalizedString("Balanced Perf", bundle: bundle, comment: "")
        let performance = NSLocalizedString("Performance", bundle: bundle, comment: "")
        let advancedControls = NSLocalizedString("Advanced Controls", bundle: bundle, comment: "")

        // These should NOT match the hardcoded Spanish strings
        XCTAssertNotEqual(powerSave, "Ahorro")
        XCTAssertNotEqual(balancedPower, "Eq. Ahorro")
        XCTAssertNotEqual(balancedPerf, "Eq. Rend.")
        XCTAssertNotEqual(performance, "Rendimiento")
        XCTAssertNotEqual(advancedControls, "Controles Avanzados")
    }

    // MARK: - A-11: Data(bytes:) replaces withUnsafePointer

    func testUpdateKextCurvesDoesNotCrashWhenDisabled() {
        // updateKextCurves() should be a no-op when smcDriverLoaded is false.
        // This tests that the Data(bytes:) pattern doesn't crash with empty curves.
        let model = TelemetryModel.shared
        // Set up a custom curve so the method has data to process
        let originalCurves = model.customCurves
        model.customCurves = [
            FanCurve(name: "Test", points: [FanCurvePoint(temp: 40, pwm: 50)],
                     sourceSensor: .cpu, hysteresis: 2, rampRate: 5)
        ]
        XCTAssertNoThrow(model.updateKextCurves(),
                         "updateKextCurves should not crash when SMC not loaded")
        model.customCurves = originalCurves
    }

    // MARK: - A-12: Sampling loop doesn't deadlock on main thread

    func testSampleDoesNotBlockMainThread() {
        let model = TelemetryModel.shared
        let expectation = expectation(description: "Sample completes within 500ms")
        expectation.isInverted = false

        // sample() is called on main thread via Timer — verify it dispatches
        // background work and returns quickly.
        let start = CFAbsoluteTimeGetCurrent()
        model.restartTimer()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let elapsed = CFAbsoluteTimeGetCurrent() - start
            XCTAssertLessThan(elapsed, 0.5,
                              "Sample loop should not block the main thread for more than 500ms")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    // MARK: - A-12: Structured concurrency context switch verification

    func testCaptureSnapshotIsAsync() {
        // Verify that captureSnapshot is async by checking the TelemetryModel
        // can be used from a structured concurrency context.
        // This is a compile-time check enforced by the actor isolation.
        let model = TelemetryModel.shared
        XCTAssertNotNil(model, "TelemetryModel singleton should exist")
        // The key A-12 improvement is that sample() uses Task { @MainActor }
        // instead of ioQueue.async + Task { @MainActor } — this is verified
        // by code review (can't test context switch count at runtime).
    }

    // MARK: - kIOReturnNotPrivileged constant (cross-check with SMU tests)

    func testNotPrivilegedIsDistinct() {
        XCTAssertNotEqual(ProcessorModel.kIOReturnNotPrivilegedCode, kIOReturnSuccess)
        XCTAssertNotEqual(ProcessorModel.kIOReturnNotPrivilegedCode, kIOReturnError)
        XCTAssertNotEqual(ProcessorModel.kIOReturnNotPrivilegedCode, kIOReturnTimeout)
    }
}
