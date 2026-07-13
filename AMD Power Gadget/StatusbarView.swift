//
//  StatusbarView.swift
//  AMD Power Gadget
//
//  Extracted from StatusbarController.swift (2026) — Menu Bar Drawing
//

import Cocoa
import SwiftUI

class StatusbarView: NSView {

    var meanFreq: Float = 0
    var maxFreq: Float = 0
    var temp: Float = 0
    var pwr: Float = 0
    var gpuTemp: Float = 0
    var gpuPwr: Float = 0
    var gpuFanRPM: Float = 0
    var gpuVram: Double = 0
    var fanRPM: UInt64 = 0
    var memoryUsed: Float = 0
    var totalMemory: String = "0G"
    var netUpload: Double = 0
    var netDownload: Double = 0

    var compactLabel: [NSAttributedString.Key : NSObject]?
    var compactValue: [NSAttributedString.Key : NSObject]?

    func setup() {
        let compactLH: CGFloat = 6

        let p = NSMutableParagraphStyle()
        p.minimumLineHeight = compactLH
        p.maximumLineHeight = compactLH

        compactLabel = [
            NSAttributedString.Key.font: NSFont(name: "Monaco", size: 7.2) ?? NSFont.monospacedSystemFont(ofSize: 7.2, weight: .regular),
            NSAttributedString.Key.foregroundColor: NSColor.labelColor,
            NSAttributedString.Key.paragraphStyle: p
        ]

        compactValue = [
            NSAttributedString.Key.font: NSFont.systemFont(ofSize: 9, weight: .semibold),
            NSAttributedString.Key.foregroundColor: NSColor.labelColor,
        ]
    }

    override func draw(_ dirtyRect: NSRect) {
        let cfg = MenuBarConfig.shared
        var x: CGFloat = 2

        // CPU column
        if cfg.showCPU {
            let maxFr = String(format: "%.1f", maxFreq * 0.001)
            let avgFr = String(format: "%.1f", meanFreq * 0.001)
            let cpuColor: NSColor = .labelColor
            
            if cfg.showMaxFreqOnly {
                drawCompactSingle(label: "C\nP\nU", val: "\(maxFr)G", color: cpuColor, x: x)
                x += 46
            } else {
                drawCompactDoubleColored(label: "C\nP\nU", up: "\(maxFr)Ghz", upColor: cpuColor, down: "\(avgFr)Ghz", downColor: .labelColor, x: x)
                x += 54
            }
        }

        // TEMP column: CPU temp + GPU temp (if enabled)
        if cfg.showTemp {
            var cTemp = temp
            var gTemp = gpuTemp
            var unitStr = "º"
            
            if cfg.useFahrenheit {
                cTemp = temp * 9.0 / 5.0 + 32.0
                gTemp = gpuTemp * 9.0 / 5.0 + 32.0
                unitStr = "F"
            }
            
            let cTempStr = String(format: "C:%.0f\(unitStr)", cTemp)
            let gTempStr = cfg.showGPU && cfg.showGPUtemp ? String(format: "G:%.0f\(unitStr)", gTemp) : ""
            
            var cColor: NSColor = .labelColor
            var gColor: NSColor = .labelColor
            
            if cfg.enableColorAlerts {
                let alertColor = StatusbarView.getNetColor(index: cfg.tempColorIdx)
                if temp >= Float(cfg.tempThreshold) {
                    cColor = alertColor
                }
                if gpuTemp >= Float(cfg.tempThreshold) {
                    gColor = alertColor
                }
            }
            
            drawCompactDoubleColored(label: "T\nM\nP", up: cTempStr, upColor: cColor, down: gTempStr.isEmpty ? "—" : gTempStr, downColor: gColor, x: x)
            x += 54
        }

        // PWR column: CPU watts + GPU watts (if enabled)
        if cfg.showPower {
            let cPwr = String(format: "C:%.0fW", pwr)
            let gPwr = cfg.showGPU && cfg.showGPUpwr ? String(format: "G:%.0fW", gpuPwr) : ""
            
            let cColor: NSColor = .labelColor
            let gColor: NSColor = .labelColor
            
            drawCompactDoubleColored(label: "P\nW\nR", up: cPwr, upColor: cColor, down: gPwr.isEmpty ? "—" : gPwr, downColor: gColor, x: x)
            x += 54
        }

        // FAN column
        if cfg.showFanRPM {
            let fan = String(fanRPM)
            let fanColor: NSColor = .labelColor
            
            if cfg.showGPU && cfg.showGPUfan {
                let gFanStr = String(format: "G:%.0f", gpuFanRPM)
                drawCompactDoubleColored(label: "F\nA\nN", up: "C:\(fan)", upColor: fanColor, down: gFanStr, downColor: .labelColor, x: x)
            } else {
                drawCompactDoubleColored(label: "F\nA\nN", up: fan, upColor: fanColor, down: "RPM", downColor: .labelColor, x: x)
            }
            x += 54
        }

        // MEMORY column
        if cfg.showMemory {
            let used = String(format: "%.1fG", memoryUsed)
            let memColor: NSColor = .labelColor
            
            if cfg.showGPU && cfg.showGPUvram {
                let vramGB = gpuVram / (1024.0 * 1024.0 * 1024.0)
                let vramStr = String(format: "G:%.1fG", vramGB)
                drawCompactDoubleColored(label: "M\nE\nM", up: "S:\(used)", upColor: memColor, down: vramStr, downColor: .labelColor, x: x)
            } else {
                drawCompactDoubleColored(label: "M\nE\nM", up: used, upColor: memColor, down: totalMemory, downColor: .labelColor, x: x)
            }
            x += 54
        }

        // NETWORK column
        if cfg.showNetwork {
            let labelStr = NSAttributedString(string: "N\nE\nT", attributes: compactLabel)
            labelStr.draw(in: NSRect(x: x, y: -4.5, width: 7, height: frame.height))

            let formatSpeed: (Double) -> String = { mbps in
                let bytesPerSec = mbps * 1024.0 * 1024.0
                if bytesPerSec >= 1024.0 * 1024.0 {
                    let val = bytesPerSec / (1024.0 * 1024.0)
                    return String(format: "%.1f MB/s", locale: Locale.current, val)
                } else if bytesPerSec >= 1.0 {
                    let val = bytesPerSec / 1024.0
                    if val < 1.0 {
                        return String(format: "%.3f KB/s", locale: Locale.current, val)
                    } else {
                        return String(format: "%.1f KB/s", locale: Locale.current, val)
                    }
                } else {
                    return "0 KB/s"
                }
            }

            let upSpeedStr = formatSpeed(netUpload)
            let downSpeedStr = formatSpeed(netDownload)

            // Determine active colors for arrows
            // If upload/download is active (e.g. > 1 Byte/s = 0.0000009 MB/s), color the arrow with active color
            let activeColor = StatusbarView.getNetColor(index: cfg.netColorIdx)
            let upArrowColor = (netUpload > 0.0000009) ? activeColor : NSColor.secondaryLabelColor
            let downArrowColor = (netDownload > 0.0000009) ? activeColor : NSColor.secondaryLabelColor

            // Speed text color is standard labelColor
            let speedTextColor = NSColor.labelColor

            // Draw Upload row
            let upArrowAttr: [NSAttributedString.Key : NSObject] = [
                .font: NSFont.systemFont(ofSize: 9, weight: .bold),
                .foregroundColor: upArrowColor
            ]
            let upSpeedAttr: [NSAttributedString.Key : NSObject] = [
                .font: NSFont.systemFont(ofSize: 9, weight: .semibold),
                .foregroundColor: speedTextColor
            ]

            let upArrowNS = NSAttributedString(string: "↑", attributes: upArrowAttr)
            let upSpeedNS = NSAttributedString(string: upSpeedStr, attributes: upSpeedAttr)

            upArrowNS.draw(at: NSPoint(x: x + 10, y: 10))
            upSpeedNS.draw(at: NSPoint(x: x + 18, y: 10))

            // Draw Download row
            let downArrowAttr: [NSAttributedString.Key : NSObject] = [
                .font: NSFont.systemFont(ofSize: 9, weight: .bold),
                .foregroundColor: downArrowColor
            ]
            let downSpeedAttr: [NSAttributedString.Key : NSObject] = [
                .font: NSFont.systemFont(ofSize: 9, weight: .semibold),
                .foregroundColor: speedTextColor
            ]

            let downArrowNS = NSAttributedString(string: "↓", attributes: downArrowAttr)
            let downSpeedNS = NSAttributedString(string: downSpeedStr, attributes: downSpeedAttr)

            downArrowNS.draw(at: NSPoint(x: x + 10, y: 0))
            downSpeedNS.draw(at: NSPoint(x: x + 18, y: 0))

            x += 68
        }

    }

