import Foundation
import IOKit
import SystemConfiguration
import AppKit

var shouldExit = false

// Struct layout matching AMDRyzenCPUPowerManagement CPUSensorPacket structure
struct CPUSensorPacket {
    var packagePowerW: Float = 0
    var packageTempC: Float = 0
    var numLogicalCores: UInt32 = 0
    var ccdCount: UInt32 = 0
    var ccdTemperatures: (Float, Float, Float, Float, Float, Float, Float, Float) = (0,0,0,0,0,0,0,0)
    var coreFrequenciesMHz: (
        Float, Float, Float, Float, Float, Float, Float, Float,
        Float, Float, Float, Float, Float, Float, Float, Float,
        Float, Float, Float, Float, Float, Float, Float, Float,
        Float, Float, Float, Float, Float, Float, Float, Float,
        Float, Float, Float, Float, Float, Float, Float, Float,
        Float, Float, Float, Float, Float, Float, Float, Float,
        Float, Float, Float, Float, Float, Float, Float, Float,
        Float, Float, Float, Float, Float, Float, Float, Float
    ) = (
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    )
}

struct HistoryDataPoint: Codable {
    var id: UUID = UUID()
    let timestamp: Date
    let cpuLoad: Double
    let cpuTemp: Double
    let ramUsage: Double
    let gpuTemp: Double
    let gpuLoad: Double
    var cpuWatts: Double? = nil
    var cpuFreqAvg: Double? = nil
}

// Global CPU load history
var previousCpuLoadInfo: [processor_cpu_load_info] = []

func getConsoleUserHomeDirectory() -> URL? {
    var uid: uid_t = 0
    var gid: gid_t = 0
    guard let userRef = SCDynamicStoreCopyConsoleUser(nil, &uid, &gid) else {
        return nil
    }
    let username = userRef as String
    if username == "loginwindow" || username.isEmpty {
        return nil
    }
    return URL(fileURLWithPath: "/Users/\(username)")
}

func isAppRunning() -> Bool {
    return !NSRunningApplication.runningApplications(withBundleIdentifier: "wtf.spinach.AMD-Power-Gadget").isEmpty
}

func getRAMUsagePct() -> Double {
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

func getGPUStat(key: String) -> Double {
    var iter: io_iterator_t = 0
    let err = IOServiceGetMatchingServices(kIOMainPortDefault,
                                          IOServiceMatching("IOAccelerator"), &iter)
    if err != kIOReturnSuccess { return 0 }
    defer { IOObjectRelease(iter) }

    while true {
        let reg = IOIteratorNext(iter)
        if reg == 0 { break }
        defer { IOObjectRelease(reg) }

        if let dict = IORegistryEntryCreateCFProperty(reg, "PerformanceStatistics" as CFString,
                                                     kCFAllocatorDefault, 0)?.takeRetainedValue() as? [String: Any] {
            if let v = dict[key] as? NSNumber { return v.doubleValue }
            if let v = dict[key] as? Int      { return Double(v) }
        }
    }
    return 0
}

func getCPULoadPct() -> Double {
    var numCPUs: mach_msg_type_number_t = 0
    var infoArray: processor_info_array_t?
    var infoCount: mach_msg_type_number_t = 0
    
    let kr = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUs, &infoArray, &infoCount)
    guard kr == KERN_SUCCESS, let info = infoArray else {
        return 0.0
    }
    
    let count = Int(numCPUs)
    var totalLoad: Double = 0.0
    var activeCoresCount = 0
    
    let cpuLoadData = info.withMemoryRebound(to: processor_cpu_load_info.self, capacity: count) { $0 }
    
    defer {
        let size = vm_size_t(infoCount) * vm_size_t(MemoryLayout<integer_t>.size)
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), size)
    }
    
    if previousCpuLoadInfo.count == count {
        for i in 0..<count {
            let prev = previousCpuLoadInfo[i]
            let curr = cpuLoadData[i]
            
            let userDiff   = max(0.0, Double(curr.cpu_ticks.0 &- prev.cpu_ticks.0))
            let systemDiff = max(0.0, Double(curr.cpu_ticks.1 &- prev.cpu_ticks.1))
            let idleDiff   = max(0.0, Double(curr.cpu_ticks.2 &- prev.cpu_ticks.2))
            let niceDiff   = max(0.0, Double(curr.cpu_ticks.3 &- prev.cpu_ticks.3))
            
            let total = userDiff + systemDiff + idleDiff + niceDiff
            if total > 0 {
                let load = (userDiff + systemDiff + niceDiff) / total
                totalLoad += load * 100.0
                activeCoresCount += 1
            }
        }
    }
    
    // Save current stats for next diff
    previousCpuLoadInfo = (0..<count).map { cpuLoadData[$0] }
    
    return activeCoresCount > 0 ? (totalLoad / Double(activeCoresCount)) : 0.0
}

