import XCTest
@testable import AMD_Power_Gadget

@MainActor
final class FormatInstTests: XCTestCase {
    func testBoundaries() {
        let model = TelemetryModel.shared
        XCTAssertEqual(model.formatInstRetired(0), "0")
        XCTAssertEqual(model.formatInstRetired(999), "999")
        XCTAssertEqual(model.formatInstRetired(1_500), "1.5K")
        XCTAssertEqual(model.formatInstRetired(1_500_000), "1.5M")
        XCTAssertEqual(model.formatInstRetired(1_500_000_000), "1.5G")
        XCTAssertEqual(model.formatInstRetired(1_500_000_000_000), "1.5T")
    }
}
