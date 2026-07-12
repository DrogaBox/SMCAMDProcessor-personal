//
//  TelemetryModel.swift
//  AMD Power Gadget
//
//  Created by Droga (2026) — SwiftUI Tahoe Redesign
//

import SwiftUI
import Combine
import Foundation
import Darwin
import Metal
import VideoToolbox
import CoreMedia
import UserNotifications
import IOKit.ps

// MARK: - Data Structures

struct CoreSnapshot: Identifiable {
    let id: Int
    var freqMHz: Float
    var loadPct: Float
    var isLogical: Bool
    var cppcScore: UInt8? = nil
    var cppcScoreEstimated: Bool = false
    var coreRank: Int? = nil
}

/// A physical core with its CPPC or estimated silicon quality ranking
struct RankedPhysicalCore: Identifiable {
    let id: Int            // 1-based physical core number
    let score: UInt8       // 0-255 quality score (CPPC or estimated)
    let rank: Int          // 1-based rank (1 = best)
    let isEstimated: Bool  // true if derived from max observed freq, not CPPC MSR
    
    var rankText: String { "\(rank)." }
    var scoreText: String { (isEstimated ? "~" : "") + String(score) }
}

struct FanSnapshot: Identifiable {
    let id: Int
    var name: String
    var rpm: UInt64
    var throttle: UInt8
    var isOverrided: Bool
}

struct FanCurvePoint: Codable, Identifiable, Hashable {
    var id = UUID()
    var temp: Double
    var pwm: Double
}

struct FanCurve: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var points: [FanCurvePoint]
    var sourceSensor: Int // 0 = CPU, 1 = GPU
    var hysteresis: Double // In °C
    var rampRate: Double   // In % PWM / sec
    
    func generateLUT() -> [UInt8] {
        var lut = [UInt8](repeating: 0, count: 256)
        let sortedPoints = points.sorted { $0.temp < $1.temp }
        guard let firstPt = sortedPoints.first, let lastPt = sortedPoints.last else { return lut }
        
        for temp in 0...255 {
            let tempD = Double(temp)
            if tempD <= firstPt.temp {
                let rawPWM = firstPt.pwm
                let byteVal = UInt8(round((rawPWM / 100.0) * 255.0))
                lut[temp] = byteVal == 0 ? 1 : byteVal
                continue
            }
            if tempD >= lastPt.temp {
                let rawPWM = lastPt.pwm
                let byteVal = UInt8(round((rawPWM / 100.0) * 255.0))
                lut[temp] = byteVal == 0 ? 1 : byteVal
                continue
            }
            for i in 0..<(sortedPoints.count - 1) {
                let p1 = sortedPoints[i]
                let p2 = sortedPoints[i + 1]
                if tempD >= p1.temp && tempD <= p2.temp {
                    let pct = (tempD - p1.temp) / (p2.temp - p1.temp)
                    let interpPWM = p1.pwm + pct * (p2.pwm - p1.pwm)
                    let byteVal = UInt8(round((interpPWM / 100.0) * 255.0))
                    lut[temp] = byteVal == 0 ? 1 : byteVal
                    break
                }
            }
        }
        return lut
    }
}

struct PStateRow: Identifiable {
    let id: Int
    var enabled: UInt32
    var iddDiv: UInt32
    var iddValue: UInt32
    var cpuVid: UInt32
    var cpuDfsId: UInt32
    var cpuFid: UInt32
    var isZen5: Bool = false

    /// Computed frequency in MHz, using the correct formula for the CPU architecture.
    var computedSpeedMHz: Float {
        if isZen5 {
            // Zen 5 (Family 1Ah): frequency = CpuFid * 5 MHz, no divisor
            return Float(cpuFid) * 5.0
        } else {
            guard cpuDfsId > 0 else { return 0 }
            return Float(cpuFid) / Float(cpuDfsId) * 200.0
        }
    }

    /// Encodes the row back into the raw 64-bit MSR register value.
    var rawValue: UInt64 {
        var r: UInt64 = 0
        r |= UInt64(enabled)  << 63
        r |= (UInt64(iddDiv)   & 0x3)  << 30
        r |= (UInt64(iddValue) & 0xff) << 22
        r |= (UInt64(cpuVid)   & 0xff) << 14
        if isZen5 {
            // Zen 5: CpuFid occupies bits 0-11 (12 bits), no CpuDfsId field
            r |= UInt64(cpuFid) & 0xfff
        } else {
            r |= (UInt64(cpuDfsId) & 0x1f) << 8
            r |=  UInt64(cpuFid)   & 0xff
        }
        return r
    }

    /// Decodes a raw 64-bit MSR value into a PStateRow.
    /// - Parameters:
    ///   - raw: The raw UInt64 register value.
    ///   - index: The P-state index (0–7).
    ///   - cpuFamily: The CPU family from CPUID (e.g. 0x17, 0x19, 0x1A).
    static func from(raw: UInt64, index: Int, cpuFamily: UInt64 = 0) -> PStateRow {
        let zen5 = cpuFamily >= 0x1A
        return PStateRow(
            id:       index,
            enabled:  UInt32(raw >> 63),
            iddDiv:   UInt32((raw >> 30) & 0x3),
            iddValue: UInt32((raw >> 22) & 0xff),
            cpuVid:   UInt32((raw >> 14) & 0xff),
            cpuDfsId: zen5 ? 1 : UInt32((raw >> 8) & 0x1f),
            cpuFid:   zen5 ? UInt32(raw & 0xfff) : UInt32(raw & 0xff),
            isZen5:   zen5
        )
    }
}

struct TelemetryPoint: Identifiable {
    let id: Int
    var time: Double
    var cpuFreqGHz: Double
    var cpuFreqMaxGHz: Double
    var instRetired: UInt64      // raw instruction count (not scaled)
    var gpuTempC: Double
    var cpuTempC: Double
    var cpuWatts: Double
    var gpuWatts: Double
    var netUploadMBps: Double
    var netDownloadMBps: Double
    var cpuLoad: Double
    var gpuLoad: Double
    var ramUsagePct: Double
    var diskUsagePct: Double
    var diskReadMBps: Double
    var diskWriteMBps: Double
    var fanRPM: Double
}

struct SystemInfo {
    var cpuBrand: String = ""
    var cpuFamily: String = ""
    var cpuModel: String = ""
    var physicalCores: Int = 0
    var logicalCores: Int = 0
    var l1KB: Int = 0
    var l2MB: Int = 0
    var l3MB: Int = 0
    var boardName: String = ""
    var boardVendor: String = ""
    var gpuModel: String = ""
    var ramGB: Int = 0
    var storageGB: Int = 0
    var macOSVersion: String = ""
    var kextVersion: String = ""
    var kextSupported: Bool = false
    var metalVersion: String = ""
    var vdaAcceleration: String = ""
}

// MARK: - Chart Size Config

struct ChartSizeConfig {
    static let shared = ChartSizeConfig()
    private let ud = UserDefaults.standard

    var dashboardHeight: CGFloat {
        get { CGFloat(ud.double(forKey: "chart_dash_h")) }
        set { ud.set(Double(newValue), forKey: "chart_dash_h") }
    }
    var telemetryBarHeight: CGFloat {
        get { CGFloat(ud.double(forKey: "chart_tbar_h")) }
        set { ud.set(Double(newValue), forKey: "chart_tbar_h") }
    }
    var telemetryLineHeight: CGFloat {
        get { CGFloat(ud.double(forKey: "chart_tline_h")) }
        set { ud.set(Double(newValue), forKey: "chart_tline_h") }
    }

    init() {
        if ud.object(forKey: "chart_dash_h") == nil { ud.set(100.0, forKey: "chart_dash_h") }
        if ud.object(forKey: "chart_tbar_h") == nil { ud.set(140.0, forKey: "chart_tbar_h") }
        if ud.object(forKey: "chart_tline_h") == nil { ud.set(80.0, forKey: "chart_tline_h") }
    }
}

// MARK: - ProcessInfoRow
struct ProcessInfoRow: Identifiable {
    let id: Int32
    var name: String
    var cpuUsage: Float
}

// MARK: - TelemetryModel

@MainActor
final class TelemetryModel: ObservableObject {
    static let shared = TelemetryModel()

    @Published var selectedTab: DashboardTab = .dashboard
    /// Non-nil when a privileged kext write was denied (root / -amdpnopchk required).
    @Published var privilegeErrorMessage: String? = nil
    @Published var cpuFreqAvgGHz: Double = 0
    @Published var cpuFreqMaxGHz: Double = 0
    @Published var cpuTempC: Double = 0
    @Published var cpuWatts: Double = 0
    @Published var gpuTempC: Double = 0
    @Published var gpuPowerW: Double = 0
    @Published var gpuLoadPct: Double = 0
    @Published var gpuVramUsedBytes: Double = 0
    @Published var gpuFanRPM: Double = 0
    @Published var ccdTemperatures: [Float] = []
    @Published var instRetiredFormatted: String = "0"
    @Published var netUploadMBps: Double = 0
    @Published var netDownloadMBps: Double = 0
    @Published var cpuLoadAvg: Double = 0
    @Published var ramUsagePct: Double = 0
    @Published var diskUsagePct: Double = 0
    @Published var diskReadMBps: Double = 0
    @Published var diskWriteMBps: Double = 0
    @Published var ramSwapTotalBytes: Double = 0
    @Published var ramSwapUsedBytes: Double = 0
    @Published var netLocalIP: String = "Unknown"
    @Published var netActiveInterface: String = "Unknown"
    @Published var systemUptimeFormatted: String = "0m"
    @Published var topProcesses: [ProcessInfoRow] = []

    @Published var cores: [CoreSnapshot] = []
    @Published var fans: [FanSnapshot] = []
    @Published var hiddenFanIDs: Set<Int> = [] {
        didSet {
            UserDefaults.standard.set(Array(hiddenFanIDs), forKey: "hidden_fan_ids")
        }
    }
    @Published var history: [TelemetryPoint] = []

    // Sparkline history buffers
    @Published var cpuLoadHistory = MetricHistory(capacity: 30)
    @Published var gpuLoadHistory = MetricHistory(capacity: 30)
    @Published var cpuTempHistory = MetricHistory(capacity: 30)
    @Published var gpuTempHistory = MetricHistory(capacity: 30)
    @Published var cpuPowerHistory = MetricHistory(capacity: 30)
    @Published var gpuPowerHistory = MetricHistory(capacity: 30)
    @Published var ramHistory = MetricHistory(capacity: 30)
    
    // Memory pressure, Battery status, Uptime
    @Published var memoryPressure: String = "Normal"
    @Published var memoryPressureColor: Color = .green
    @Published var batteryPercentage: Int = -1
    @Published var batteryIsCharging: Bool = false
    @Published var hasBattery: Bool = false

