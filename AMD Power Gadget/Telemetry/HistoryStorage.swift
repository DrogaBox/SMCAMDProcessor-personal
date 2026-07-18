//
// Auto-extracted during Phase 2 restructure
//

import Foundation
import SwiftUI
import Combine

struct HistoryDataPoint: Codable, Identifiable {
    var id: UUID = UUID()
    let timestamp: Date
    let cpuLoad: Double
    let cpuTemp: Double
    let ramUsage: Double
    let gpuTemp: Double
    let gpuLoad: Double
    var cpuWatts: Double? = nil
    var cpuFreqAvg: Double? = nil
    
    var safeCpuWatts: Double { cpuWatts ?? 0.0 }
    var safeCpuFreqAvg: Double { cpuFreqAvg ?? 0.0 }
}

@MainActor
class HistoryManager: ObservableObject {
    static let shared = HistoryManager()
    
    @Published var historyData: [HistoryDataPoint] = []
    
    private let saveURL: URL
    private var timer: Timer?
    private var saveCounter = 0
    
    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        let appDir = appSupport.appendingPathComponent("AMD Power Gadget")
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        saveURL = appDir.appendingPathComponent("telemetry_history.json")
        
        loadData()
        startSampling()
    }
    
    private func loadData() {
        guard let data = try? Data(contentsOf: saveURL) else { return }
        let decoder = JSONDecoder()
        
        // Try decoding as JSON array first for backward compatibility
        if let array = try? decoder.decode([HistoryDataPoint].self, from: data) {
            historyData = array
            pruneOldData()
            rewriteFile() // Convert to JSON Lines format immediately
            return
        }
        
        // Otherwise, decode as JSON Lines
        var loadedPoints: [HistoryDataPoint] = []
        if let content = String(data: data, encoding: .utf8) {
            let lines = content.components(separatedBy: .newlines)
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }
                if let lineData = trimmed.data(using: .utf8),
                   let point = try? decoder.decode(HistoryDataPoint.self, from: lineData) {
                    loadedPoints.append(point)
                }
            }
        }
        historyData = loadedPoints
        pruneOldData()
    }
    
    private func rewriteFile() {
        do {
            let encoder = JSONEncoder()
            var fileData = Data()
            for pt in historyData {
                if let data = try? encoder.encode(pt) {
                    fileData.append(data)
                    if let nl = "\n".data(using: .utf8) {
                        fileData.append(nl)
                    }
                }
            }
            try fileData.write(to: saveURL, options: .atomic)
        } catch {
            NSLog("Failed to rewrite history: %@", error.localizedDescription)
        }
    }
    
    private func appendData(point: HistoryDataPoint) {
        do {
            if !FileManager.default.fileExists(atPath: saveURL.path) {
                rewriteFile()
                return
            }
            let encoder = JSONEncoder()
            let data = try encoder.encode(point)
            let fileHandle = try FileHandle(forWritingTo: saveURL)
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
            if let newline = "\n".data(using: .utf8) {
                fileHandle.write(newline)
            }
            fileHandle.closeFile()
        } catch {
            rewriteFile()
        }
    }
    
    func saveData() {
        pruneOldData()
        saveCounter += 1
        if saveCounter >= 60 {
            rewriteFile()
            saveCounter = 0
        } else {
            if let last = historyData.last {
                appendData(point: last)
            }
        }
    }

    /// Force a full rewrite (language relaunch / app quit paths).
    func flushToDisk() {
        pruneOldData()
        rewriteFile()
        saveCounter = 0
    }
    
    private func pruneOldData() {
        // Keep data for 30 days
        let cutoff = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        historyData.removeAll(where: { $0.timestamp < cutoff })
    }
    
    private func startSampling() {
        // Sample every 60 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.sampleCurrentTelemetry()
        }
    }
    
    func sampleCurrentTelemetry() {
        Task { @MainActor in
            let model = TelemetryModel.shared
            let point = HistoryDataPoint(
                timestamp: Date(),
                cpuLoad: model.cpuLoadAvg,
                cpuTemp: model.cpuTempC,
                ramUsage: model.ramUsagePct,
                gpuTemp: model.gpuTempC,
                gpuLoad: model.gpuLoadPct,
                cpuWatts: model.cpuWatts,
                cpuFreqAvg: model.cpuFreqAvgGHz
            )
            
            self.historyData.append(point)
            self.pruneOldData()
            self.saveData()
        }
    }
    
    nonisolated static func performDownsample(data: [HistoryDataPoint], hours: Int) -> [HistoryDataPoint] {
        let cutoff = Date().addingTimeInterval(Double(-hours * 60 * 60))
        let filtered = data.filter { $0.timestamp >= cutoff }
        
        if hours <= 24 || filtered.isEmpty {
            return filtered
        }
        
        var downsampled: [HistoryDataPoint] = []
        var bucketStart = filtered[0].timestamp
        var sumLoad: Double = 0
        var sumTemp: Double = 0
        var sumRam: Double = 0
        var sumGpuTemp: Double = 0
        var sumGpuLoad: Double = 0
        var sumWatts: Double = 0
        var sumFreq: Double = 0
        var wattsCount: Int = 0
        var freqCount: Int = 0
        var count: Int = 0
        
        for point in filtered {
            if point.timestamp.timeIntervalSince(bucketStart) >= 3600 {
                if count > 0 {
                    downsampled.append(HistoryDataPoint(
                        timestamp: bucketStart.addingTimeInterval(1800),
                        cpuLoad: sumLoad / Double(count),
                        cpuTemp: sumTemp / Double(count),
                        ramUsage: sumRam / Double(count),
                        gpuTemp: sumGpuTemp / Double(count),
                        gpuLoad: sumGpuLoad / Double(count),
                        cpuWatts: wattsCount > 0 ? sumWatts / Double(wattsCount) : nil,
                        cpuFreqAvg: freqCount > 0 ? sumFreq / Double(freqCount) : nil
                    ))
                }
                bucketStart = point.timestamp
                sumLoad = 0; sumTemp = 0; sumRam = 0; sumGpuTemp = 0; sumGpuLoad = 0; sumWatts = 0; sumFreq = 0
                count = 0; wattsCount = 0; freqCount = 0
            }
            
            sumLoad += point.cpuLoad
            sumTemp += point.cpuTemp
            sumRam += point.ramUsage
            sumGpuTemp += point.gpuTemp
            sumGpuLoad += point.gpuLoad
            if let w = point.cpuWatts { sumWatts += w; wattsCount += 1 }
            if let f = point.cpuFreqAvg { sumFreq += f; freqCount += 1 }
            count += 1
        }
        
        if count > 0 {
            downsampled.append(HistoryDataPoint(
                timestamp: bucketStart.addingTimeInterval(1800),
                cpuLoad: sumLoad / Double(count),
                cpuTemp: sumTemp / Double(count),
                ramUsage: sumRam / Double(count),
                gpuTemp: sumGpuTemp / Double(count),
                gpuLoad: sumGpuLoad / Double(count),
                cpuWatts: wattsCount > 0 ? sumWatts / Double(wattsCount) : nil,
                cpuFreqAvg: freqCount > 0 ? sumFreq / Double(freqCount) : nil
            ))
        }
        
        return downsampled
    }
    
    func downsampledData(for hours: Int) -> [HistoryDataPoint] {
        return Self.performDownsample(data: historyData, hours: hours)
    }
}

