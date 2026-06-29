import XCTest
@testable import AMD_Power_Gadget

final class FormatInstTests: XCTestCase {
    func testBoundaries() {
        XCTAssertEqual(formatInstRetired(0), "0")
        XCTAssertEqual(formatInstRetired(999), "999")
        XCTAssertEqual(formatInstRetired(1_500), "1.5K")
        XCTAssertEqual(formatInstRetired(1_500_000), "1.5M")
        XCTAssertEqual(formatInstRetired(1_500_000_000), "1.5G")
        XCTAssertEqual(formatInstRetired(1_500_000_000_000), "1.5T")
    }
}
