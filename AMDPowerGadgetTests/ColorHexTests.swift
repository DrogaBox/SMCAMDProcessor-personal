import XCTest
import SwiftUI
@testable import AMD_Power_Gadget

final class ColorHexTests: XCTestCase {
    func testValid6() { XCTAssertNotNil(Color(hexString: "#4CC9F0")) }
    func testValid3() { XCTAssertNotNil(Color(hexString: "#FFF")) }
    func testValid8() { XCTAssertNotNil(Color(hexString: "#80FFFFFF")) }
    func testInvalidChar() { XCTAssertNil(Color(hexString: "#GG0000")) }
    func testInvalidLen() { XCTAssertNil(Color(hexString: "#12345")) }
    func testEmpty() { XCTAssertNil(Color(hexString: "")) }
    func testNoHashAllowed() { XCTAssertNotNil(Color(hexString: "4CC9F0")) }

    /// Opaque colors serialize as #RRGGBB (no alpha nibble) via toHexString.
    func testToHexOpaqueOmitsAlpha() {
        let color = Color(hexString: "#4CC9F0")!
        XCTAssertEqual(color.toHexString.uppercased(), "#4CC9F0")
    }

    /// Theme editor always stores ARGB so opacity cannot be lost.
    func testToHexARGBAlways8Digits() {
        let opaque = Color(hexString: "#4CC9F0")!
        XCTAssertEqual(opaque.toHexStringARGB.uppercased(), "#FF4CC9F0")
        let translucent = Color(hexString: "#80FF0000")!
        XCTAssertEqual(translucent.toHexStringARGB.uppercased(), "#80FF0000")
    }

    /// Semi-transparent colors must round-trip as #AARRGGBB (alpha first).
    func testToHexPreservesAlpha() {
        let original = "#80FF0000"
        let color = Color(hexString: original)!
        XCTAssertEqual(color.toHexString.uppercased(), original)
        XCTAssertEqual(color.toHexStringARGB.uppercased(), original)
    }

    func testRoundTripSemiTransparentCard() {
        let original = "#D11A1F2B"
        guard let color = Color(hexString: original) else {
            return XCTFail("parse failed")
        }
        let hex = color.toHexStringARGB.uppercased()
        XCTAssertEqual(hex.count, 9)
        guard let again = Color(hexString: hex) else {
            return XCTFail("re-parse failed")
        }
        XCTAssertEqual(again.toHexStringARGB.uppercased(), hex)
    }

    func testWithResolvedAlpha() {
        let base = Color(hexString: "#FF0000")!
        let half = base.withResolvedAlpha(0.5)
        XCTAssertEqual(half.toHexStringARGB.uppercased(), "#80FF0000")
    }

    func testOpacityModifierRoundTrips() {
        let color = Color(red: 0.10, green: 0.12, blue: 0.17).opacity(0.82)
        let hex = color.toHexStringARGB
        XCTAssertEqual(hex.count, 9, "expected #AARRGGBB, got \(hex)")
        XCTAssertNotNil(Color(hexString: hex))
    }
}
