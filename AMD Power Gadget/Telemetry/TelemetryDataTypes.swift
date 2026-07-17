//
//  TelemetryDataTypes.swift
//  AMD Power Gadget
//

import Foundation

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


// MARK: - ProcessInfoRow
struct ProcessInfoRow: Identifiable {
    let id: Int32
    var name: String
    var cpuUsage: Float
}

