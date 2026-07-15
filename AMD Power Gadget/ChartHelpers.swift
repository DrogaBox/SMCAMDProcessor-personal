//
//  ChartHelpers.swift
//  AMD Power Gadget
//
//  Global chart & formatting helpers extracted from duplicated private implementations.
//

import Foundation

// MARK: - Network Speed Formatter

/// Converts a network speed in MB/s to a human-readable string (MB/s, KB/s, or "0 KB/s").
/// - Parameter mbps: Speed in megabytes per second.
/// - Returns: Formatted string like "12.3 MB/s" or "456.7 KB/s".
func formatSpeed(_ mbps: Double) -> String {
    let absMbps = abs(mbps)
    let bytesPerSec = absMbps * 1024.0 * 1024.0
    if bytesPerSec >= 1024.0 * 1024.0 {
        let val = bytesPerSec / (1024.0 * 1024.0)
        return String(format: "%.1f MB/s", locale: Locale.current, val)
    } else if bytesPerSec >= 1024.0 {
        let val = bytesPerSec / 1024.0
        return String(format: "%.1f KB/s", locale: Locale.current, val)
    } else if bytesPerSec >= 1.0 {
        let val = bytesPerSec / 1024.0
        return String(format: "%.2f KB/s", locale: Locale.current, val)
    } else {
        return "0 KB/s"
    }
}

// MARK: - Byte Count Formatter

/// Converts a byte count to a human-readable string (GB, MB, KB, or B).
/// - Parameter bytes: Number of bytes.
/// - Returns: Formatted string like "2.5 GB" or "128.0 MB".
func formatBytes(_ bytes: Double) -> String {
    if bytes >= 1024.0 * 1024.0 * 1024.0 {
        return String(format: "%.1f GB", bytes / (1024.0 * 1024.0 * 1024.0))
    } else if bytes >= 1024.0 * 1024.0 {
        return String(format: "%.1f MB", bytes / (1024.0 * 1024.0))
    } else if bytes >= 1024.0 {
        return String(format: "%.1f KB", bytes / 1024.0)
    } else {
        return String(format: "%.0f B", bytes)
    }
}