    // Cache structures for performance optimization
    private var lastDiskIOCheck: Date = Date.distantPast
    private var cachedDiskIO: (read: UInt64, write: UInt64) = (0, 0)
    private var lastCCDCheck: Date = Date.distantPast
    private var cachedCCDTemps: [Float] = []
    private var historyCounter: Int = 0
    private var historyBuffer = SimpleDeque<TelemetryPoint>(capacity: 120)
    private var lastRAMCheck: Date = Date.distantPast
    private var cachedRAMUsage: Double = 0.0
    private let cachedCsvDelimiter: String
    private var cachedCSVColumnConfig: CSVColumnConfig? = nil
    private var csvConfigDirty: Bool = true

    @Published var selectedSpeedStep: Int = 0
    @Published var speedStepClocks: [Float] = []
    @Published var curveOptimizerOffsets: [Int8] = []
    @Published var numPhysicalCores: Int = 0

    @Published var cpbSupported: Bool = false
    @Published var cpbEnabled: Bool = false
    @Published var ppmEnabled: Bool = false
    @Published var lpmEnabled: Bool = false

    @Published var cppcSupported: Bool = false
    @Published var cppcScores: [UInt8] = []
    @Published var cppcScoresEstimated: Bool = false
    @Published var rankedPhysicalCores: [RankedPhysicalCore] = []
    @Published var cstateAddress: UInt64 = 0
    @Published var cppcActiveMode: Bool = false
    @Published var cppcEPPValue: UInt8 = 0x3F
    