func getKextConnection() -> io_connect_t {
    var connect: io_connect_t = 0
    let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AMDRyzenCPUPowerManagement"))
    guard service != 0 else { return 0 }
    defer { IOObjectRelease(service) }
    let kr = IOServiceOpen(service, mach_task_self_, 0, &connect)
    return kr == KERN_SUCCESS ? connect : 0
}

func pruneOldData(fileURL: URL) {
    guard let filePointer = fopen(fileURL.path, "r") else { return }
    
    let tempURL = fileURL.deletingLastPathComponent().appendingPathComponent("telemetry_history_tmp.json")
    guard let writePointer = fopen(tempURL.path, "w") else {
        fclose(filePointer)
        return
    }
    
    let decoder = JSONDecoder()
    let cutoff = Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days
    
    var lineBuffer = [CChar](repeating: 0, count: 4096)
    while true {
        guard fgets(&lineBuffer, Int32(lineBuffer.count), filePointer) != nil else {
            break
        }
        let lineStr = String(cString: lineBuffer).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !lineStr.isEmpty else { continue }
        
        if let lineData = lineStr.data(using: .utf8),
           let point = try? decoder.decode(HistoryDataPoint.self, from: lineData) {
            if point.timestamp >= cutoff {
                fputs(lineStr + "\n", writePointer)
            }
        }
    }
    
    fclose(filePointer)
    fclose(writePointer)
    
    // Replace old file with pruned temp file atomically
    _ = try? FileManager.default.removeItem(at: fileURL)
    _ = try? FileManager.default.moveItem(at: tempURL, to: fileURL)
}

func appendTelemetryPoint(point: HistoryDataPoint, fileURL: URL) {
    do {
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            let encoder = JSONEncoder()
            let data = try encoder.encode(point)
            var fileData = Data()
            fileData.append(data)
            fileData.append("\n".data(using: .utf8)!)
            try fileData.write(to: fileURL, options: .atomic)
            return
        }
        let encoder = JSONEncoder()
        let data = try encoder.encode(point)
        let fileHandle = try FileHandle(forWritingTo: fileURL)
        fileHandle.seekToEndOfFile()
        fileHandle.write(data)
        if let newline = "\n".data(using: .utf8) {
            fileHandle.write(newline)
        }
        fileHandle.closeFile()
    } catch {
        print("Failed to append telemetry point: \(error)")
    }
}

