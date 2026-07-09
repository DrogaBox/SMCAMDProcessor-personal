import XCTest
@testable import AMD_Power_Gadget

/// Audit R-5: light unit coverage for privilege hints, fan LUT edge cases, language list.
final class PrivilegeAndFanCurveTests: XCTestCase {

    func testPrivilegeHintNotPrivilegedReturnsMessage() {
        let status = ProcessorModel.kIOReturnNotPrivilegedCode
        let hint = ProcessorModel.privilegeHint(for: status)
        XCTAssertNotNil(hint)
        XCTAssertFalse(hint!.isEmpty)
        XCTAssertTrue(hint!.localizedCaseInsensitiveContains("amdpnopchk")
                      || hint!.localizedCaseInsensitiveContains("administrator")
                      || hint!.localizedCaseInsensitiveContains("privileg"))
    }

    func testPrivilegeHintSuccessIsNil() {
        XCTAssertNil(ProcessorModel.privilegeHint(for: KERN_SUCCESS))
    }

    func testFanCurveEmptyPointsReturnsZeroLUT() {
        let curve = FanCurve(name: "empty", points: [], sourceSensor: 0, hysteresis: 2, rampRate: 10)
        let lut = curve.generateLUT()
        XCTAssertEqual(lut.count, 256)
        XCTAssertTrue(lut.allSatisfy { $0 == 0 })
    }

    func testFanCurveSinglePointFillsLUT() {
        let curve = FanCurve(
            name: "flat",
            points: [FanCurvePoint(temp: 40, pwm: 50)],
            sourceSensor: 0,
            hysteresis: 2,
            rampRate: 10
        )
        let lut = curve.generateLUT()
        XCTAssertEqual(lut.count, 256)
        // 50% of 255 ≈ 128 (rounded); generateLUT uses max(1, ...) for zero only
        XCTAssertTrue(lut.allSatisfy { $0 > 0 })
    }

    func testPStateRowZeroRawDoesNotCrash() {
        let row = PStateRow.from(raw: 0, index: 0, cpuFamily: 0x19)
        XCTAssertEqual(row.enabled, 0)
        XCTAssertEqual(row.computedSpeedMHz, 0.0, accuracy: 0.01)
    }

    func testAppLanguageIncludesEnglish() {
        let codes = AppLanguage.allCases.map(\.rawValue)
        XCTAssertTrue(codes.contains("en"))
        XCTAssertTrue(codes.contains("")) // system
    }

    func testChartStyleNormalizesLegacySpanishKeys() {
        XCTAssertEqual(AppChartStyle.normalized("Histograma de Barras"), .bar)
        XCTAssertEqual(AppChartStyle.normalized("Línea Suave (Spline)"), .line)
        XCTAssertEqual(AppChartStyle.normalized("Área Rellena (Gradient)"), .filledArea)
        XCTAssertEqual(AppChartStyle.normalized("Línea Escalonada (Step)"), .steppedLine)
        XCTAssertEqual(AppChartStyle.normalized("Column Bars"), .bar)
        XCTAssertEqual(AppChartStyle.normalized("Smooth Curves"), .line)
    }

    func testChartStyleMigrationRewritesUserDefaults() {
        let ud = UserDefaults(suiteName: "com.drogabox.tests.chartstyle.\(UUID().uuidString)")!
        ud.set("Histograma de Barras", forKey: AppChartStyle.storageKey)
        let style = AppChartStyle.migrateStoredPreference(defaults: ud)
        XCTAssertEqual(style, .bar)
        XCTAssertEqual(ud.string(forKey: AppChartStyle.storageKey), AppChartStyle.bar.rawValue)
    }
}