    @Published var autoEPPEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(autoEPPEnabled, forKey: "autoEPPEnabled")
        }
    }
    @Published var autoEPPIdleThreshold: Double = 15.0 {
        didSet {
            UserDefaults.standard.set(autoEPPIdleThreshold, forKey: "autoEPPIdleThreshold")
        }
    }
    @Published var autoEPPHighThreshold: Double = 65.0 {
        didSet {
            UserDefaults.standard.set(autoEPPHighThreshold, forKey: "autoEPPHighThreshold")
        }
    }
    private var lastAutoEPPApplied: UInt8? = nil
    
    @Published var autoPowerSourceSwitchingEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(autoPowerSourceSwitchingEnabled, forKey: "autoPowerSourceSwitchingEnabled")
            if autoPowerSourceSwitchingEnabled {
                evaluatePowerSourceSwitching()
            }
        }
    }
    @Published var batteryEPPValue: UInt8 = 0xC0 {
        didSet { UserDefaults.standard.set(Int(batteryEPPValue), forKey: "batteryEPPValue") }
    }
    @Published var acEPPValue: UInt8 = 0x3F {
        didSet { UserDefaults.standard.set(Int(acEPPValue), forKey: "acEPPValue") }
    }
    private var lastPowerSourceIsAC: Bool? = nil
    
    @Published var autoFanCurveEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(autoFanCurveEnabled, forKey: "autoFanCurveEnabled")
            if autoFanCurveEnabled {
                updateKextCurves()
                updateKextMappings()
            } else {
                releaseAllKextMappings()
                setAllFansAuto()
            }
        }
    }
    @Published var fanCurveMinTemp: Double = 40.0 {
        didSet { UserDefaults.standard.set(fanCurveMinTemp, forKey: "fanCurveMinTemp") }
    }
    @Published var fanCurveMaxTemp: Double = 75.0 {
        didSet { UserDefaults.standard.set(fanCurveMaxTemp, forKey: "fanCurveMaxTemp") }
    }
    @Published var customCurves: [FanCurve] = [] {
        didSet {
            if let data = try? JSONEncoder().encode(customCurves) {
                UserDefaults.standard.set(data, forKey: "customCurves")
            }
            updateKextCurves()
        }
    }
    @Published var fanMappings: [Int: Int] = [:] {
        didSet {
            if let data = try? JSONEncoder().encode(fanMappings) {
                UserDefaults.standard.set(data, forKey: "fanMappings")
            }
            updateKextMappings()
        }
    }
    @Published var customFanNames: [Int: String] = [:] {
        didSet {
            if let data = try? JSONEncoder().encode(customFanNames) {
                UserDefaults.standard.set(data, forKey: "customFanNames")
            }
            updateFanNames()
        }
    }
    private var lastAppliedFanPWM: UInt8? = nil
    private var cachedNumPhysicalCores: Int = 0
    private var cachedNumLogicalCores: Int = 0
    private var rankedCoreLookupMap: [Int: RankedPhysicalCore] = [:]
    private var lastHeavySyscallCheck: Date = Date.distantPast
    private var lastProcessFetchTime: Date = Date.distantPast
    
    private var lastCPUControlsCheck: Date = Date.distantPast
    private var lastSwapCheck: Date = Date.distantPast
    private var lastIPCheck: Date = Date.distantPast
    private var lastDiskUsageCheck: Date = Date.distantPast
    private var lastUptimeCheck: Date = Date.distantPast
    private var lastWrittenGPUTemp: Float = -1.0
    private var lastGPUTempWriteTime: Date = Date.distantPast
    
    private var cachedDiskUsage: Double = 0.0
    private var cachedSwap: (total: Double, used: Double) = (0.0, 0.0)
    private var cachedIPInfo: (ip: String, interface: String) = ("", "")
    private var cachedUptime: String = ""
    
    private(set) var maxObservedFreq_perCore: [Int: Float] = [:]

    @Published var pStateRows: [PStateRow] = []
    @Published var pStateEditorDirty: Bool = false

    // CSV logging properties
    @Published var isLoggingEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(isLoggingEnabled, forKey: "isLoggingEnabled")
            if isLoggingEnabled {
                startLoggingSession()
            } else {
                stopLoggingSession()
            }
        }
    }
    @Published var logFilePath: String = "" {
        didSet {
            UserDefaults.standard.set(logFilePath, forKey: "logFilePath")
            if isLoggingEnabled {
                stopLoggingSession()
                startLoggingSession()
            }
        }
    }
    private let logger = CSVLogger()

    // Notifications properties
    @Published var notificationsEnabled: Bool = false {
        didSet {
            // Guard against no-op writes: without this, the permission callback
            // re-assigns notificationsEnabled (e.g. = granted true) which re-fires
            // didSet and calls requestNotificationPermission() again -> infinite loop.
            guard notificationsEnabled != oldValue else { return }
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
            if notificationsEnabled {
                requestNotificationPermission()
            }
        }
    }
    @Published var tempAlertThreshold: Int = 90 {
        didSet {
            UserDefaults.standard.set(tempAlertThreshold, forKey: "tempAlertThreshold")
        }
    }
    @Published var powerAlertThreshold: Int = 142 {
        didSet {
            UserDefaults.standard.set(powerAlertThreshold, forKey: "powerAlertThreshold")
        }
    }
    @Published var powerAlertDuration: Int = 10 {
        didSet {
            UserDefaults.standard.set(powerAlertDuration, forKey: "powerAlertDuration")
        }
    }

    // Software Update properties
    @Published var isCheckingForUpdates: Bool = false
    @Published var updateAvailable: Bool = false
    @Published var updateCheckMessage: String = ""
    @Published var latestVersionTag: String = ""
    @Published var releaseURLString: String = ""

    private var lastTempAlertTime: Date?
    private var lastPowerAlertTime: Date?
    private var powerViolationStartTime: Date?
    private var stabilizedEstimatedScores: [Int: UInt8] = [:]

    @Published var smcDriverLoaded: Bool = false
    @Published var sysInfo: SystemInfo = SystemInfo()

    private var timer: AnyCancellable?
    private let startTime: Double = Date.timeIntervalSinceReferenceDate
    private let maxHistoryPoints = 120

    private var activeWindows = false
    private var popoverVisible = false
    @Published var isAnyWidgetHovered = false {
        didSet {
            updateTimerState()
        }
    }
    private var statusbarActive = false
    private var lastDiskReadBytes: UInt64 = 0
    private var lastDiskWriteBytes: UInt64 = 0
    private var lastDiskCheck: Date = Date.distantPast
    /// Utility QoS: telemetry is continuous background work, not interactive UI.
    private let ioQueue = DispatchQueue(label: "com.drogabox.SMCAMDProcessor.io", qos: .utility)
    private var isSampling = false
    private var lastFanSampleTime: Date = .distantPast
    private var lastHistoryPublishTime: Date = .distantPast
    private var lastGPUExtraSample: Date = .distantPast

    func setPopoverVisible(_ visible: Bool) {
        popoverVisible = visible
        updateTimerState()
    }

    func setStatusbarActive(_ active: Bool) {
        statusbarActive = active
        updateTimerState()
    }

    func updateTimerState() {
        if activeWindows || popoverVisible || DesktopWidgetManager.shared.hasActiveWidgets || statusbarActive {
            restartTimer()
        } else {
            timer?.cancel()
            timer = nil
        }
    }

    private var numFans = 0
    private var fanNames: [String] = []

    // Inst Retired accumulation (like original Power Tool) — resets display every ~1 second
    private var instAccumulated: UInt64 = 0
    private var instElapsedTime: Double = 0.0

    init() {
        let decimal = Locale.current.decimalSeparator ?? "."
        cachedCsvDelimiter = decimal == "," ? ";" : ","
        
        buildSystemInfo()
        updateRankedPhysicalCores() // Initialize ranking early (fallback mode)
        speedStepClocks = ProcessorModel.shared.getValidPStateClocks()
        selectedSpeedStep = ProcessorModel.shared.getPState()

        // Load settings from UserDefaults
        self.isLoggingEnabled = false // Keep logging off on startup for safety/disk space
        self.logFilePath = UserDefaults.standard.string(forKey: "logFilePath") ?? ""
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        self.tempAlertThreshold = UserDefaults.standard.integer(forKey: "tempAlertThreshold")
        if self.tempAlertThreshold == 0 { self.tempAlertThreshold = 90 }
        self.powerAlertThreshold = UserDefaults.standard.integer(forKey: "powerAlertThreshold")
        if self.powerAlertThreshold == 0 { self.powerAlertThreshold = 142 }
        self.powerAlertDuration = UserDefaults.standard.integer(forKey: "powerAlertDuration")
        if self.powerAlertDuration == 0 { self.powerAlertDuration = 10 }

        self.autoEPPEnabled = UserDefaults.standard.bool(forKey: "autoEPPEnabled")
        let idleT = UserDefaults.standard.double(forKey: "autoEPPIdleThreshold")
        self.autoEPPIdleThreshold = idleT > 0 ? idleT : 15.0
        let highT = UserDefaults.standard.double(forKey: "autoEPPHighThreshold")
        self.autoEPPHighThreshold = highT > 0 ? highT : 65.0

        self.autoFanCurveEnabled = UserDefaults.standard.bool(forKey: "autoFanCurveEnabled")
        let fMin = UserDefaults.standard.double(forKey: "fanCurveMinTemp")
        self.fanCurveMinTemp = fMin > 0 ? fMin : 40.0
        let fMax = UserDefaults.standard.double(forKey: "fanCurveMaxTemp")
        self.fanCurveMaxTemp = fMax > 0 ? fMax : 75.0

        if let data = UserDefaults.standard.data(forKey: "customCurves"),
           let decoded = try? JSONDecoder().decode([FanCurve].self, from: data) {
            self.customCurves = decoded
        } else {
            self.customCurves = [
                FanCurve(name: "CPU Silent", points: [
                    FanCurvePoint(temp: 35.0, pwm: 20.0),
                    FanCurvePoint(temp: 55.0, pwm: 35.0),
                    FanCurvePoint(temp: 75.0, pwm: 65.0),
                    FanCurvePoint(temp: 85.0, pwm: 80.0)
                ], sourceSensor: 0, hysteresis: 2.0, rampRate: 5.0),
                FanCurve(name: "CPU Standard", points: [
                    FanCurvePoint(temp: 35.0, pwm: 25.0),
                    FanCurvePoint(temp: 55.0, pwm: 45.0),
                    FanCurvePoint(temp: 75.0, pwm: 75.0),
                    FanCurvePoint(temp: 85.0, pwm: 90.0)
                ], sourceSensor: 0, hysteresis: 2.0, rampRate: 5.0),
                FanCurve(name: "CPU Performance", points: [
                    FanCurvePoint(temp: 30.0, pwm: 35.0),
                    FanCurvePoint(temp: 50.0, pwm: 60.0),
                    FanCurvePoint(temp: 70.0, pwm: 85.0),
                    FanCurvePoint(temp: 80.0, pwm: 100.0)
                ], sourceSensor: 0, hysteresis: 2.0, rampRate: 8.0),
                FanCurve(name: "GPU Sync", points: [
                    FanCurvePoint(temp: 40.0, pwm: 20.0),
                    FanCurvePoint(temp: 60.0, pwm: 45.0),
                    FanCurvePoint(temp: 75.0, pwm: 75.0),
                    FanCurvePoint(temp: 85.0, pwm: 95.0)
                ], sourceSensor: 1, hysteresis: 3.0, rampRate: 5.0)
            ]
        }
        
        if let data = UserDefaults.standard.data(forKey: "fanMappings"),
           let decoded = try? JSONDecoder().decode([Int: Int].self, from: data) {
            self.fanMappings = decoded
        } else {
            self.fanMappings = [:]
        }

        if let data = UserDefaults.standard.data(forKey: "customFanNames"),
           let decoded = try? JSONDecoder().decode([Int: String].self, from: data) {
            self.customFanNames = decoded
        } else {
            self.customFanNames = [:]
        }

        if let ids = UserDefaults.standard.array(forKey: "hidden_fan_ids") as? [Int] {
            self.hiddenFanIDs = Set(ids)
        }

        initSMC()
        applySavedCPUControls()
        loadPStateRows()
        loadCPUControls()
        
        let initialDisk = getDiskIOBytes()
        lastDiskReadBytes = initialDisk.read
        lastDiskWriteBytes = initialDisk.write
        lastDiskCheck = Date()
        
        sample()

        restartTimer()
        NotificationCenter.default.addObserver(self, selector: #selector(handleActiveWindowsChanged), name: .init("AppActiveWindowsChanged"), object: nil)
        NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.csvConfigDirty = true
        }

        // Background update check on launch — 5 s delay so the UI is fully ready
        // and the kext connection is stable before hitting the network.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.checkForUpdates(manual: false)
        }
    }

    private func buildSystemInfo() {
        let pm = ProcessorModel.shared
        let id = pm.cpuidBasic

        var info = SystemInfo()
        info.cpuBrand   = pm.systemConfig["cpu"] ?? ProcessorModel.sysctlString(key: "machdep.cpu.brand_string")
        info.macOSVersion = pm.systemConfig["os"] ?? ""
        info.kextVersion  = pm.AMDRyzenCPUPowerManagementVersion
        info.kextSupported = id.count > 7 && id[7] == 1

        if id.count >= 7 {
            info.cpuFamily    = String(format: "%02Xh", id[0])
            info.cpuModel     = String(format: "%02Xh", id[1])
            info.physicalCores = Int(id[2])
            info.logicalCores  = Int(id[3])
            info.l1KB          = Int(id[4]) * Int(id[2])
            info.l2MB          = Int(id[5]) * Int(id[2]) / 1024
            info.l3MB          = Int(id[6]) / 1024
        }

        if pm.boardValid {
            info.boardName   = pm.boardName
            info.boardVendor = pm.boardVendor
        }
        info.gpuModel = pm.systemConfig["gpu"] ?? ""

        if let memStr = pm.systemConfig["mem"], let memMB = Int(memStr) {
            info.ramGB = memMB / 1024
        }
        if let rsStr = pm.systemConfig["rs"], let rsGB = Int(rsStr) {
            info.storageGB = rsGB / 1024
        }

        // Metal & Hardware Acceleration Detection
        if let device = MTLCreateSystemDefaultDevice() {
            var ver = "Metal 1"
            if #available(macOS 13.0, *) {
                if device.supportsFamily(.metal3) {
                    ver = "Metal 3"
                } else if device.supportsFamily(.apple7) || device.supportsFamily(.common3) {
                    ver = "Metal 2"
                }
            } else {
                ver = "Metal 2"
            }
            info.metalVersion = "\(ver) (\(device.name))"
        } else {
            info.metalVersion = "Not Supported"
        }

        // VDA Decoders Detection (VideoToolbox)
        let h264 = VTIsHardwareDecodeSupported(kCMVideoCodecType_H264)
        let hevc = VTIsHardwareDecodeSupported(kCMVideoCodecType_HEVC)
        if h264 && hevc {
            info.vdaAcceleration = "H.264 & HEVC Active"
        } else if h264 {
            info.vdaAcceleration = "H.264 Active (HEVC Inactive)"
        } else if hevc {
            info.vdaAcceleration = "HEVC Active (H.264 Inactive)"
        } else {
            info.vdaAcceleration = "Inactive / Not Supported"
        }

        sysInfo = info
    }

    private func initSMC() {
        cachedNumPhysicalCores = 0
        cachedNumLogicalCores = 0
        let initRes = ProcessorModel.shared.kernelGetUInt64(count: 2, selector: 90)
        guard initRes.count > 0 && initRes[0] == 1 else { return }
        smcDriverLoaded = true

        let cppcRes = ProcessorModel.shared.getCPPCScore()
        cppcSupported = cppcRes.supported
        cppcScores = cppcRes.scores
        // Zen + Active Mode: never stick a false "unsupported" from a flaky score call.
        if ProcessorModel.shared.getCPPCActiveMode().active {
            cppcSupported = true
        }
        cppcScoresEstimated = cppcSupported && (cppcScores.isEmpty || cppcScores.allSatisfy { $0 == 0 })
        updateRankedPhysicalCores()
        
        cstateAddress = ProcessorModel.shared.getCStateAddress()

        let fansRes = ProcessorModel.shared.kernelGetUInt64(count: 1, selector: 91)
        guard fansRes.count > 0 else { return }
        numFans = Int(fansRes[0])
        
        fanNames.removeAll()
        for i in 0..<numFans {
            fanNames.append(ProcessorModel.shared.kernelGetString(selector: 92, args: [UInt64(i)]))
        }

        fans = (0..<numFans).map { idx in
            let defaultName = fanNames[idx]
            let displayName = customFanNames[idx] ?? (defaultName.isEmpty ? "Fan \(idx + 1)" : defaultName)
            return FanSnapshot(id: idx, name: displayName, rpm: 0, throttle: 0, isOverrided: false)
        }
        
        fetchCurveOptimizerOffsets()
    }

    func restartTimer() {
        timer?.cancel()
        // Always honor the user-selected interval (Advanced → Refresh Rate).
        // Do not clamp by popover/menubar mode — that would cancel the slider.
        let interval = max(0.1, min(5.0, RefreshRateConfig.shared.interval))
        timer = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.sample() }
    }

    @objc private func handleActiveWindowsChanged(_ notification: Notification) {
        if let active = notification.object as? Bool {
            activeWindows = active
            updateTimerState()
        }
    }

    private func sample() {
        guard !isSampling else { return }
        isSampling = true

        ioQueue.async { [weak self] in
            guard let self = self else { return }

            if !self.smcDriverLoaded {
                self.initSMC()
            }

            let pm = ProcessorModel.shared
            var numPhys = self.cachedNumPhysicalCores
            if numPhys == 0 {
                numPhys = pm.getNumOfCore()
            }
            let numLogi = self.sysInfo.logicalCores > 0 ? self.sysInfo.logicalCores : numPhys

            // Light mode: menu bar only (no dashboard/popover) — fewer kext/GPU calls
            let lightMode = !self.activeWindows && !self.popoverVisible
            let logging = self.isLoggingEnabled
            let mbc = MenuBarConfig.shared

            let metric   = pm.getMetric(forced: true)
            let loadIndex = pm.getLoadIndex()
            
            let skipGPU = lightMode && !logging && !mbc.showGPU && !mbc.showGPUvram && !mbc.showGPUfan
            let skipGPUThermals = lightMode && !logging && !mbc.showGPUtemp && !mbc.showGPUpwr
            
            let rawGPUTemp = skipGPUThermals ? Float(self.gpuTempC) : pm.getGPUTemp()
            let rawGPUPower = skipGPUThermals ? Float(self.gpuPowerW) : pm.getGPUPower()
            let nowTime = Date()
            let rawGPULoad: Float
            let rawGPUVram: Float
            let rawGPUFan: Float
            if skipGPU {
                rawGPULoad = Float(self.gpuLoadPct)
                rawGPUVram = Float(self.gpuVramUsedBytes)
                rawGPUFan = Float(self.gpuFanRPM)
            } else if lightMode, nowTime.timeIntervalSince(self.lastGPUExtraSample) < 3.0 {
                rawGPULoad = Float(self.gpuLoadPct)
                rawGPUVram = Float(self.gpuVramUsedBytes)
                rawGPUFan = Float(self.gpuFanRPM)
            } else {
                rawGPULoad = pm.getGPUUtilization()
                rawGPUVram = pm.getGPUVramUsed()
                rawGPUFan = pm.getGPUFanRPM()
                self.lastGPUExtraSample = nowTime
            }
            let ccdTemps: [Float]
            if lightMode && !logging {
                ccdTemps = self.cachedCCDTemps
            } else {
                let ccdTTL: TimeInterval = lightMode ? 4.0 : 2.0
                if nowTime.timeIntervalSince(self.lastCCDCheck) >= ccdTTL {
                    ccdTemps = pm.getCCDTemperatures()
                    self.cachedCCDTemps = ccdTemps
                    self.lastCCDCheck = nowTime
                } else {
                    ccdTemps = self.cachedCCDTemps
                }
            }
            let instDelta = pm.getInstructionDelta()

            let numFansCount = self.numFans
            var fanRpms: [UInt64] = []
            var fanCtrls: [UInt64] = []
            if lightMode && !logging && !mbc.showFanRPM {
                // skip polling fans
            } else {
                let fanTTL: TimeInterval = lightMode ? 2.0 : 0.8
                if self.smcDriverLoaded && numFansCount > 0,
                   nowTime.timeIntervalSince(self.lastFanSampleTime) >= fanTTL {
                    fanRpms  = pm.kernelGetUInt64(count: numFansCount, selector: 93)
                    fanCtrls = pm.kernelGetUInt64(count: numFansCount, selector: 94)
                    self.lastFanSampleTime = nowTime
                }
            }

            let ramUsage: Double
            let now = Date()
            if lightMode && !logging && !mbc.showMemory {
                ramUsage = self.cachedRAMUsage
            } else {
                if now.timeIntervalSince(self.lastRAMCheck) >= 2.0 {
                    ramUsage = self.getRAMUsagePct()
                    self.cachedRAMUsage = ramUsage
                    self.lastRAMCheck = now
                } else {
                    ramUsage = self.cachedRAMUsage
                }
            }
            
            let diskUsage: Double
            if lightMode && !logging {
                diskUsage = self.cachedDiskUsage
            } else {
                if now.timeIntervalSince(self.lastDiskUsageCheck) >= 10.0 {
                    diskUsage = self.getDiskUsagePct()
                    self.cachedDiskUsage = diskUsage
                    self.lastDiskUsageCheck = now
                } else {
                    diskUsage = self.cachedDiskUsage
                }
            }
            
            let diskIO: (read: UInt64, write: UInt64)
            if lightMode && !logging {
                diskIO = self.cachedDiskIO
            } else {
                if now.timeIntervalSince(self.lastDiskIOCheck) >= 2.0 {
                    diskIO = self.getDiskIOBytes()
                    self.cachedDiskIO = diskIO
                    self.lastDiskIOCheck = now
                } else {
                    diskIO = self.cachedDiskIO
                }
            }

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.isSampling = false
                self.processSampleData(
                    numPhys: numPhys,
                    numLogi: numLogi,
                    metric: metric,
                    loadIndex: loadIndex,
                    rawGPUTemp: rawGPUTemp,
                    rawGPUPower: rawGPUPower,
                    rawGPULoad: rawGPULoad,
                    rawGPUVram: rawGPUVram,
                    rawGPUFan: rawGPUFan,
                    ccdTemps: ccdTemps,
                    instDelta: instDelta,
                    fanRpms: fanRpms,
                    fanCtrls: fanCtrls,
                    ramUsage: ramUsage,
                    diskUsage: diskUsage,
                    diskIO: diskIO,
                    lightMode: lightMode
                )
            }
        }
    }

    private func processSampleData(
        numPhys: Int,
        numLogi: Int,
        metric: [Float],
        loadIndex: [Float],
        rawGPUTemp: Float,
        rawGPUPower: Float,
        rawGPULoad: Float,
        rawGPUVram: Float,
        rawGPUFan: Float,
        ccdTemps: [Float],
        instDelta: [UInt64],
        fanRpms: [UInt64],
        fanCtrls: [UInt64],
        ramUsage: Double,
        diskUsage: Double,
        diskIO: (read: UInt64, write: UInt64),
        lightMode: Bool = false
    ) {
        if cachedNumPhysicalCores == 0 {
            cachedNumPhysicalCores = numPhys
            cachedNumLogicalCores = numLogi
            self.numPhysicalCores = numPhys
        }
        let numPhysicalCores = cachedNumPhysicalCores
        let numLogicalCores = cachedNumLogicalCores

        guard numPhysicalCores > 0 && numLogicalCores > 0 && metric.count > numPhysicalCores + 2 else { return }
        let now = Date()

        let watts  = Double(metric[0])
        let tempC  = Double(metric[1])
        var freqsMHz: [Float] = []
        for i in 0..<numPhysicalCores { freqsMHz.append(metric[i + 3]) }

        let avgMHz = freqsMHz.reduce(0, +) / Float(freqsMHz.count)
        let maxMHz = freqsMHz.max() ?? 0

        cpuTempC    = tempC
        if watts < 1000 { cpuWatts = watts }
        cpuFreqAvgGHz = Double(avgMHz) * 0.001
        cpuFreqMaxGHz = Double(maxMHz) * 0.001

        gpuTempC = Double(rawGPUTemp)
        let roundedTemp = round(rawGPUTemp)
        if smcDriverLoaded && (roundedTemp != lastWrittenGPUTemp || now.timeIntervalSince(lastGPUTempWriteTime) >= 5.0) {
            _ = ProcessorModel.shared.kernelSetUInt64(selector: 103, args: [UInt64(roundedTemp)])
            lastWrittenGPUTemp = roundedTemp
            lastGPUTempWriteTime = now
        }
        gpuPowerW = Double(rawGPUPower)
        
        let targetGPULoad = Double(rawGPULoad)
        if gpuLoadPct == 0 && targetGPULoad > 0 {
            gpuLoadPct = targetGPULoad
        } else {
            gpuLoadPct = (gpuLoadPct * 0.8) + (targetGPULoad * 0.2) // EMA for smoothing
        }

        gpuVramUsedBytes = Double(rawGPUVram)
        gpuFanRPM = Double(rawGPUFan)
        if !ccdTemps.elementsEqual(ccdTemperatures) {
            ccdTemperatures = ccdTemps
        }

        let instSum = instDelta.reduce(0, +)
        instAccumulated += instSum
        instElapsedTime += RefreshRateConfig.shared.interval

        // Update display every ~1 second regardless of polling interval
        if instElapsedTime >= 1.0 {
            instRetiredFormatted = formatInstRetired(instAccumulated)
            instAccumulated = 0
            instElapsedTime = 0.0
        }

        // CPPC Fallback: update maximum observed frequencies
        var freqUpdated = false
        for logicalIdx in 0..<numLogicalCores {
            let physicalIdx = logicalIdx % numPhysicalCores
            let freq = freqsMHz[physicalIdx]
            let currentMax = maxObservedFreq_perCore[logicalIdx] ?? 0.0
            if freq > currentMax {
                maxObservedFreq_perCore[logicalIdx] = freq
                freqUpdated = true
            }
        }

        // Always update ranked cores if frequencies changed and we're relying on them
        let cppcHasReal = cppcSupported && !cppcScoresEstimated && !cppcScores.isEmpty && !cppcScores.allSatisfy { $0 == 0 }
        if freqUpdated && !cppcHasReal {
            self.updateRankedPhysicalCores()
        }

        var newCores: [CoreSnapshot] = []
        for logicalIdx in 0..<numLogicalCores {
            let physicalIdx = logicalIdx % numPhysicalCores
            let freq = freqsMHz[physicalIdx]
            let load = (loadIndex.count > logicalIdx) ? loadIndex[logicalIdx] * 100.0 : 0.0
            let isLogical = logicalIdx >= numPhysicalCores
            
            var cppcVal: UInt8? = nil
            var rRank: Int? = nil
            if let r = rankedCoreLookupMap[physicalIdx + 1] {
                rRank = r.rank
                if cppcSupported && cppcScoresEstimated {
                    cppcVal = r.score
                }
            }
            if cppcSupported && !cppcScoresEstimated && cppcScores.count > logicalIdx {
                cppcVal = cppcScores[logicalIdx]
            }
            
            newCores.append(CoreSnapshot(
                id: logicalIdx,
                freqMHz: freq,
                loadPct: Float(load),
                isLogical: isLogical,
                cppcScore: cppcVal,
                cppcScoreEstimated: cppcScoresEstimated,
                coreRank: rRank
            ))
        }
        var shouldUpdateCores = false
        if newCores.count != cores.count {
            shouldUpdateCores = true
        } else {
            for idx in 0..<newCores.count {
                let old = cores[idx]
                let new = newCores[idx]
                if abs(new.freqMHz - old.freqMHz) > 1.0 ||
                    abs(new.loadPct - old.loadPct) > 1.0 ||
                    new.isLogical != old.isLogical ||
                    new.cppcScore != old.cppcScore ||
                    new.coreRank != old.coreRank {
                    shouldUpdateCores = true
                    break
                }
            }
        }
        if shouldUpdateCores {
            cores = newCores
        }
        
        let totalLoad = newCores.reduce(0.0) { $0 + Double($1.loadPct) }
        cpuLoadAvg = newCores.isEmpty ? 0.0 : (totalLoad / Double(newCores.count))
        
        if autoPowerSourceSwitchingEnabled && cppcActiveMode {
            evaluatePowerSourceSwitching()
        } else if autoEPPEnabled && cppcActiveMode {
            evaluateAutoEPP(currentLoad: cpuLoadAvg)
        }
        if autoFanCurveEnabled {
            // Evaluated kext-side in v3.14.5
        }
        
        
        ramUsagePct = ramUsage
        diskUsagePct = diskUsage
        
        if lastDiskCheck != Date.distantPast {
            let elapsed = now.timeIntervalSince(lastDiskCheck)
            if elapsed > 0.1 {
                let rDelta = diskIO.read >= lastDiskReadBytes ? diskIO.read - lastDiskReadBytes : 0
                let wDelta = diskIO.write >= lastDiskWriteBytes ? diskIO.write - lastDiskWriteBytes : 0
                
                let rSpeed = Double(rDelta) / elapsed / (1024.0 * 1024.0)
                let wSpeed = Double(wDelta) / elapsed / (1024.0 * 1024.0)
                
                diskReadMBps = rSpeed < 0.00001 ? 0 : rSpeed
                diskWriteMBps = wSpeed < 0.00001 ? 0 : wSpeed
            }
        }
        lastDiskReadBytes = diskIO.read
        lastDiskWriteBytes = diskIO.write
        lastDiskCheck = now
        
        if popoverVisible && MenuBarConfig.shared.popoverShowProcesses {
            if lastProcessFetchTime == Date.distantPast || now.timeIntervalSince(lastProcessFetchTime) >= 4.0 {
                lastProcessFetchTime = now
                Task.detached(priority: .background) {
                    let list = self.fetchTopProcesses()
                    await MainActor.run {
                        self.topProcesses = list
                    }
                }
            }
        }

        var netUp: Double = 0
        var netDown: Double = 0
        let isNetActive = (selectedTab == .dashboard || selectedTab == .telemetry || popoverVisible)
        
        // Skip network polling entirely if in menubar mode and networking is hidden
        let skipNetwork = lightMode && !isLoggingEnabled && !MenuBarConfig.shared.showNetwork
        
        if !skipNetwork {
            if let netSnap = NetworkStats.shared.update(lowFrequency: !isNetActive) {
                netUp = netSnap.uploadMBps
                netDown = netSnap.downloadMBps
            }
        } else {
            netUp = self.netUploadMBps
            netDown = self.netDownloadMBps
        }
        self.netUploadMBps = netUp
        self.netDownloadMBps = netDown

        let relTime = Date.timeIntervalSinceReferenceDate - startTime
        
        var firstFanRPM: Double = 0
        if smcDriverLoaded && numFans > 0 {
            if let firstRpm = fanRpms.first {
                firstFanRPM = Double(firstRpm)
            }
        }

        let point = TelemetryPoint(
            id: historyCounter,
            time: relTime,
            cpuFreqGHz: cpuFreqAvgGHz,
            cpuFreqMaxGHz: cpuFreqMaxGHz,
            instRetired: instSum,  // per-sample delta for chart
            gpuTempC: gpuTempC,
            cpuTempC: cpuTempC,
            cpuWatts: cpuWatts,
            gpuWatts: gpuPowerW,
            netUploadMBps: netUp,
            netDownloadMBps: netDown,
            cpuLoad: cpuLoadAvg,
            gpuLoad: gpuLoadPct,
            ramUsagePct: ramUsagePct,
            diskUsagePct: diskUsagePct,
            diskReadMBps: diskReadMBps,
            diskWriteMBps: diskWriteMBps,
            fanRPM: firstFanRPM
        )
        historyCounter += 1
        historyBuffer.append(point)
        
        cpuLoadHistory.push(cpuLoadAvg)
        gpuLoadHistory.push(gpuLoadPct)
        cpuTempHistory.push(cpuTempC)
        cpuPowerHistory.push(cpuWatts)
        gpuTempHistory.push(gpuTempC)
        gpuPowerHistory.push(gpuPowerW)
        
        let usedRAM = (ramUsagePct / 100.0) * (Double(ProcessInfo.processInfo.physicalMemory) / (1024.0 * 1024.0 * 1024.0))
        ramHistory.push(usedRAM)
        
        updateMemoryPressure()
        getBatteryStatus()

        // Publishing full history array every tick is expensive for SwiftUI charts.
        // Light mode (menu bar only): refresh history less often.
        let historyTTL: TimeInterval = lightMode ? 2.0 : 0.0
        if historyTTL <= 0 || now.timeIntervalSince(lastHistoryPublishTime) >= historyTTL {
            history = historyBuffer.elements
            lastHistoryPublishTime = now
        }

        if smcDriverLoaded && numFans > 0 && !fanRpms.isEmpty {
            var updatedFans = fans
            for i in 0..<numFans where i < updatedFans.count {
                updatedFans[i].rpm        = fanRpms.count  > i ? fanRpms[i]                 : 0
                updatedFans[i].throttle   = fanCtrls.count > i ? UInt8(fanCtrls[i] >> 8)    : 0
                updatedFans[i].isOverrided = fanCtrls.count > i ? (fanCtrls[i] & 0xff) == 0 : false
            }
            self.fans = updatedFans
        }

        // Background CSV logging
        writeTelemetryToLogFile(point: point)
        
        // System alerts notifications check
        if notificationsEnabled {
            let now = Date()
            
            // 1. Temperature Alerts
            if cpuTempC >= Double(tempAlertThreshold) {
                let shouldAlert = lastTempAlertTime.map { now.timeIntervalSince($0) >= 60.0 } ?? true
                if shouldAlert {
                    lastTempAlertTime = now
                    sendNotification(
                        title: NSLocalizedString("CPU Temperature Alert", comment: ""),
                        body: String(format: NSLocalizedString("CPU temperature has reached %.1f°C!", comment: ""), cpuTempC),
                        identifier: "tempAlert"
                    )
                }
            }
            
            // 2. Power PPT Alerts
            if cpuWatts >= Double(powerAlertThreshold) {
                if let startTime = powerViolationStartTime {
                    let elapsed = now.timeIntervalSince(startTime)
                    if elapsed >= Double(powerAlertDuration) {
                        let shouldAlert = lastPowerAlertTime.map { now.timeIntervalSince($0) >= 60.0 } ?? true
                        if shouldAlert {
                            lastPowerAlertTime = now
                            sendNotification(
                                title: NSLocalizedString("CPU Power Alert", comment: ""),
                                body: String(format: NSLocalizedString("CPU power has been at %.1fW (above limit of %dW) for over %d seconds!", comment: ""), cpuWatts, powerAlertThreshold, powerAlertDuration),
                                identifier: "powerAlert"
                            )
                        }
                    }
                } else {
                    powerViolationStartTime = now
                }
            } else {
                powerViolationStartTime = nil
            }
        }

        if now.timeIntervalSince(lastCPUControlsCheck) >= 5.0 {
            loadCPUControls()
            speedStepClocks  = ProcessorModel.shared.getValidPStateClocks()
            selectedSpeedStep = ProcessorModel.shared.getPState()
            lastCPUControlsCheck = now
        }
        
        if now.timeIntervalSince(lastSwapCheck) >= 5.0 {
            let swap = getSwapMemoryUsage()
            cachedSwap = (total: swap.total, used: swap.used)
            lastSwapCheck = now
        }
        ramSwapTotalBytes = cachedSwap.total
        ramSwapUsedBytes = cachedSwap.used
        
        if now.timeIntervalSince(lastIPCheck) >= 10.0 {
            let ipInfo = getLocalIPAddressAndInterface()
            cachedIPInfo = ipInfo
            lastIPCheck = now
        }
        netLocalIP = cachedIPInfo.ip
        netActiveInterface = cachedIPInfo.interface
        
        if now.timeIntervalSince(lastUptimeCheck) >= 1.0 {
            systemUptimeFormatted = getSystemUptime()
            lastUptimeCheck = now
        }
        
    }

    // Format instruction count with suffix like original: K, M, G, T, P, E
    func formatInstRetired(_ number: UInt64) -> String {
        var num: Double = Double(number)
        let sign = (num < 0) ? "-" : ""
        num = abs(num)
        if num < 1000.0 {
            return "\(sign)\(Int(num))"
        }
        let exp = Int(log10(num) / 3.0)
        let units = ["K", "M", "G", "T", "P", "E"]
        let idx = min(exp - 1, units.count - 1)
        let rounded = round(10 * num / pow(1000.0, Double(exp))) / 10
        return "\(sign)\(rounded)\(units[idx])"
    }

    func applySavedCPUControls() {
        // Restore persisted controls; surface first privilege denial via banner.
        if UserDefaults.standard.bool(forKey: "has_saved_cppcActiveMode") {
            let active = UserDefaults.standard.bool(forKey: "saved_cppcActiveMode")
            _ = noteKernelWriteStatus(ProcessorModel.shared.setCPPCActiveMode(active: active))
        }
        if UserDefaults.standard.bool(forKey: "has_saved_cppcEPPValue") {
            let epp = UInt8(UserDefaults.standard.integer(forKey: "saved_cppcEPPValue"))
            _ = noteKernelWriteStatus(ProcessorModel.shared.setCPPCEPPValue(epp: epp))
        }
        if UserDefaults.standard.bool(forKey: "has_saved_cpbEnabled") {
            let enabled = UserDefaults.standard.bool(forKey: "saved_cpbEnabled")
            _ = noteKernelWriteStatus(ProcessorModel.shared.setCPB(enabled: enabled))
        }
        if UserDefaults.standard.bool(forKey: "has_saved_ppmEnabled") {
            let enabled = UserDefaults.standard.bool(forKey: "saved_ppmEnabled")
            _ = noteKernelWriteStatus(ProcessorModel.shared.setPPM(enabled: enabled))
        }
        if UserDefaults.standard.bool(forKey: "has_saved_lpmEnabled") {
            let enabled = UserDefaults.standard.bool(forKey: "saved_lpmEnabled")
            _ = noteKernelWriteStatus(ProcessorModel.shared.setLPM(enabled: enabled))
        }
    }

    func loadCPUControls() {
        let cpb = ProcessorModel.shared.getCPB()
        cpbSupported = cpb.count > 0 && cpb[0]
        cpbEnabled   = cpb.count > 1 && cpb[1]
        ppmEnabled   = ProcessorModel.shared.getPPM()
        lpmEnabled   = ProcessorModel.shared.getLPM()

        let cppcRes = ProcessorModel.shared.getCPPCScore()
        let cppc = ProcessorModel.shared.getCPPCActiveMode()
        cppcActiveMode = cppc.active
        cppcEPPValue = cppc.epp
        // Refresh support for Profiles banner; Active Mode bit also implies CPPC path is live.
        cppcSupported = cppcRes.supported || cppc.active
        if cppcRes.supported {
            cppcScores = cppcRes.scores
            cppcScoresEstimated = cppcScores.isEmpty || cppcScores.allSatisfy { $0 == 0 }
        }
    }

    /// Report a kernel write failure to the UI (privilege banner / console).
    @discardableResult
    func noteKernelWriteStatus(_ status: kern_return_t) -> Bool {
        if status == KERN_SUCCESS {
            if privilegeErrorMessage != nil { privilegeErrorMessage = nil }
            return true
        }
        if let hint = ProcessorModel.privilegeHint(for: status) {
            privilegeErrorMessage = hint
        }
        return false
    }

    func clearPrivilegeError() {
        privilegeErrorMessage = nil
    }

    /// Flush in-memory UI state before process exit / language relaunch (audit R-7).
    /// Curves and mappings already auto-save via `didSet`; re-push to kext and sync defaults.
    func commitPendingChanges() {
        UserDefaults.standard.synchronize()
        if smcDriverLoaded {
            updateKextCurves()
            updateKextMappings()
        }
        if pStateEditorDirty {
            _ = applyPStates()
        }
        HistoryManager.shared.flushToDisk()
    }

    func setCPB(enabled: Bool) {
        let status = ProcessorModel.shared.setCPB(enabled: enabled)
        if noteKernelWriteStatus(status) {
            UserDefaults.standard.set(enabled, forKey: "saved_cpbEnabled")
            UserDefaults.standard.set(true, forKey: "has_saved_cpbEnabled")
        }
        loadCPUControls()
    }

    func setPPM(enabled: Bool) {
        let status = ProcessorModel.shared.setPPM(enabled: enabled)
        if noteKernelWriteStatus(status) {
            UserDefaults.standard.set(enabled, forKey: "saved_ppmEnabled")
            UserDefaults.standard.set(true, forKey: "has_saved_ppmEnabled")
        }
        loadCPUControls()
    }

    func setLPM(enabled: Bool) {
        let status = ProcessorModel.shared.setLPM(enabled: enabled)
        if noteKernelWriteStatus(status) {
            UserDefaults.standard.set(enabled, forKey: "saved_lpmEnabled")
            UserDefaults.standard.set(true, forKey: "has_saved_lpmEnabled")
        }
        loadCPUControls()
    }

    func setCPPCActiveMode(active: Bool) {
        let status = ProcessorModel.shared.setCPPCActiveMode(active: active)
        if noteKernelWriteStatus(status) {
            UserDefaults.standard.set(active, forKey: "saved_cppcActiveMode")
            UserDefaults.standard.set(true, forKey: "has_saved_cppcActiveMode")
        }
        loadCPUControls()
    }

    func setCPPCEPPValue(epp: UInt8) {
        let status = ProcessorModel.shared.setCPPCEPPValue(epp: epp)
        if noteKernelWriteStatus(status) {
            UserDefaults.standard.set(Int(epp), forKey: "saved_cppcEPPValue")
            UserDefaults.standard.set(true, forKey: "has_saved_cppcEPPValue")
        }
        loadCPUControls()
    }

    private func evaluateAutoEPP(currentLoad: Double) {
        let targetEPP: UInt8
        if currentLoad >= autoEPPHighThreshold {
            targetEPP = 0x00 // Performance
        } else if currentLoad <= autoEPPIdleThreshold {
            targetEPP = 0xC0 // Power Save
        } else {
            targetEPP = 0x3F // Balanced Performance
        }
        
        if lastAutoEPPApplied != targetEPP {
            let status = ProcessorModel.shared.setCPPCEPPValue(epp: targetEPP)
            if noteKernelWriteStatus(status) {
                lastAutoEPPApplied = targetEPP
                cppcEPPValue = targetEPP
            }
        }
    }

    func isCurrentlyOnACPower() -> Bool {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else { return true }
        guard let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else { return true }
        for source in sources {
            if let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] {
                if let powerSource = description[kIOPSPowerSourceStateKey] as? String {
                    if powerSource == kIOPSBatteryPowerValue {
                        return false
                    }
                }
            }
        }
        return true
    }

    private func evaluatePowerSourceSwitching() {
        let isOnAC = isCurrentlyOnACPower()
        if lastPowerSourceIsAC != isOnAC {
            lastPowerSourceIsAC = isOnAC
            let targetEPP = isOnAC ? acEPPValue : batteryEPPValue
            setCPPCEPPValue(epp: targetEPP)
        }
    }

    private func evaluateAutoFanCurve() {
        guard smcDriverLoaded, !fans.isEmpty else { return }
        let currentTemp = cpuTempC
        let targetPWM: UInt8
        
        if currentTemp >= 85.0 {
            // Hardware Thermal Safety Guard: force 80% PWM (0xC8)
            targetPWM = 0xC8
        } else {
            let minT = fanCurveMinTemp
            let maxT = max(minT + 10.0, fanCurveMaxTemp)
            let clampedTemp = min(maxT, max(minT, currentTemp))
            let pct = (clampedTemp - minT) / (maxT - minT)
            // Scale PWM between 20% (50) and 80% (200)
            let pwmVal = 50.0 + pct * 150.0
            targetPWM = UInt8(clampedTemp <= minT ? 0 : min(200, max(50, Int(round(pwmVal)))))
        }
        
        if lastAppliedFanPWM != targetPWM {
            var allOk = true
            for i in 0..<fans.count {
                let st: kern_return_t
                if targetPWM == 0 {
                    st = ProcessorModel.shared.kernelSetUInt64Status(selector: 96, args: [UInt64(i)])
                } else {
                    st = ProcessorModel.shared.kernelSetUInt64Status(selector: 95, args: [UInt64(i), UInt64(targetPWM)])
                }
                if !noteKernelWriteStatus(st) { allOk = false; break }
            }
            if allOk { lastAppliedFanPWM = targetPWM }
        }
    }

    func setSpeedStep(_ index: Int) {
        let status = ProcessorModel.shared.setPState(state: index)
        if noteKernelWriteStatus(status) {
            selectedSpeedStep = index
        } else {
            // Reload actual P-state selection so UI does not stick on a denied step
            loadCPUControls()
        }
    }

    func loadPStateRows() {
        let raw = ProcessorModel.shared.getPStateDef()
        let family = ProcessorModel.shared.cpuidBasic.first ?? 0
        pStateRows = raw.enumerated().map { PStateRow.from(raw: $0.element, index: $0.offset, cpuFamily: family) }
        pStateEditorDirty = false
    }

    func applyPStates() -> Bool {
        let arr = pStateRows.map { $0.rawValue }
        let err = ProcessorModel.shared.setPState(def: arr)
        if err == 0 {
            privilegeErrorMessage = nil
            pStateEditorDirty = false
            loadPStateRows()
            return true
        }
        _ = noteKernelWriteStatus(kern_return_t(err))
        return false
    }

    func setFanThrottle(fanIndex: Int, throttle: UInt8) {
        guard smcDriverLoaded else { return }
        if noteKernelWriteStatus(ProcessorModel.shared.kernelSetUInt64Status(selector: 95, args: [UInt64(fanIndex), UInt64(throttle)])) {
            fans[fanIndex].throttle = throttle
        }
    }

    func setFanOverride(fanIndex: Int, overrideEnabled: Bool) {
        guard smcDriverLoaded, !overrideEnabled else { return }
        if noteKernelWriteStatus(ProcessorModel.shared.kernelSetUInt64Status(selector: 96, args: [UInt64(fanIndex)])) {
            fans[fanIndex].isOverrided = false
        }
    }

    func setAllFansAuto() {
        guard smcDriverLoaded else { return }
        _ = noteKernelWriteStatus(ProcessorModel.shared.kernelSetUInt64Status(selector: 97, args: [0]))
    }

    func setAllFansTakeOff() {
        guard smcDriverLoaded else { return }
        _ = noteKernelWriteStatus(ProcessorModel.shared.kernelSetUInt64Status(selector: 97, args: [1]))
    }

    func updateKextCurves() {
        guard smcDriverLoaded else { return }
        for (idx, curve) in customCurves.enumerated() {
            guard idx < 4 else { break }
            var data = Data()
            var curveIndex = UInt32(idx)
            var sourceSensor = UInt32(curve.sourceSensor)
            var hysteresis = UInt32(round(curve.hysteresis))
            var rampRate = UInt32(round(curve.rampRate))
            
            data.append(UnsafeBufferPointer(start: &curveIndex, count: 1))
            data.append(UnsafeBufferPointer(start: &sourceSensor, count: 1))
            data.append(UnsafeBufferPointer(start: &hysteresis, count: 1))
            data.append(UnsafeBufferPointer(start: &rampRate, count: 1))
            
            let lut = curve.generateLUT()
            data.append(lut, count: 256)
            
            _ = noteKernelWriteStatus(ProcessorModel.shared.kernelSetStruct(selector: 101, data: data))
        }
    }

    func updateKextMappings() {
        guard smcDriverLoaded else { return }
        for (fanIdx, snapshot) in fans.enumerated() {
            let curveIdx = fanMappings[snapshot.id] ?? -1
            let st = ProcessorModel.shared.kernelSetUInt64Status(
                selector: 102,
                args: [UInt64(fanIdx), UInt64(bitPattern: Int64(curveIdx))]
            )
            _ = noteKernelWriteStatus(st)
            if st != KERN_SUCCESS { break }
        }
    }

    func releaseAllKextMappings() {
        guard smcDriverLoaded else { return }
        for (fanIdx, _) in fans.enumerated() {
            let st = ProcessorModel.shared.kernelSetUInt64Status(
                selector: 102,
                args: [UInt64(fanIdx), UInt64(bitPattern: -1)]
            )
            _ = noteKernelWriteStatus(st)
            if st != KERN_SUCCESS { break }
        }
    }

    func updateFanNames() {
        guard numFans > 0 else { return }
        var updated = fans
        for i in 0..<numFans where i < updated.count {
            let defaultName = fanNames.count > i ? fanNames[i] : "Fan \(i + 1)"
            updated[i].name = customFanNames[i] ?? (defaultName.isEmpty ? "Fan \(i + 1)" : defaultName)
        }
        fans = updated
    }

    func exportPStates(to url: URL) {
        let arr = pStateRows.map { $0.rawValue }
        (arr as NSArray).write(to: url, atomically: true)
    }

    func importPStates(from url: URL) {
        guard let arr = NSArray(contentsOf: url) as? [UInt64] else { return }
        let family = ProcessorModel.shared.cpuidBasic.first ?? 0
        pStateRows = arr.enumerated().map { PStateRow.from(raw: $0.element, index: $0.offset, cpuFamily: family) }
        pStateEditorDirty = true
    }

    // MARK: - Resource Metrics Helpers

    nonisolated private func getRAMUsagePct() -> Double {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let kerr = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        if kerr == KERN_SUCCESS {
            var pageSize: vm_size_t = 0
            host_page_size(mach_host_self(), &pageSize)
            let active = Double(stats.active_count) * Double(pageSize)
            let wire = Double(stats.wire_count) * Double(pageSize)
            let compressed = Double(stats.compressor_page_count) * Double(pageSize)
            let used = active + wire + compressed
            let total = Double(ProcessInfo.processInfo.physicalMemory)
            return (used / total) * 100.0
        }
        return 0.0
    }

    nonisolated private func getDiskUsagePct() -> Double {
        do {
            let attrs = try FileManager.default.attributesOfFileSystem(forPath: "/")
            if let totalSize = attrs[.systemSize] as? NSNumber,
               let freeSize = attrs[.systemFreeSize] as? NSNumber {
                let total = totalSize.doubleValue
                let free = freeSize.doubleValue
                let used = total - free
                return (used / total) * 100.0
            }
        } catch {}
        return 0.0
    }

    nonisolated private func getDiskIOBytes() -> (read: UInt64, write: UInt64) {
        var readBytes: UInt64 = 0
        var writeBytes: UInt64 = 0
        
        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOBlockStorageDriver"), &iterator)
        if result == kIOReturnSuccess {
            while true {
                let parent = IOIteratorNext(iterator)
                if parent == 0 { break }
                
                var properties: Unmanaged<CFMutableDictionary>? = nil
                if IORegistryEntryCreateCFProperties(parent, &properties, kCFAllocatorDefault, 0) == kIOReturnSuccess,
                   let dict = properties?.takeRetainedValue() as? [String: Any] {
                    if let stats = dict["Statistics"] as? [String: Any] {
                        if let r = stats["Bytes (Read)"] as? NSNumber {
                            readBytes += r.uint64Value
                        } else if let r = stats["Bytes (Read)"] as? Int64 {
                            readBytes += UInt64(r)
                        }
                        if let w = stats["Bytes (Write)"] as? NSNumber {
                            writeBytes += w.uint64Value
                        } else if let w = stats["Bytes (Write)"] as? Int64 {
                            writeBytes += UInt64(w)
                        }
                    }
                }
                IOObjectRelease(parent)
            }
            IOObjectRelease(iterator)
        }
        return (readBytes, writeBytes)
    }

    struct xsw_usage {
        var xsu_total: UInt64
        var xsu_avail: UInt64
        var xsu_used: UInt64
        var xsu_pagesize: UInt32
        var xsu_encrypted: Int32
    }

    nonisolated private func getSwapMemoryUsage() -> (total: Double, used: Double, free: Double) {
        var size = MemoryLayout<xsw_usage>.size
        var usage = xsw_usage(xsu_total: 0, xsu_avail: 0, xsu_used: 0, xsu_pagesize: 0, xsu_encrypted: 0)
        let result = sysctlbyname("vm.swapusage", &usage, &size, nil, 0)
        if result == 0 {
            return (Double(usage.xsu_total), Double(usage.xsu_used), Double(usage.xsu_avail))
        }
        return (0.0, 0.0, 0.0)
    }

    nonisolated private func getLocalIPAddressAndInterface() -> (ip: String, interface: String) {
        var ipAddress = "Disconnected"
        var interfaceName = "None"
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                guard let interface = ptr?.pointee else { continue }
                let addrFamily = interface.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                    let name = String(cString: interface.ifa_name)
                    if name.hasPrefix("en") || name.hasPrefix("bridge") || name.hasPrefix("bond") {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                    &hostname, socklen_t(hostname.count),
                                    nil, 0, NI_NUMERICHOST)
                        let ip = String(cString: hostname)
                        
                        if interfaceName == "None" || name.hasPrefix("en") {
                            ipAddress = ip
                            interfaceName = name
                        }
                        
                        if addrFamily == UInt8(AF_INET) && name.hasPrefix("en") {
                            break
                        }
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return (ipAddress, interfaceName)
    }

    nonisolated private func getSystemUptime() -> String {
        let seconds = ProcessInfo.processInfo.systemUptime
        let days = Int(seconds) / 86400
        let hours = (Int(seconds) % 86400) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func updateMemoryPressure() {
        var pressure: Int32 = 0
        var size = MemoryLayout<Int32>.size
        if sysctlbyname("kern.memorystatus_vm_pressure_level", &pressure, &size, nil, 0) == 0 {
            switch pressure {
            case 1: 
                memoryPressure = "Normal"
                memoryPressureColor = .green
            case 2: 
                memoryPressure = "Warning"
                memoryPressureColor = .orange
            case 4: 
                memoryPressure = "Critical"
                memoryPressureColor = .red
            default: 
                memoryPressure = "Normal"
                memoryPressureColor = .green
            }
        } else {
            memoryPressure = "Normal"
            memoryPressureColor = .green
        }
    }
    
    private func getBatteryStatus() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else { return }
        guard let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else { return }
        var foundBattery = false
        for source in sources {
            if let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] {
                if let type = description[kIOPSTypeKey] as? String, type == kIOPSInternalBatteryType {
                    foundBattery = true
                    if let capacity = description[kIOPSCurrentCapacityKey] as? Int {
                        batteryPercentage = capacity
                    }
                    if let isCharging = description[kIOPSIsChargingKey] as? Bool {
                        batteryIsCharging = isCharging
                    }
                }
            }
        }
        hasBattery = foundBattery
    }

    nonisolated private func fetchTopProcesses() -> [ProcessInfoRow] {
        let task = Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["-A", "-r", "-o", "pid,%cpu,comm", "-c"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                var list: [ProcessInfoRow] = []
                let lines = output.components(separatedBy: .newlines)
                for line in lines.dropFirst() {
                    let parts = line.split(separator: " ", omittingEmptySubsequences: true)
                    if parts.count >= 3 {
                        if let pid = Int32(parts[0]) {
                            let cpuStr = parts[1].replacingOccurrences(of: ",", with: ".")
                            if let cpu = Float(cpuStr) {
                                let name = parts[2...].joined(separator: " ")
                                let cleanName = name.replacingOccurrences(of: ".app/Contents/MacOS/", with: "")
                                                    .components(separatedBy: "/").last ?? name
                                list.append(ProcessInfoRow(id: pid, name: cleanName, cpuUsage: cpu))
                                if list.count >= 5 {
                                    break
                                }
                            }
                        }
                    }
                }
                return list
            }
        } catch {}
        return []
    }

    // MARK: - Diagnostics, CSV Logging and Alerts Helpers

    private var csvDelimiter: String {
        return cachedCsvDelimiter
    }

    private func startLoggingSession() {
        let headers = getActiveCSVHeaders(includeTimestamp: true)
        logger.start(path: logFilePath, delimiter: csvDelimiter, headers: headers)
    }
    
    private func stopLoggingSession() {
        logger.stop()
    }

    private struct CSVColumnConfig {
        let showCpuTemp: Bool
        let showGpuTemp: Bool
        let showCpuPwr: Bool
        let showGpuPwr: Bool
        let showRam: Bool
        let showDisk: Bool
        let showNet: Bool
        let showFan: Bool
    }
    
    private func loadCSVColumnConfig() -> CSVColumnConfig {
        if !csvConfigDirty, let cached = cachedCSVColumnConfig {
            return cached
        }
        let ud = UserDefaults.standard
        let config = CSVColumnConfig(
            showCpuTemp: ud.object(forKey: "tele_show_cputemp") as? Bool ?? true,
            showGpuTemp: ud.object(forKey: "tele_show_gputemp") as? Bool ?? true,
            showCpuPwr:  ud.object(forKey: "tele_show_cpupwr") as? Bool ?? true,
            showGpuPwr:  ud.object(forKey: "tele_show_gpupwr") as? Bool ?? true,
            showRam:     ud.object(forKey: "tele_show_ram") as? Bool ?? true,
            showDisk:    ud.object(forKey: "tele_show_disk") as? Bool ?? true,
            showNet:     ud.object(forKey: "tele_show_net") as? Bool ?? true,
            showFan:     ud.object(forKey: "tele_show_fan") as? Bool ?? true
        )
        cachedCSVColumnConfig = config
        csvConfigDirty = false
        return config
    }

    private func getActiveCSVHeaders(includeTimestamp: Bool) -> [String] {
        var headers: [String] = []
        if includeTimestamp { headers.append("Timestamp") }
        headers.append("Relative Time (s)")
        headers.append("CPU Freq Avg (GHz)")
        headers.append("CPU Load (%)")
        
        let config = loadCSVColumnConfig()
        let showCpuTemp = config.showCpuTemp
        let showGpuTemp = config.showGpuTemp
        let showCpuPwr  = config.showCpuPwr
        let showGpuPwr  = config.showGpuPwr
        let showRam     = config.showRam
        let showDisk    = config.showDisk
        let showNet     = config.showNet
        let showFan     = config.showFan
        
        if showCpuTemp { headers.append("CPU Temp (°C)") }
        if showCpuPwr  { headers.append("CPU Power (W)") }
        if showGpuTemp { headers.append("GPU Temp (°C)") }
        if showGpuPwr  { headers.append("GPU Power (W)") }
        if showRam     { headers.append("RAM Usage (%)") }
        if showDisk    { headers.append("Disk Activity (MB/s)") }
        if showNet     {
            headers.append("Net Download (MB/s)")
            headers.append("Net Upload (MB/s)")
        }
        if showFan     { headers.append("Fan Speed (RPM)") }
        return headers
    }

    private static let isoFormatter = ISO8601DateFormatter()
    private func writeTelemetryToLogFile(point: TelemetryPoint) {
        guard isLoggingEnabled else { return }
        
        let delim = csvDelimiter
        let locale = Locale.current
        let dateString = TelemetryModel.isoFormatter.string(from: Date())
        
        let config = loadCSVColumnConfig()
        let showCpuTemp = config.showCpuTemp
        let showGpuTemp = config.showGpuTemp
        let showCpuPwr  = config.showCpuPwr
        let showGpuPwr  = config.showGpuPwr
        let showRam     = config.showRam
        let showDisk    = config.showDisk
        let showNet     = config.showNet
        let showFan     = config.showFan

        var cols: [String] = []
        cols.append(dateString)
        cols.append(String(format: "%.3f", locale: locale, point.time))
        cols.append(String(format: "%.3f", locale: locale, point.cpuFreqGHz))
        cols.append(String(format: "%.1f", locale: locale, point.cpuLoad))
        
        if showCpuTemp { cols.append(String(format: "%.2f", locale: locale, point.cpuTempC)) }
        if showCpuPwr  { cols.append(String(format: "%.2f", locale: locale, point.cpuWatts)) }
        if showGpuTemp { cols.append(String(format: "%.2f", locale: locale, point.gpuTempC)) }
        if showGpuPwr  { cols.append(String(format: "%.2f", locale: locale, point.gpuWatts)) }
        if showRam     { cols.append(String(format: "%.1f", locale: locale, point.ramUsagePct)) }
        if showDisk    { cols.append(String(format: "%.2f", locale: locale, point.diskReadMBps + point.diskWriteMBps)) }
        if showNet     {
            cols.append(String(format: "%.3f", locale: locale, point.netDownloadMBps))
            cols.append(String(format: "%.3f", locale: locale, point.netUploadMBps))
        }
        if showFan     { cols.append(String(format: "%.0f", locale: locale, point.fanRPM)) }

        let line = cols.joined(separator: delim) + "\n"
        logger.write(line: line)
    }

    func exportHistoryToCSV(url: URL) {
        let delim = csvDelimiter
        let locale = Locale.current
        
        let headers = getActiveCSVHeaders(includeTimestamp: false)
        var csvText = headers.joined(separator: delim) + "\n"
        
        let config = loadCSVColumnConfig()
        let showCpuTemp = config.showCpuTemp
        let showGpuTemp = config.showGpuTemp
        let showCpuPwr  = config.showCpuPwr
        let showGpuPwr  = config.showGpuPwr
        let showRam     = config.showRam
        let showDisk    = config.showDisk
        let showNet     = config.showNet
        let showFan     = config.showFan

        for point in history {
            var cols: [String] = []
            cols.append(String(format: "%.3f", locale: locale, point.time))
            cols.append(String(format: "%.3f", locale: locale, point.cpuFreqGHz))
            cols.append(String(format: "%.1f", locale: locale, point.cpuLoad))
            
            if showCpuTemp { cols.append(String(format: "%.2f", locale: locale, point.cpuTempC)) }
            if showCpuPwr  { cols.append(String(format: "%.2f", locale: locale, point.cpuWatts)) }
            if showGpuTemp { cols.append(String(format: "%.2f", locale: locale, point.gpuTempC)) }
            if showGpuPwr  { cols.append(String(format: "%.2f", locale: locale, point.gpuWatts)) }
            if showRam     { cols.append(String(format: "%.1f", locale: locale, point.ramUsagePct)) }
            if showDisk    { cols.append(String(format: "%.2f", locale: locale, point.diskReadMBps + point.diskWriteMBps)) }
            if showNet     {
                cols.append(String(format: "%.3f", locale: locale, point.netDownloadMBps))
                cols.append(String(format: "%.3f", locale: locale, point.netUploadMBps))
            }
            if showFan     { cols.append(String(format: "%.0f", locale: locale, point.fanRPM)) }

            csvText += cols.joined(separator: delim) + "\n"
        }
        
        try? csvText.write(to: url, atomically: true, encoding: .utf8)
    }

    func fetchCurveOptimizerOffsets() {
        let pm = ProcessorModel.shared
        let offsets = pm.getCurveOptimizerOffsets()
        DispatchQueue.main.async {
            self.curveOptimizerOffsets = offsets
        }
    }
    
    func setCurveOptimizerOffset(core: Int, offset: Int) -> Bool {
        let status = ProcessorModel.shared.setCurveOptimizerOffset(core: UInt8(core), offset: Int8(offset))
        let ok = noteKernelWriteStatus(status)
        if ok {
            fetchCurveOptimizerOffsets()
        }
        return ok
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.notificationsEnabled = granted
                if !granted {
                    UserDefaults.standard.set(false, forKey: "notificationsEnabled")
                }
            }
        }
    }

    private func sendNotification(title: String, body: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Software Updates Helper
    func checkForUpdates(manual: Bool = true) {
        guard !isCheckingForUpdates else { return }
        isCheckingForUpdates = true
        updateCheckMessage = manual ? NSLocalizedString("Checking for updates...", comment: "Update check in progress") : ""
        
        let urlString = "https://api.github.com/repos/DrogaBox/SMCAMDProcessor-personal/releases/latest"
        guard let url = URL(string: urlString) else {
            isCheckingForUpdates = false
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10.0
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isCheckingForUpdates = false
                
                if let error = error {
                    if manual {
                        let format = NSLocalizedString("Connection Error: %@", comment: "")
                        self.updateCheckMessage = String(format: format, error.localizedDescription)
                    }
                    return
                }
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let tagName = json["tag_name"] as? String else {
                    if manual {
                        self.updateCheckMessage = NSLocalizedString("Could not fetch release info.", comment: "")
                    }
                    return
                }
                
                let fallbackBody = NSLocalizedString("No release notes available.", comment: "")
                let bodyText = (json["body"] as? String) ?? fallbackBody
                let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
                let cleanTag = tagName.replacingOccurrences(of: "v", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                let cleanCurrent = currentVersion.replacingOccurrences(of: "v", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                
                self.latestVersionTag = tagName
                self.releaseURLString = (json["html_url"] as? String) ?? "https://github.com/DrogaBox/SMCAMDProcessor-personal/releases"
                
                if cleanTag.compare(cleanCurrent, options: .numeric) == .orderedDescending {
                    self.updateAvailable = true
                    let format = NSLocalizedString("New version %@ available!", comment: "")
                    self.updateCheckMessage = String(format: format, tagName)
                    if manual {
                        let alert = NSAlert()
                        let titleFormat = NSLocalizedString("New Version Available: %@", comment: "")
                        alert.messageText = String(format: titleFormat, tagName)
                        let previewBody = bodyText.count > 300 ? String(bodyText.prefix(300)) + "..." : bodyText
                        let infoFormat = NSLocalizedString("Current version: v%@\nNew version: %@\n\nRelease Notes:\n%@", comment: "")
                        alert.informativeText = String(format: infoFormat, currentVersion, tagName, previewBody)
                        alert.alertStyle = .informational
                        alert.addButton(withTitle: NSLocalizedString("Download on GitHub", comment: ""))
                        alert.addButton(withTitle: NSLocalizedString("Later", comment: ""))
                        if alert.runModal() == .alertFirstButtonReturn {
                            if let openUrl = URL(string: self.releaseURLString) {
                                NSWorkspace.shared.open(openUrl)
                            }
                        }
                    }
                } else {
                    self.updateAvailable = false
                    if manual {
                        let msgFormat = NSLocalizedString("You have the latest version installed (v%@).", comment: "")
                        self.updateCheckMessage = String(format: msgFormat, currentVersion)
                        let alert = NSAlert()
                        alert.messageText = NSLocalizedString("System Up to Date", comment: "")
                        let infoFormat = NSLocalizedString("You are running the most recent version of AMD Power Gadget (v%@).", comment: "")
                        alert.informativeText = String(format: infoFormat, currentVersion)
                        alert.alertStyle = .informational
                        alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
                        alert.runModal()
                    }
                }
            }
        }.resume()
    }
    
    // MARK: - Physical Core Ranking
    
    /// Recomputes rankedPhysicalCores from CPPC scores or max-observed frequencies.
    /// Called after cppcScores are set (initSMC) and after each estimated score update (tick).
    func updateRankedPhysicalCores() {
        let numPhysical = sysInfo.physicalCores
        guard numPhysical > 0 else { return }
        
        let cppcHasReal = cppcSupported && !cppcScoresEstimated && !cppcScores.isEmpty && !cppcScores.allSatisfy { $0 == 0 }
        let maxFreqOverall = maxObservedFreq_perCore.values.max() ?? 1.0
        var list: [RankedPhysicalCore] = []
        
        for physIdx in 0..<numPhysical {
            let score: UInt8
            if cppcHasReal && cppcScores.count > physIdx {
                score = cppcScores[physIdx]
            } else {
                let t0 = physIdx
                let t1 = physIdx + numPhysical
                let f0 = maxObservedFreq_perCore[t0] ?? 0
                let f1 = maxObservedFreq_perCore[t1] ?? 0
                let m = max(f0, f1)
                
                let rawScore: UInt8
                if maxFreqOverall > 0 && m > 0 {
                    rawScore = UInt8(min(255, Int(round((m / maxFreqOverall) * 255.0))))
                } else {
                    rawScore = 0
                }
                
                // Monotonic caching to freeze rankings and prevent jittering
                let prevScore = stabilizedEstimatedScores[physIdx] ?? 0
                score = max(prevScore, rawScore)
                stabilizedEstimatedScores[physIdx] = score
            }
            list.append(RankedPhysicalCore(id: physIdx + 1, score: score, rank: 0, isEstimated: !cppcHasReal))
        }
        let sorted = list.sorted { $0.score != $1.score ? $0.score > $1.score : $0.id < $1.id }
        let ranked = sorted.enumerated().map {
            RankedPhysicalCore(id: $1.id, score: $1.score, rank: $0 + 1, isEstimated: $1.isEstimated)
        }
        var map: [Int: RankedPhysicalCore] = [:]
        for r in ranked {
            map[r.id] = r
        }
        rankedCoreLookupMap = map
        rankedPhysicalCores = ranked
    }
}

// MARK: - CSV Logger Helper Class (Thread-safe & nonisolated to bypass actor deinit constraints)
private class CSVLogger {
    private var fileHandle: FileHandle?
    private let queue = DispatchQueue(label: "wtf.spinach.CSVLogger", qos: .background)
    
    func start(path: String, delimiter: String, headers: [String]) {
        queue.async {
            guard !path.isEmpty else { return }
            let fileURL = URL(fileURLWithPath: path)
            
            // Create file if it doesn't exist
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                let header = headers.joined(separator: delimiter) + "\n"
                try? header.write(to: fileURL, atomically: true, encoding: .utf8)
            }
            
            self.fileHandle?.closeFile()
            self.fileHandle = try? FileHandle(forWritingTo: fileURL)
            self.fileHandle?.seekToEndOfFile()
        }
    }
    
    func stop() {
        queue.async {
            self.fileHandle?.closeFile()
            self.fileHandle = nil
        }
    }
    
    func write(line: String) {
        queue.async {
            if let data = line.data(using: .utf8) {
                self.fileHandle?.write(data)
            }
        }
    }
    
    deinit {
        let handle = fileHandle
        queue.sync {
            handle?.closeFile()
        }
    }
}

