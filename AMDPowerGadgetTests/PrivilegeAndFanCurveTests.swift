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
        let curve = FanCurve(name: "empty", points: [], sourceSensor: .cpu, hysteresis: 2, rampRate: 10)
        let lut = curve.generateLUT()
        XCTAssertEqual(lut.count, 256)
        XCTAssertTrue(lut.allSatisfy { $0 == 0 })
    }

    func testFanCurveSinglePointFillsLUT() {
        let curve = FanCurve(
            name: "flat",
            points: [FanCurvePoint(temp: 40, pwm: 50)],
            sourceSensor: .cpu,
            hysteresis: 2,
            rampRate: 10
        )
        let lut = curve.generateLUT()
        XCTAssertEqual(lut.count, 256)
        // 50% of 255 ≈ 128 (rounded); generateLUT uses max(1, ...) for zero only
        XCTAssertTrue(lut.allSatisfy { $0 > 0 })
    }

    func testFanCurveTwoPointInterpolation() {
        // Two points: 40°C@20%PWM, 80°C@80%PWM
        // At 60°C should be 50% PWM (linear interpolation)
        let curve = FanCurve(
            name: "interp",
            points: [FanCurvePoint(temp: 40, pwm: 20), FanCurvePoint(temp: 80, pwm: 80)],
            sourceSensor: .cpu,
            hysteresis: 2,
            rampRate: 5
        )
        let lut = curve.generateLUT()
        XCTAssertEqual(lut.count, 256)
        // At 40°C (index 40): 20% of 255 = 51
        XCTAssertEqual(lut[40], 51, "At first point temp, PWM should be 20% of 255")
        // At 80°C (index 80): 80% of 255 = 204
        XCTAssertEqual(lut[80], 204, "At last point temp, PWM should be 80% of 255")
        // At 60°C (index 60): 50% of 255 = 128 (rounds from 127.5)
        XCTAssertEqual(lut[60], 128, "Midpoint interpolation: 50% of 255")
    }

    func testFanCurvePWMZeroReturnsOne() {
        // pwmByte returns 1 when byteVal is 0 (never fully stop fan)
        let curve = FanCurve(
            name: "minPWM",
            points: [FanCurvePoint(temp: 40, pwm: 0)],
            sourceSensor: .cpu,
            hysteresis: 2,
            rampRate: 5
        )
        let lut = curve.generateLUT()
        XCTAssertFalse(lut.allSatisfy { $0 == 0 }, "No entry should be zero")
        XCTAssertTrue(lut.allSatisfy { $0 >= 1 }, "Minimum value should be 1, not 0")
    }

    func testFanCurvePWMFullScale() {
        // 100% PWM → 255
        let curve = FanCurve(
            name: "full",
            points: [FanCurvePoint(temp: 50, pwm: 100)],
            sourceSensor: .cpu,
            hysteresis: 2,
            rampRate: 5
        )
        let lut = curve.generateLUT()
        // All entries should be 255
        XCTAssertTrue(lut.allSatisfy { $0 == 255 }, "100% PWM should produce all 255")
    }

    func testFanCurveClampBelowMin() {
        // Points at 60°C@50%, temps below 60 should clamp to first point
        let curve = FanCurve(
            name: "clampLow",
            points: [FanCurvePoint(temp: 60, pwm: 50), FanCurvePoint(temp: 80, pwm: 100)],
            sourceSensor: .cpu,
            hysteresis: 2,
            rampRate: 5
        )
        let lut = curve.generateLUT()
        // Temp 0-59 should all have same value (128 = 50% of 255)
        XCTAssertEqual(lut[0], 128, "At temp=0, should clamp to first point PWM (50%)")
        XCTAssertEqual(lut[30], 128, "At temp=30, should clamp to first point PWM (50%)")
        XCTAssertEqual(lut[59], 128, "At temp=59, should clamp to first point PWM (50%)")
    }

    func testFanCurveClampAboveMax() {
        // Points at 20°C@30%, temps above 60 should clamp to last point
        let curve = FanCurve(
            name: "clampHigh",
            points: [FanCurvePoint(temp: 20, pwm: 30), FanCurvePoint(temp: 60, pwm: 80)],
            sourceSensor: .cpu,
            hysteresis: 2,
            rampRate: 5
        )
        let lut = curve.generateLUT()
        // Temp 61-255 should all have same value (204 = 80% of 255)
        XCTAssertEqual(lut[61], 204, "At temp=61, should clamp to last point PWM")
        XCTAssertEqual(lut[100], 204, "At temp=100, should clamp to last point PWM")
        XCTAssertEqual(lut[255], 204, "At temp=255, should clamp to last point PWM")
    }

    func testFanCurveUnsortedPoints() {
        // Points provided in reverse order should be sorted internally
        let curve = FanCurve(
            name: "unsorted",
            points: [FanCurvePoint(temp: 80, pwm: 100), FanCurvePoint(temp: 40, pwm: 50), FanCurvePoint(temp: 60, pwm: 75)],
            sourceSensor: .cpu,
            hysteresis: 2,
            rampRate: 5
        )
        let lut = curve.generateLUT()
        // After sorting: 40→50, 60→75, 80→100
        // At 40°C (index 40): 50% of 255 = 128
        XCTAssertEqual(lut[40], 128, "Unsorted points: first sorted point should work")
        // At 70°C (index 70): should interpolate between 60→75 and 80→100
        // Midpoint of 60-80 at 70: (75+100)/2 = 87.5% of 255 ≈ 223
        XCTAssertEqual(lut[70], 223, "Unsorted points: interpolation should work")
    }

    func testFanCurveNaNInPWMSafeToZero() {
        // NaN PWM should be treated as 0 → pwmByte returns 1
        let curve = FanCurve(
            name: "nan",
            points: [FanCurvePoint(temp: 50, pwm: Double.nan)],
            sourceSensor: .cpu,
            hysteresis: 2,
            rampRate: 5
        )
        let lut = curve.generateLUT()
        XCTAssertTrue(lut.allSatisfy { $0 == 1 }, "NaN PWM should be treated as 0 → minimum 1")
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
