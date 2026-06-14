//
//  TelemetryModel.swift
//  AMD Power Gadget
//
//  Created by Droga (2026) — SwiftUI Tahoe Redesign
//

import SwiftUI
import Combine

// MARK: - Data Structures

struct CoreSnapshot: Identifiable {
    let id: Int
    var freqMHz: Float
    var loadPct: Float
    var isLogical: Bool
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

// MARK: - TelemetryModel

@MainActor
final class TelemetryModel: ObservableObject {

    @Published var cpuFreqAvgGHz: Double = 0
    @Published var cpuFreqMaxGHz: Double = 0
    @Published var cpuTempC: Double = 0
    @Published var cpuWatts: Double = 0
    @Published var gpuTempC: Double = 0
    @Published var gpuPowerW: Double = 0
    @Published var instRetiredFormatted: String = "0"
    @Published var netUploadMBps: Double = 0
    @Published var netDownloadMBps: Double = 0

    @Published var cores: [CoreSnapshot] = []
    @Published var fans: [FanSnapshot] = []
    @Published var history: [TelemetryPoint] = []

    @Published var selectedSpeedStep: Int = 0
    @Published var speedStepClocks: [Float] = []

    @Published var cpbSupported: Bool = false
    @Published var cpbEnabled: Bool = false
    @Published var ppmEnabled: Bool = false
    @Published var lpmEnabled: Bool = false

    @Published var pStateRows: [PStateRow] = []
    @Published var pStateEditorDirty: Bool = false

    @Published var smcDriverLoaded: Bool = false
    @Published var sysInfo: SystemInfo = SystemInfo()

    private var timer: AnyCancellable?
    private let startTime: Double = Date.timeIntervalSinceReferenceDate
    private let maxHistoryPoints = 120

    private var numFans = 0
    private var fanNames: [String] = []

    // Inst Retired accumulation (like original Power Tool) — resets display every ~1 second
    private var instAccumulated: UInt64 = 0
    private var instElapsedTime: Double = 0.0

    init() {
        buildSystemInfo()
        speedStepClocks = ProcessorModel.shared.getVaildPStateClocks()
        selectedSpeedStep = ProcessorModel.shared.getPState()

        initSMC()
        loadPStateRows()
        loadCPUControls()
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
            info.boardVendor = pm.boardVender
        }
        info.gpuModel = pm.systemConfig["gpu"] ?? ""

        if let memStr = pm.systemConfig["mem"], let memMB = Int(memStr) {
            info.ramGB = memMB / 1024
        }
        if let rsStr = pm.systemConfig["rs"], let rsGB = Int(rsStr) {
            info.storageGB = rsGB / 1024
        }

        sysInfo = info
    }

    private func initSMC() {
        let initRes = ProcessorModel.shared.kernelGetUInt64(count: 2, selector: 90)
        guard initRes.count > 0 && initRes[0] == 1 else { return }
        smcDriverLoaded = true

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
        let interval = RefreshRateConfig.shared.interval
        timer = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.sample() }
    }

    @objc private func handleActiveWindowsChanged(_ notification: Notification) {
        if let active = notification.object as? Bool {
            if active {
                restartTimer()
            } else {
                timer?.cancel()
                timer = nil
            }
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
        gpuTempC = Double(rawGPUTemp)
        gpuPowerW = Double(rawGPUPower)

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

        var newCores: [CoreSnapshot] = []
        for logicalIdx in 0..<numLogicalCores {
            let physicalIdx = logicalIdx % numPhysicalCores
            let freq = freqsMHz[physicalIdx]
            let load = (loadIndex.count > logicalIdx) ? loadIndex[logicalIdx] * 100.0 : 0.0
            let isLogical = logicalIdx >= numPhysicalCores
            newCores.append(CoreSnapshot(
                id: logicalIdx,
                freqMHz: freq,
                loadPct: Float(load),
                isLogical: isLogical
            ))
        }
        cores = newCores

        var netUp: Double = 0
        var netDown: Double = 0
        if let netSnap = NetworkStats.shared.update() {
            netUp = netSnap.uploadMBps
            netDown = netSnap.downloadMBps
        }
        self.netUploadMBps = netUp
        self.netDownloadMBps = netDown

        let relTime = Date.timeIntervalSinceReferenceDate - startTime
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
            netDownloadMBps: netDown
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

        speedStepClocks  = ProcessorModel.shared.getVaildPStateClocks()
        selectedSpeedStep = ProcessorModel.shared.getPState()
        loadCPUControls()
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

    func loadCPUControls() {
        let cpb = ProcessorModel.shared.getCPB()
        cpbSupported = cpb.count > 0 && cpb[0]
        cpbEnabled   = cpb.count > 1 && cpb[1]
        ppmEnabled   = ProcessorModel.shared.getPPM()
        lpmEnabled   = ProcessorModel.shared.getLPM()
    }

    func setCPB(enabled: Bool) {
        ProcessorModel.shared.setCPB(enabled: enabled)
        loadCPUControls()
    }

    func setPPM(enabled: Bool) {
        ProcessorModel.shared.setPPM(enabled: enabled)
        loadCPUControls()
    }

    func setLPM(enabled: Bool) {
        ProcessorModel.shared.setLPM(enabled: enabled)
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
        pStateRows = arr.enumerated().map { PStateRow.from(raw: $0.element, index: $0.offset) }
        pStateEditorDirty = true
    }
}