//
//  NetworkStats.swift
//  AMD Power Gadget
//
//  Created by Droga (2026) — macOS network counters via in-process sysctl route monitoring
//

import Foundation
import Darwin

struct NetworkSnapshot {
    let timestamp: Date
    let bytesIn: UInt64
    let bytesOut: UInt64
    let uploadMBps: Double
    let downloadMBps: Double
}

class NetworkStats {
    static let shared = NetworkStats()

    private var lastBytesIn: UInt64 = 0
    private var lastBytesOut: UInt64 = 0
    private var lastCheck: Date = Date.distantPast
    
    private let queue = DispatchQueue(label: "com.amdpowergadget.network", qos: .utility)
    private var currentSnapshot: NetworkSnapshot?
    private var physicalInterfaceCache: [UInt32: Bool] = [:]
    private var cacheLastCleared: Date = Date()

    init() {
        // In-process sysctl does not require initialization or background processes
    }
    
    deinit {
        // No background processes to clean up
    }
    
    func start() {
        // No-op: network statistics are sampled on-demand via update()
    }

    func stop() {
        // No-op: no background threads to tear down
    }
    
    func update() -> NetworkSnapshot? {
        return queue.sync {
            if Date().timeIntervalSince(cacheLastCleared) > 30 {
                physicalInterfaceCache.removeAll()
                cacheLastCleared = Date()
            }
            let now = Date()
            
            // Rate limit the sysctl call to once every 200ms to prevent jitter and minimize overhead
            if lastCheck != Date.distantPast && now.timeIntervalSince(lastCheck) < 0.2 {
                return currentSnapshot
            }
            
            // Fetch total bytes from sysctl (summing all physical en* interfaces)
            var bytesIn: UInt64 = 0
            var bytesOut: UInt64 = 0
            
            var mib: [Int32] = [CTL_NET, PF_ROUTE, 0, 0, NET_RT_IFLIST2, 0]
            var len: size_t = 0
            var mibCopy = mib
            
            if sysctl(&mibCopy, 6, nil, &len, nil, 0) == 0 {
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: len)
                defer { buffer.deallocate() }
                
                if sysctl(&mibCopy, 6, buffer, &len, nil, 0) == 0 {
                    var ptr = buffer
                    let end = buffer.advanced(by: len)
                    
                    while ptr < end {
                        let ifm = ptr.withMemoryRebound(to: if_msghdr.self, capacity: 1) { $0.pointee }
                        
                        if ifm.ifm_type == UInt8(RTM_IFINFO2) {
                            let if2m = ptr.withMemoryRebound(to: if_msghdr2.self, capacity: 1) { $0.pointee }
                            let index = UInt32(if2m.ifm_index)
                            
                            var isPhysical = self.physicalInterfaceCache[index]
                            if isPhysical == nil {
                                var nameBuffer = [CChar](repeating: 0, count: 16) // 16 is IF_NAMESIZE
                                if if_indextoname(index, &nameBuffer) != nil {
                                    let ifName = String(cString: nameBuffer)
                                    // Include Ethernet (en0/en1...), bridged (bridge0), bonded (bond0)
                                    // Exclude loopback (lo0), tunnel (utun, llw, ipsec, awdl, gif, stf)
                                    isPhysical = ifName.hasPrefix("en") ||
                                                 ifName.hasPrefix("bridge") ||
                                                 ifName.hasPrefix("bond")
                                } else {
                                    isPhysical = false
                                }
                                self.physicalInterfaceCache[index] = isPhysical
                            }
                            
                            if isPhysical == true {
                                bytesIn += if2m.ifm_data.ifi_ibytes
                                bytesOut += if2m.ifm_data.ifi_obytes
                            }
                        }
                        let msgLen = Int(ifm.ifm_msglen)
                        if msgLen <= 0 || ptr.advanced(by: msgLen) > end {
                            break
                        }
                        ptr = ptr.advanced(by: msgLen)
                    }
                }
            }
            
            if lastCheck == Date.distantPast {
                lastBytesIn = bytesIn
                lastBytesOut = bytesOut
                lastCheck = now
                currentSnapshot = NetworkSnapshot(
                    timestamp: now,
                    bytesIn: bytesIn,
                    bytesOut: bytesOut,
                    uploadMBps: 0,
                    downloadMBps: 0
                )
                return currentSnapshot
            }
            
            let interval = now.timeIntervalSince(lastCheck)
            guard interval > 0.05 else { return currentSnapshot }
            
            // Allow delta even if last was 0 (first real reading after baseline)
            var bytesInDelta: UInt64 = 0
            var bytesOutDelta: UInt64 = 0
            
            if bytesIn >= lastBytesIn {
                bytesInDelta = bytesIn - lastBytesIn
            }
            if bytesOut >= lastBytesOut {
                bytesOutDelta = bytesOut - lastBytesOut
            }
            
            let rawDownload = Double(bytesInDelta) / interval / (1024.0 * 1024.0)
            let rawUpload = Double(bytesOutDelta) / interval / (1024.0 * 1024.0)
            
            var downloadSpeed = rawDownload
            var uploadSpeed = rawUpload
            
            // Clamp noise-floor near zero
            if downloadSpeed < 0.0000009 { downloadSpeed = 0 }
            if uploadSpeed  < 0.0000009 { uploadSpeed  = 0 }
            
            currentSnapshot = NetworkSnapshot(
                timestamp: now,
                bytesIn: bytesIn,
                bytesOut: bytesOut,
                uploadMBps: uploadSpeed,
                downloadMBps: downloadSpeed
            )
            
            lastBytesIn = bytesIn
            lastBytesOut = bytesOut
            lastCheck = now
            
            return currentSnapshot
        }
    }
}