func main() {
    print("AMD Telemetry Daemon started.")
    
    // Register signal handlers for clean launchd lifecycle termination
    signal(SIGTERM) { _ in
        shouldExit = true
    }
    signal(SIGINT) { _ in
        shouldExit = true
    }
    
    // Initial CPU load sample to establish baseline for subsequent diffs
    _ = getCPULoadPct()
    
    var lastPruneDate = Date()
    
    while !shouldExit {
        // Sleep in 1-second increments to allow immediate signal response
        for _ in 0..<60 {
            if shouldExit { break }
            Thread.sleep(forTimeInterval: 1.0)
        }
        
        if shouldExit {
            break
        }
        
        // Skip logging if the GUI application is currently running (it manages its own logging)
        if isAppRunning() {
            continue
        }
        
        guard let userHome = getConsoleUserHomeDirectory() else {
            continue
        }
        
        let appDir = userHome.appendingPathComponent("Library/Application Support/AMD Power Gadget")
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        let fileURL = appDir.appendingPathComponent("telemetry_history.json")
        
        // Connect to Kext
        let connect = getKextConnection()
        guard connect != 0 else {
            print("Kext AMDRyzenCPUPowerManagement is not loaded or unreachable.")
            continue
        }
        
        var packet = CPUSensorPacket()
        var outputSize = MemoryLayout<CPUSensorPacket>.size
        let kr = IOConnectCallMethod(connect, 100, nil, 0, nil, 0, nil, nil, &packet, &outputSize)
        IOServiceClose(connect)
        
        guard kr == KERN_SUCCESS else {
            print("Failed to query structured telemetry from Kext.")
            continue
        }
        
        // Process CPU frequencies to get the average
        let numCores = Int(packet.numLogicalCores)
        var freqSum: Double = 0
        
        let rawFreqArray = [
            packet.coreFrequenciesMHz.0, packet.coreFrequenciesMHz.1, packet.coreFrequenciesMHz.2, packet.coreFrequenciesMHz.3,
            packet.coreFrequenciesMHz.4, packet.coreFrequenciesMHz.5, packet.coreFrequenciesMHz.6, packet.coreFrequenciesMHz.7,
            packet.coreFrequenciesMHz.8, packet.coreFrequenciesMHz.9, packet.coreFrequenciesMHz.10, packet.coreFrequenciesMHz.11,
            packet.coreFrequenciesMHz.12, packet.coreFrequenciesMHz.13, packet.coreFrequenciesMHz.14, packet.coreFrequenciesMHz.15,
            packet.coreFrequenciesMHz.16, packet.coreFrequenciesMHz.17, packet.coreFrequenciesMHz.18, packet.coreFrequenciesMHz.19,
            packet.coreFrequenciesMHz.20, packet.coreFrequenciesMHz.21, packet.coreFrequenciesMHz.22, packet.coreFrequenciesMHz.23,
            packet.coreFrequenciesMHz.24, packet.coreFrequenciesMHz.25, packet.coreFrequenciesMHz.26, packet.coreFrequenciesMHz.27,
            packet.coreFrequenciesMHz.28, packet.coreFrequenciesMHz.29, packet.coreFrequenciesMHz.30, packet.coreFrequenciesMHz.31,
            packet.coreFrequenciesMHz.32, packet.coreFrequenciesMHz.33, packet.coreFrequenciesMHz.34, packet.coreFrequenciesMHz.35,
            packet.coreFrequenciesMHz.36, packet.coreFrequenciesMHz.37, packet.coreFrequenciesMHz.38, packet.coreFrequenciesMHz.39,
            packet.coreFrequenciesMHz.40, packet.coreFrequenciesMHz.41, packet.coreFrequenciesMHz.42, packet.coreFrequenciesMHz.43,
            packet.coreFrequenciesMHz.44, packet.coreFrequenciesMHz.45, packet.coreFrequenciesMHz.46, packet.coreFrequenciesMHz.47,
            packet.coreFrequenciesMHz.48, packet.coreFrequenciesMHz.49, packet.coreFrequenciesMHz.50, packet.coreFrequenciesMHz.51,
            packet.coreFrequenciesMHz.52, packet.coreFrequenciesMHz.53, packet.coreFrequenciesMHz.54, packet.coreFrequenciesMHz.55,
            packet.coreFrequenciesMHz.56, packet.coreFrequenciesMHz.57, packet.coreFrequenciesMHz.58, packet.coreFrequenciesMHz.59,
            packet.coreFrequenciesMHz.60, packet.coreFrequenciesMHz.61, packet.coreFrequenciesMHz.62, packet.coreFrequenciesMHz.63
        ]
        
        for i in 0..<min(numCores, 64) {
            freqSum += Double(rawFreqArray[i])
        }
        let avgFreqGHz = numCores > 0 ? (freqSum / (1000.0 * Double(numCores))) : 0.0
        
        // Gather local host statistics
        let cpuLoad = getCPULoadPct()
        let ramUsage = getRAMUsagePct()
        
        // Gather GPU statistics
        let gpuTemp = getGPUStat(key: "Temperature(C)")
        let gpuLoad = getGPUStat(key: "Device Utilization %")
        
        let point = HistoryDataPoint(
            timestamp: Date(),
            cpuLoad: cpuLoad,
            cpuTemp: Double(packet.packageTempC),
            ramUsage: ramUsage,
            gpuTemp: gpuTemp,
            gpuLoad: gpuLoad,
            cpuWatts: Double(packet.packagePowerW),
            cpuFreqAvg: avgFreqGHz
        )
        
        appendTelemetryPoint(point: point, fileURL: fileURL)
        
        // Prune older files once every 24 hours
        if Date().timeIntervalSince(lastPruneDate) >= 86400.0 {
            pruneOldData(fileURL: fileURL)
            lastPruneDate = Date()
        }
    }
    print("AMD Telemetry Daemon terminating cleanly.")
}

main()
