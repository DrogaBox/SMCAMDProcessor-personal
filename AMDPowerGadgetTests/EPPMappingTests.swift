import XCTest
@testable import AMD_Power_Gadget

final class EPPMappingTests: XCTestCase {
    func mapEPPtoSegment(_ epp: UInt8) -> Int {
        if epp <= 0x1F { return 0 }
        else if epp <= 0x5F { return 1 }
        else if epp <= 0x9F { return 2 }
        else { return 3 }
    }
    func testBoundaries() {
        XCTAssertEqual(mapEPPtoSegment(0x00), 0)
        XCTAssertEqual(mapEPPtoSegment(0x1F), 0)
        XCTAssertEqual(mapEPPtoSegment(0x20), 1)
        XCTAssertEqual(mapEPPtoSegment(0x3F), 1)
        XCTAssertEqual(mapEPPtoSegment(0x7F), 2)
        XCTAssertEqual(mapEPPtoSegment(0xC0), 3)
        XCTAssertEqual(mapEPPtoSegment(0xFF), 3)
    }
}
