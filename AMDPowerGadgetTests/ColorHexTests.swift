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
}