// MARK: - Simple Deque Ring Buffer
struct SimpleDeque<T> {
    private var array: [T?]
    private var head: Int = 0
    private var tail: Int = 0
    private(set) var count: Int = 0
    
    init(capacity: Int) {
        self.array = Array(repeating: nil, count: capacity)
    }
    
    mutating func append(_ element: T) {
        if count == array.count {
            array[tail] = element
            tail = (tail + 1) % array.count
            head = (head + 1) % array.count
        } else {
            array[tail] = element
            tail = (tail + 1) % array.count
            count += 1
        }
    }
    
    mutating func clear() {
        array = Array(repeating: nil, count: array.count)
        head = 0
        tail = 0
        count = 0
    }
    
    var elements: [T] {
        var result: [T] = []
        result.reserveCapacity(count)
        for i in 0..<count {
            if let el = array[(head + i) % array.count] {
                result.append(el)
            }
        }
        return result
    }
}

// MARK: - MetricHistory
struct MetricHistory {
    let capacity: Int
    private(set) var values: [Double] = []

    init(capacity: Int) {
        self.capacity = max(1, capacity)
    }

    mutating func push(_ value: Double) {
        values.append(value)
        if values.count > capacity {
            values.removeFirst(values.count - capacity)
        }
    }
}

// MARK: - CaffeinateManager
import IOKit.pwr_mgt

@MainActor
final class CaffeinateManager: ObservableObject {
    static let shared = CaffeinateManager()
    
    @Published var isAwake: Bool = false {
        didSet {
            if isAwake {
                startAssertion()
            } else {
                releaseAssertion()
            }
        }
    }
    
    private var assertionID: IOPMAssertionID = 0
    private var assertionCreated: Bool = false
    private var timer: Timer?

    func toggle() {
        isAwake.toggle()
    }
    
    func keepAwakeFor(hours: Double) {
        isAwake = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: hours * 3600, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.isAwake = false
            }
        }
    }

    private func startAssertion() {
        guard !assertionCreated else { return }
        let reasonForActivity = "AMD Power Gadget User Requested Keep Awake" as CFString
        let success = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reasonForActivity,
            &assertionID
        )
        if success == kIOReturnSuccess {
            assertionCreated = true
        } else {
            isAwake = false
        }
    }
    
    private func releaseAssertion() {
        if assertionCreated {
            IOPMAssertionRelease(assertionID)
            assertionCreated = false
        }
        timer?.invalidate()
        timer = nil
    }
}