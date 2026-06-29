import XCTest
@testable import AMD_Power_Gadget

final class PStateRowTests: XCTestCase {
    func testZen3RoundTrip() {
        let raw: UInt64 = (1 << 63) | (0x48 << 14) | (0x08 << 8) | 0xA0
        let row = PStateRow.from(raw: raw, index: 0, cpuFamily: 0x19)
        XCTAssertEqual(row.enabled, 1)
        XCTAssertEqual(row.cpuFid, 0xA0)
        XCTAssertEqual(row.cpuDfsId, 0x08)
        XCTAssertEqual(row.cpuVid, 0x48)
        XCTAssertEqual(row.computedSpeedMHz, 4000.0, accuracy: 0.1)
        XCTAssertEqual(row.rawValue, raw)
    }

    func testZen5RoundTrip() {
        let raw: UInt64 = (1 << 63) | (0x50 << 14) | 0x3A6
        let row = PStateRow.from(raw: raw, index: 0, cpuFamily: 0x1A)
        XCTAssertTrue(row.isZen5)
        XCTAssertEqual(row.cpuFid, 0x3A6)
        XCTAssertEqual(row.computedSpeedMHz, 4670.0, accuracy: 0.1)
        XCTAssertEqual(row.rawValue, raw)
    }

    func testZeroDfsIdDoesNotCrash() {
        let raw: UInt64 = (1 << 63) | 0xA0
        let row = PStateRow.from(raw: raw, index: 1, cpuFamily: 0x19)
        XCTAssertEqual(row.computedSpeedMHz, 0.0)
    }
}
