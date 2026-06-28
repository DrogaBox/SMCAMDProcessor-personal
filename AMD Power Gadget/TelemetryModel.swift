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

// MARK: - Data Structures

struct CoreSnapshot: Identifiable {
    let id: Int
    var freqMHz: Float
    var loadPct: Float
    var isLogical: Bool
    var cppcScore: UInt8? = nil
    var cppcScoreEstimated: Bool = false
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
    let id = UUID()
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
    @Published var history: [TelemetryPoint] = []

    @Published var selectedSpeedStep: Int = 0
    @Published var speedStepClocks: [Float] = []

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

    private var lastTempAlertTime: Date?
    private var lastPowerAlertTime: Date?
    private var powerViolationStartTime: Date?

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
    private var lastDiskReadBytes: UInt64 = 0
    private var lastDiskWriteBytes: UInt64 = 0
    private var lastDiskCheck: Date = Date.distantPast

    func setPopoverVisible(_ visible: Bool) {
        popoverVisible = visible
        updateTimerState()
    }

    func updateTimerState() {
        if activeWindows || popoverVisible || DesktopWidgetManager.shared.hasActiveWidgets {
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
        let initRes = ProcessorModel.shared.kernelGetUInt64(count: 2, selector: 90)
        guard initRes.count > 0 && initRes[0] == 1 else { return }
        smcDriverLoaded = true

        let cppcRes = ProcessorModel.shared.getCPPCScore()
        cppcSupported = cppcRes.supported
        cppcScores = cppcRes.scores
        cppcScoresEstimated = cppcSupported && (cppcScores.isEmpty || cppcScores.allSatisfy { $0 == 0 })
        print("DEBUG: CPPC Supported = \(cppcSupported), Scores = \(cppcScores), Estimated = \(cppcScoresEstimated)")
        updateRankedPhysicalCores()
        
        cstateAddress = ProcessorModel.shared.getCStateAddress()

        let fansRes = ProcessorModel.shared.kernelGetUInt64(count: 1, selector: 91)
        guard fansRes.count > 0 else { return }
        numFans = Int(fansRes[0])
        
        fanNames.removeAll()
        for i in 0..<numFans {
            fanNames.append(ProcessorModel.shared.kernelGetString(selector: 92, args: [UInt64(i)]))
        }

        fans = (0..<numFans).map {
            FanSnapshot(id: $0, name: fanNames[$0], rpm: 0, throttle: 0, isOverrided: false)
        }
    }

    func restartTimer() {
        timer?.cancel()
        let interval: Double
        if activeWindows || popoverVisible || isAnyWidgetHovered {
            interval = RefreshRateConfig.shared.interval
        } else if DesktopWidgetManager.shared.hasActiveWidgets {
            interval = 2.0 // Slow refresh when widgets are in background to conserve resources
        } else {
            interval = RefreshRateConfig.shared.interval
        }
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
        if !smcDriverLoaded {
            initSMC()
        }

        let numPhysicalCores = ProcessorModel.shared.getNumOfCore()
        let numLogicalCores  = sysInfo.logicalCores > 0 ? sysInfo.logicalCores : numPhysicalCores
        let metric   = ProcessorModel.shared.getMetric(forced: true)
        let loadIndex = ProcessorModel.shared.getLoadIndex()

        guard metric.count > numPhysicalCores + 2 else { return }

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

        let rawGPUTemp = ProcessorModel.shared.getGPUTemp()
        let rawGPUPower = ProcessorModel.shared.getGPUPower()
        let rawGPULoad = ProcessorModel.shared.getGPUUtilization()
        let rawGPUVram = ProcessorModel.shared.getGPUVramUsed()
        let rawGPUFan = ProcessorModel.shared.getGPUFanRPM()
        gpuTempC = Double(rawGPUTemp)
        gpuPowerW = Double(rawGPUPower)
        
        let targetGPULoad = Double(rawGPULoad)
        if gpuLoadPct == 0 && targetGPULoad > 0 {
            gpuLoadPct = targetGPULoad
        } else {
            gpuLoadPct = (gpuLoadPct * 0.8) + (targetGPULoad * 0.2) // EMA for smoothing
        }

        gpuVramUsedBytes = Double(rawGPUVram)
        gpuFanRPM = Double(rawGPUFan)
        ccdTemperatures = ProcessorModel.shared.getCCDTemperatures()

        // Inst Retired: read from getInstructionDelta() like original Power Tool
        let instDelta = ProcessorModel.shared.getInstructionDelta()
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
            if cppcSupported {
                if !cppcScoresEstimated && cppcScores.count > logicalIdx {
                    cppcVal = cppcScores[logicalIdx]
                } else if cppcScoresEstimated {
                    if let r = rankedPhysicalCores.first(where: { $0.id == physicalIdx + 1 }) {
                        cppcVal = r.score
                    }
                }
            }
            
            newCores.append(CoreSnapshot(
                id: logicalIdx,
                freqMHz: freq,
                loadPct: Float(load),
                isLogical: isLogical,
                cppcScore: cppcVal,
                cppcScoreEstimated: cppcScoresEstimated
            ))
        }
        cores = newCores
        
        let totalLoad = newCores.reduce(0.0) { $0 + Double($1.loadPct) }
        cpuLoadAvg = newCores.isEmpty ? 0.0 : (totalLoad / Double(newCores.count))
        ramUsagePct = getRAMUsagePct()
        diskUsagePct = getDiskUsagePct()
        
        let now = Date()
        let diskIO = getDiskIOBytes()
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
        
        if popoverVisible {
            Task.detached(priority: .background) {
                let list = self.fetchTopProcesses()
                await MainActor.run {
                    self.topProcesses = list
                }
            }
        }

        var netUp: Double = 0
        var netDown: Double = 0
        if let netSnap = NetworkStats.shared.update() {
            netUp = netSnap.uploadMBps
            netDown = netSnap.downloadMBps
        }
        self.netUploadMBps = netUp
        self.netDownloadMBps = netDown

        let relTime = Date.timeIntervalSinceReferenceDate - startTime
        
        var firstFanRPM: Double = 0
        if smcDriverLoaded && numFans > 0 {
            let rpms = ProcessorModel.shared.kernelGetUInt64(count: numFans, selector: 93)
            if let firstRpm = rpms.first {
                firstFanRPM = Double(firstRpm)
            }
        }

        let point = TelemetryPoint(
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
        history.append(point)
        if history.count > maxHistoryPoints { history.removeFirst() }

        if smcDriverLoaded && numFans > 0 {
            let rpms  = ProcessorModel.shared.kernelGetUInt64(count: numFans, selector: 93)
            let ctrls = ProcessorModel.shared.kernelGetUInt64(count: numFans, selector: 94)
            for i in 0..<numFans where i < fans.count {
                fans[i].rpm        = rpms.count  > i ? rpms[i]                  : 0
                fans[i].throttle   = ctrls.count > i ? UInt8(ctrls[i] >> 8)     : 0
                fans[i].isOverrided = ctrls.count > i ? (ctrls[i] & 0xff) == 0  : false
            }
        }

        // Background CSV logging
        writeTelemetryToLogFile(point: point)
        
        // System alerts notifications check
        if notificationsEnabled {
            let now = Date()
            
            // 1. Temperature Alerts
            if cpuTempC >= Double(tempAlertThreshold) {
                let shouldAlert = lastTempAlertTime == nil || now.timeIntervalSince(lastTempAlertTime!) >= 60.0
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
                        let shouldAlert = lastPowerAlertTime == nil || now.timeIntervalSince(lastPowerAlertTime!) >= 60.0
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

        speedStepClocks  = ProcessorModel.shared.getValidPStateClocks()
        selectedSpeedStep = ProcessorModel.shared.getPState()
        loadCPUControls()
        
        let swap = getSwapMemoryUsage()
        ramSwapTotalBytes = swap.total
        ramSwapUsedBytes = swap.used
        
        let ipInfo = getLocalIPAddressAndInterface()
        netLocalIP = ipInfo.ip
        netActiveInterface = ipInfo.interface
        
        systemUptimeFormatted = getSystemUptime()
    }

    // Format instruction count with suffix like original: K, M, G, T, P, E
    private func formatInstRetired(_ number: UInt64) -> String {
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
        if UserDefaults.standard.bool(forKey: "has_saved_cppcActiveMode") {
            let active = UserDefaults.standard.bool(forKey: "saved_cppcActiveMode")
            _ = ProcessorModel.shared.setCPPCActiveMode(active: active)
        }
        if UserDefaults.standard.bool(forKey: "has_saved_cppcEPPValue") {
            let epp = UInt8(UserDefaults.standard.integer(forKey: "saved_cppcEPPValue"))
            _ = ProcessorModel.shared.setCPPCEPPValue(epp: epp)
        }
        if UserDefaults.standard.bool(forKey: "has_saved_cpbEnabled") {
            let enabled = UserDefaults.standard.bool(forKey: "saved_cpbEnabled")
            ProcessorModel.shared.setCPB(enabled: enabled)
        }
        if UserDefaults.standard.bool(forKey: "has_saved_ppmEnabled") {
            let enabled = UserDefaults.standard.bool(forKey: "saved_ppmEnabled")
            ProcessorModel.shared.setPPM(enabled: enabled)
        }
        if UserDefaults.standard.bool(forKey: "has_saved_lpmEnabled") {
            let enabled = UserDefaults.standard.bool(forKey: "saved_lpmEnabled")
            ProcessorModel.shared.setLPM(enabled: enabled)
        }
    }

    func loadCPUControls() {
        let cpb = ProcessorModel.shared.getCPB()
        cpbSupported = cpb.count > 0 && cpb[0]
        cpbEnabled   = cpb.count > 1 && cpb[1]
        ppmEnabled   = ProcessorModel.shared.getPPM()
        lpmEnabled   = ProcessorModel.shared.getLPM()
        
        let cppc = ProcessorModel.shared.getCPPCActiveMode()
        cppcActiveMode = cppc.active
        cppcEPPValue = cppc.epp
    }

    func setCPB(enabled: Bool) {
        ProcessorModel.shared.setCPB(enabled: enabled)
        UserDefaults.standard.set(enabled, forKey: "saved_cpbEnabled")
        UserDefaults.standard.set(true, forKey: "has_saved_cpbEnabled")
        loadCPUControls()
    }

    func setPPM(enabled: Bool) {
        ProcessorModel.shared.setPPM(enabled: enabled)
        UserDefaults.standard.set(enabled, forKey: "saved_ppmEnabled")
        UserDefaults.standard.set(true, forKey: "has_saved_ppmEnabled")
        loadCPUControls()
    }

    func setLPM(enabled: Bool) {
        ProcessorModel.shared.setLPM(enabled: enabled)
        UserDefaults.standard.set(enabled, forKey: "saved_lpmEnabled")
        UserDefaults.standard.set(true, forKey: "has_saved_lpmEnabled")
        loadCPUControls()
    }

    func setCPPCActiveMode(active: Bool) {
        _ = ProcessorModel.shared.setCPPCActiveMode(active: active)
        UserDefaults.standard.set(active, forKey: "saved_cppcActiveMode")
        UserDefaults.standard.set(true, forKey: "has_saved_cppcActiveMode")
        loadCPUControls()
    }

    func setCPPCEPPValue(epp: UInt8) {
        _ = ProcessorModel.shared.setCPPCEPPValue(epp: epp)
        UserDefaults.standard.set(Int(epp), forKey: "saved_cppcEPPValue")
        UserDefaults.standard.set(true, forKey: "has_saved_cppcEPPValue")
        loadCPUControls()
    }

    func setSpeedStep(_ index: Int) {
        ProcessorModel.shared.setPState(state: index)
        selectedSpeedStep = index
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
            pStateEditorDirty = false
            loadPStateRows()
            return true
        }
        return false
    }

    func setFanThrottle(fanIndex: Int, throttle: UInt8) {
        guard smcDriverLoaded else { return }
        if ProcessorModel.shared.kernelSetUInt64(selector: 95, args: [UInt64(fanIndex), UInt64(throttle)]) {
            fans[fanIndex].throttle = throttle
        }
    }

    func setFanOverride(fanIndex: Int, overrideEnabled: Bool) {
        guard smcDriverLoaded, !overrideEnabled else { return }
        if ProcessorModel.shared.kernelSetUInt64(selector: 96, args: [UInt64(fanIndex)]) {
            fans[fanIndex].isOverrided = false
        }
    }

    func setAllFansAuto() {
        guard smcDriverLoaded else { return }
        let _ = ProcessorModel.shared.kernelSetUInt64(selector: 97, args: [0])
    }

    func setAllFansTakeOff() {
        guard smcDriverLoaded else { return }
        let _ = ProcessorModel.shared.kernelSetUInt64(selector: 97, args: [1])
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
        let decimal = Locale.current.decimalSeparator ?? "."
        return decimal == "," ? ";" : ","
    }

    private func startLoggingSession() {
        logger.start(path: logFilePath, delimiter: csvDelimiter)
    }
    
    private func stopLoggingSession() {
        logger.stop()
    }

    private func writeTelemetryToLogFile(point: TelemetryPoint) {
        guard isLoggingEnabled else { return }
        
        let delim = csvDelimiter
        let locale = Locale.current
        let dateString = ISO8601DateFormatter().string(from: Date())
        
        let format = [
            "%@", // Timestamp
            "%.3f", // Relative Time (s)
            "%.3f", // CPU Freq Avg (GHz)
            "%.3f", // CPU Freq Max (GHz)
            "%.2f", // CPU Temp (°C)
            "%.2f", // CPU Power (W)
            "%.2f", // GPU Temp (°C)
            "%.2f", // GPU Power (W)
            "%.0f", // GPU Fan (RPM)
            "%.3f", // GPU VRAM (GB)
            "%.1f"  // GPU Load (%)
        ].joined(separator: delim) + "\n"
        
        let line = String(format: format, locale: locale,
                          dateString,
                          point.time,
                          point.cpuFreqGHz,
                          point.cpuFreqMaxGHz,
                          point.cpuTempC,
                          point.cpuWatts,
                          point.gpuTempC,
                          point.gpuWatts,
                          gpuFanRPM,
                          gpuVramUsedBytes / (1024.0 * 1024.0 * 1024.0),
                          gpuLoadPct)
        
        logger.write(line: line)
    }

    func exportHistoryToCSV(url: URL) {
        let delim = csvDelimiter
        let locale = Locale.current
        
        let headers = [
            "Relative Time (s)", "CPU Freq Avg (GHz)", "CPU Freq Max (GHz)",
            "CPU Temp (°C)", "CPU Power (W)", "GPU Temp (°C)", "GPU Power (W)",
            "GPU Fan (RPM)", "GPU VRAM (GB)", "GPU Load (%)"
        ]
        var csvText = headers.joined(separator: delim) + "\n"
        
        let format = [
            "%.3f", // Relative Time (s)
            "%.3f", // CPU Freq Avg (GHz)
            "%.3f", // CPU Freq Max (GHz)
            "%.2f", // CPU Temp (°C)
            "%.2f", // CPU Power (W)
            "%.2f", // GPU Temp (°C)
            "%.2f", // GPU Power (W)
            "%.0f", // GPU Fan (RPM)
            "%.3f", // GPU VRAM (GB)
            "%.1f"  // GPU Load (%)
        ].joined(separator: delim) + "\n"
        
        for point in history {
            csvText += String(format: format, locale: locale,
                              point.time,
                              point.cpuFreqGHz,
                              point.cpuFreqMaxGHz,
                              point.cpuTempC,
                              point.cpuWatts,
                              point.gpuTempC,
                              point.gpuWatts,
                              gpuFanRPM,
                              gpuVramUsedBytes / (1024.0 * 1024.0 * 1024.0),
                              gpuLoadPct)
        }
        
        try? csvText.write(to: url, atomically: true, encoding: .utf8)
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
                
                if maxFreqOverall > 0 && m > 0 {
                    score = UInt8(min(255, Int(round((m / maxFreqOverall) * 255.0))))
                } else {
                    score = 0
                }
            }
            list.append(RankedPhysicalCore(id: physIdx + 1, score: score, rank: 0, isEstimated: !cppcHasReal))
        }
        let sorted = list.sorted { $0.score != $1.score ? $0.score > $1.score : $0.id < $1.id }
        rankedPhysicalCores = sorted.enumerated().map {
            RankedPhysicalCore(id: $1.id, score: $1.score, rank: $0 + 1, isEstimated: $1.isEstimated)
        }
    }
}

// MARK: - CSV Logger Helper Class (Thread-safe & nonisolated to bypass actor deinit constraints)
private class CSVLogger {
    private var fileHandle: FileHandle?
    private let queue = DispatchQueue(label: "wtf.spinach.CSVLogger", qos: .background)
    
    func start(path: String, delimiter: String) {
        queue.async {
            guard !path.isEmpty else { return }
            let fileURL = URL(fileURLWithPath: path)
            
            // Create file if it doesn't exist
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                let headers = [
                    "Timestamp", "Relative Time (s)", "CPU Freq Avg (GHz)", "CPU Freq Max (GHz)",
                    "CPU Temp (°C)", "CPU Power (W)", "GPU Temp (°C)", "GPU Power (W)",
                    "GPU Fan (RPM)", "GPU VRAM (GB)", "GPU Load (%)"
                ]
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