    func drawCompactDouble(label: String, up: String, down: String, x: CGFloat) {
        drawCompactDoubleColored(label: label, up: up, upColor: .labelColor, down: down, downColor: .labelColor, x: x)
    }

    func drawCompactDoubleColored(label: String, up: String, upColor: NSColor, down: String, downColor: NSColor, x: CGFloat) {
        let labelStr = NSAttributedString(string: label, attributes: compactLabel)
        labelStr.draw(in: NSRect(x: x, y: -4.5, width: 7, height: frame.height))

        let upAttributes: [NSAttributedString.Key : NSObject] = [
            .font: NSFont.systemFont(ofSize: 9, weight: .semibold),
            .foregroundColor: upColor
        ]
        let upStr = NSAttributedString(string: up, attributes: upAttributes)
        upStr.draw(at: NSPoint(x: x + 12, y: 10))

        let downAttributes: [NSAttributedString.Key : NSObject] = [
            .font: NSFont.systemFont(ofSize: 9, weight: .semibold),
            .foregroundColor: downColor
        ]
        let downStr = NSAttributedString(string: down, attributes: downAttributes)
        downStr.draw(at: NSPoint(x: x + 12, y: 0))
    }

    func drawCompactSingle(label: String, val: String, color: NSColor, x: CGFloat) {
        let labelStr = NSAttributedString(string: label, attributes: compactLabel)
        labelStr.draw(in: NSRect(x: x, y: -4.5, width: 7, height: frame.height))

        let valAttributes: [NSAttributedString.Key : NSObject] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .bold),
            .foregroundColor: color
        ]
        let valStr = NSAttributedString(string: val, attributes: valAttributes)
        valStr.draw(at: NSPoint(x: x + 10, y: 3))
    }
    static func getNetColor(index: Int) -> NSColor {
        switch index {
        case 0: return .systemGreen
        case 1: return .systemBlue
        case 2: return .systemOrange
        case 3: return .systemRed
        case 4: return .systemPurple
        case 5: return .systemPink
        case 6: return .systemTeal
        default: return .systemGreen
        }
    }
}
