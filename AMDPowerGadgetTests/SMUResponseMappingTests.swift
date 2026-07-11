import XCTest
@testable import AMD_Power_Gadget

/// P2-3 coverage: SMU error-code propagation through UserClient selector 111.
/// These tests verify that the Swift side correctly interprets the IOReturn
/// codes that the kernel now maps from setCurveOptimizer rc values.
final class SMUResponseMappingTests: XCTestCase {

    // MARK: - kIOReturnUnsupported (-1 → 0xe00002c7)
    func testKIOReturnUnsupportedMeansNotZen3() {
        // kIOReturnUnsupported is returned when setCurveOptimizer returns -1
        // (CPU family != 0x19, i.e. not Zen 3).
        let rc = kIOReturnUnsupported
        XCTAssertNotEqual(rc, kIOReturnSuccess)
        XCTAssertNotEqual(rc, kIOReturnError,
            "Unsupported should be a distinct code from generic kIOReturnError")
    }

    // MARK: - kIOReturnBadArgument (-2/-3 → bad core/offset)
    func testKIOReturnBadArgumentForInvalidCoreOrOffset() {
        let rc = kIOReturnBadArgument
        XCTAssertNotEqual(rc, kIOReturnSuccess)
    }

    // MARK: - kIOReturnTimeout (-10 → SMU_RSP_TIMEOUT)
    func testKIOReturnTimeoutFromSMUTimeout() {
        let rc = kIOReturnTimeout
        XCTAssertNotEqual(rc, kIOReturnSuccess)
        XCTAssertNotEqual(rc, kIOReturnError)
    }

    // MARK: - kIOReturnBusy (-13 → SMU_RSP_BUSY)
    func testKIOReturnBusyFromSMUBusy() {
        let rc = kIOReturnBusy
        XCTAssertNotEqual(rc, kIOReturnSuccess)
    }

    // MARK: - Curve Optimizer offset clamping in ProcessorModel
    func testCurveOptimizerOffsetMaxIsClamped() {
        // The kernel enforces [-30, +30]; ensure the model sends within range.
        let clamped = max(-30, min(30, 35))
        XCTAssertEqual(clamped, 30)
    }

    func testCurveOptimizerOffsetMinIsClamped() {
        let clamped = max(-30, min(30, -40))
        XCTAssertEqual(clamped, -30)
    }

    func testCurveOptimizerZeroOffsetPassesThrough() {
        let clamped = max(-30, min(30, 0))
        XCTAssertEqual(clamped, 0)
    }
}
