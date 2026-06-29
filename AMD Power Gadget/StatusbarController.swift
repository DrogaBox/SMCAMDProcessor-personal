//
//  MenubarController.swift
//  AMD Power Gadget
//
//  Created by trulyspinach on 7/29/21.
//  Modified by Droga (2026) — Compact classic layout + configurable items
//

import Cocoa
import SwiftUI
import Charts

// MARK: - Refresh Rate Config
class RefreshRateConfig: ObservableObject {
    static let shared = RefreshRateConfig()
    private let ud = UserDefaults.standard

    @Published var interval: Double = 0.7 {
        didSet {
            ud.set(interval, forKey: "refresh_interval")
        }
    }

    init() {
        if ud.object(forKey: "refresh_interval") == nil {
            interval = 0.7
            ud.set(0.7, forKey: "refresh_interval")
        } else {
            interval = max(0.1, min(5.0, ud.double(forKey: "refresh_interval")))
        }
    }
}

// MARK: - Menu Bar Configuration (persisted via UserDefaults)
struct MenuBarConfig {
    static var shared = MenuBarConfig()

    var showCPU:    Bool { get { ud.bool(forKey: "mb_showCPU")    } set { ud.set(newValue, forKey: "mb_showCPU")    } }
    var showTemp:   Bool { get { ud.bool(forKey: "mb_showTemp")   } set { ud.set(newValue, forKey: "mb_showTemp")   } }
    var showPower:  Bool { get { ud.bool(forKey: "mb_showPower")  } set { ud.set(newValue, forKey: "mb_showPower")  } }
    var showGPU:    Bool { get { ud.bool(forKey: "mb_showGPU")    } set { ud.set(newValue, forKey: "mb_showGPU")    } }
    var showGPUtemp:Bool { get { ud.bool(forKey: "mb_showGPUtemp")} set { ud.set(newValue, forKey: "mb_showGPUtemp")} }
    var showGPUpwr: Bool { get { ud.bool(forKey: "mb_showGPUpwr") } set { ud.set(newValue, forKey: "mb_showGPUpwr") } }
    var showGPUvram:Bool { get { ud.bool(forKey: "mb_showGPUvram")} set { ud.set(newValue, forKey: "mb_showGPUvram")} }
    var showGPUfan: Bool { get { ud.bool(forKey: "mb_showGPUfan") } set { ud.set(newValue, forKey: "mb_showGPUfan") } }

    var showFanRPM:  Bool { get { ud.bool(forKey: "mb_showFanRPM") } set { ud.set(newValue, forKey: "mb_showFanRPM") } }
    var fanIndex:    Int  { get { ud.integer(forKey: "mb_fanIdx")   } set { ud.set(newValue, forKey: "mb_fanIdx")   } }
    var showMemory:  Bool { get { ud.bool(forKey: "mb_showMem")    } set { ud.set(newValue, forKey: "mb_showMem")    } }
    var showNetwork: Bool { get { ud.bool(forKey: "mb_showNet")    } set { ud.set(newValue, forKey: "mb_showNet")    } }
    var netColorIdx: Int  { get { ud.integer(forKey: "mb_netColorIdx") } set { ud.set(newValue, forKey: "mb_netColorIdx") } }

    // Creative features
    var enableColorAlerts: Bool { get { ud.bool(forKey: "mb_enableColorAlerts") } set { ud.set(newValue, forKey: "mb_enableColorAlerts") } }
    var showMaxFreqOnly:  Bool { get { ud.bool(forKey: "mb_showMaxFreqOnly")  } set { ud.set(newValue, forKey: "mb_showMaxFreqOnly")  } }
    var useFahrenheit:    Bool { get { ud.bool(forKey: "mb_useFahrenheit")    } set { ud.set(newValue, forKey: "mb_useFahrenheit")    } }
    
    var tempThreshold: Int { get { ud.integer(forKey: "mb_tempThreshold") } set { ud.set(newValue, forKey: "mb_tempThreshold") } }
    var tempColorIdx:  Int { get { ud.integer(forKey: "mb_tempColorIdx")  } set { ud.set(newValue, forKey: "mb_tempColorIdx")  } }
    var tempPresetList: String { get { ud.string(forKey: "mb_tempPresetList") ?? "30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95" } set { ud.set(newValue, forKey: "mb_tempPresetList") } }
    var enablePopover: Bool { get { ud.bool(forKey: "mb_enablePopover") } set { ud.set(newValue, forKey: "mb_enablePopover") } }

    var popoverShowCPU:       Bool { get { ud.bool(forKey: "pop_showCPU")       } set { ud.set(newValue, forKey: "pop_showCPU")       } }
    var popoverShowRAM:       Bool { get { ud.bool(forKey: "pop_showRAM")       } set { ud.set(newValue, forKey: "pop_showRAM")       } }
    var popoverShowDisk:      Bool { get { ud.bool(forKey: "pop_showDisk")      } set { ud.set(newValue, forKey: "pop_showDisk")      } }
    var popoverShowGPU:       Bool { get { ud.bool(forKey: "pop_showGPU")       } set { ud.set(newValue, forKey: "pop_showGPU")       } }
    var popoverShowGPURing:   Bool { get { ud.bool(forKey: "pop_showGPURing")   } set { ud.set(newValue, forKey: "pop_showGPURing")   } }
    var popoverShowNetwork:   Bool { get { ud.bool(forKey: "pop_showNetwork")   } set { ud.set(newValue, forKey: "pop_showNetwork")   } }
    var popoverShowProcesses: Bool { get { ud.bool(forKey: "pop_showProcesses") } set { ud.set(newValue, forKey: "pop_showProcesses") } }
    var popoverRingShowLabels:Bool { get { ud.bool(forKey: "pop_ringShowLabels") } set { ud.set(newValue, forKey: "pop_ringShowLabels") } }
    var popoverRingShowTemp:  Bool { get { ud.bool(forKey: "pop_ringShowTemp")   } set { ud.set(newValue, forKey: "pop_ringShowTemp")   } }
    var popoverCPUStyle:  Int { get { ud.integer(forKey: "pop_cpuStyle")  } set { ud.set(newValue, forKey: "pop_cpuStyle")  } }
    var popoverRAMStyle:  Int { get { ud.integer(forKey: "pop_ramStyle")  } set { ud.set(newValue, forKey: "pop_ramStyle")  } }
    var popoverDiskStyle: Int { get { ud.integer(forKey: "pop_diskStyle") } set { ud.set(newValue, forKey: "pop_diskStyle") } }
    var popoverGPUStyle:  Int { get { ud.integer(forKey: "pop_gpuStyle")  } set { ud.set(newValue, forKey: "pop_gpuStyle")  } }
    var popoverRingOrder: String { get { ud.string(forKey: "pop_ringOrder") ?? "cpu,ram,disk,gpu" } set { ud.set(newValue, forKey: "pop_ringOrder") } }

    var popoverShowCPUSparkline: Bool { get { ud.bool(forKey: "pop_showCPUSparkline") } set { ud.set(newValue, forKey: "pop_showCPUSparkline") } }
    var popoverShowGPUSparkline: Bool { get { ud.bool(forKey: "pop_showGPUSparkline") } set { ud.set(newValue, forKey: "pop_showGPUSparkline") } }
    var popoverShowNetSparkline: Bool { get { ud.bool(forKey: "pop_showNetSparkline") } set { ud.set(newValue, forKey: "pop_showNetSparkline") } }

    private let ud = UserDefaults.standard

    init() {
        if ud.object(forKey: "mb_showCPU")     == nil { ud.set(true,  forKey: "mb_showCPU")     }
        if ud.object(forKey: "mb_showTemp")    == nil { ud.set(true,  forKey: "mb_showTemp")    }
        if ud.object(forKey: "mb_showPower")   == nil { ud.set(true,  forKey: "mb_showPower")   }
        if ud.object(forKey: "mb_showGPU")     == nil { ud.set(true,  forKey: "mb_showGPU")     }
        if ud.object(forKey: "mb_showGPUtemp") == nil { ud.set(true,  forKey: "mb_showGPUtemp") }
        if ud.object(forKey: "mb_showGPUpwr")  == nil { ud.set(true,  forKey: "mb_showGPUpwr")  }
        if ud.object(forKey: "mb_showGPUvram") == nil { ud.set(false, forKey: "mb_showGPUvram") }
        if ud.object(forKey: "mb_showGPUfan")  == nil { ud.set(false, forKey: "mb_showGPUfan")  }
        if ud.object(forKey: "mb_showFanRPM")  == nil { ud.set(false, forKey: "mb_showFanRPM")  }
        if ud.object(forKey: "mb_fanIdx")      == nil { ud.set(0,     forKey: "mb_fanIdx")      }
        if ud.object(forKey: "mb_showMem")     == nil { ud.set(false, forKey: "mb_showMem")     }
        if ud.object(forKey: "mb_showNet")     == nil { ud.set(false, forKey: "mb_showNet")     }
        if ud.object(forKey: "mb_netColorIdx") == nil { ud.set(0,     forKey: "mb_netColorIdx") }
        
        if ud.object(forKey: "mb_enableColorAlerts") == nil { ud.set(false, forKey: "mb_enableColorAlerts") }
        if ud.object(forKey: "mb_showMaxFreqOnly")  == nil { ud.set(false, forKey: "mb_showMaxFreqOnly")  }
        if ud.object(forKey: "mb_useFahrenheit")    == nil { ud.set(false, forKey: "mb_useFahrenheit")    }
        
        if ud.object(forKey: "mb_tempThreshold") == nil { ud.set(80, forKey: "mb_tempThreshold") }
        if ud.object(forKey: "mb_tempColorIdx")  == nil { ud.set(3,  forKey: "mb_tempColorIdx")  } // Default is Red
        if ud.object(forKey: "mb_tempPresetList") == nil { ud.set("30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95", forKey: "mb_tempPresetList") }
        if ud.object(forKey: "mb_enablePopover") == nil { ud.set(true, forKey: "mb_enablePopover") }
        
        if ud.object(forKey: "pop_showCPU")       == nil { ud.set(true, forKey: "pop_showCPU")       }
        if ud.object(forKey: "pop_showRAM")       == nil { ud.set(true, forKey: "pop_showRAM")       }
        if ud.object(forKey: "pop_showDisk")      == nil { ud.set(true, forKey: "pop_showDisk")      }
        if ud.object(forKey: "pop_showGPU")       == nil { ud.set(true, forKey: "pop_showGPU")       }
        if ud.object(forKey: "pop_showGPURing")   == nil { ud.set(true, forKey: "pop_showGPURing")   }
        if ud.object(forKey: "pop_showNetwork")   == nil { ud.set(true, forKey: "pop_showNetwork")   }
        if ud.object(forKey: "pop_showProcesses") == nil { ud.set(true, forKey: "pop_showProcesses") }
        if ud.object(forKey: "pop_ringShowLabels") == nil { ud.set(true, forKey: "pop_ringShowLabels") }
        if ud.object(forKey: "pop_ringShowTemp")   == nil { ud.set(true, forKey: "pop_ringShowTemp")   }
        if ud.object(forKey: "pop_cpuStyle")  == nil { ud.set(0, forKey: "pop_cpuStyle")  }
        if ud.object(forKey: "pop_ramStyle")  == nil { ud.set(0, forKey: "pop_ramStyle")  }
        if ud.object(forKey: "pop_diskStyle") == nil { ud.set(0, forKey: "pop_diskStyle") }
        if ud.object(forKey: "pop_gpuStyle")  == nil { ud.set(0, forKey: "pop_gpuStyle")  }

        if ud.object(forKey: "pop_showCPUSparkline") == nil {
            let style = ud.integer(forKey: "pop_cpuStyle")
            if style == 2 {
                ud.set(true, forKey: "pop_showCPUSparkline")
                ud.set(0, forKey: "pop_cpuStyle")
            } else {
                ud.set(false, forKey: "pop_showCPUSparkline")
            }
        }
        if ud.object(forKey: "pop_showGPUSparkline") == nil {
            let style = ud.integer(forKey: "pop_gpuStyle")
            if style == 2 {
                ud.set(true, forKey: "pop_showGPUSparkline")
                ud.set(0, forKey: "pop_gpuStyle")
            } else {
                ud.set(false, forKey: "pop_showGPUSparkline")
            }
        }
        if ud.object(forKey: "pop_showNetSparkline") == nil {
            ud.set(false, forKey: "pop_showNetSparkline")
        }
    }

    var totalWidth: CGFloat {
        var w: CGFloat = 0
        if showCPU     { w += showMaxFreqOnly ? 48 : 56 }
        if showTemp    { w += 56 }
        if showPower   { w += 56 }
        if showFanRPM  { w += 56 }
        if showMemory  { w += 56 }
        if showNetwork { w += 68 }
        return max(w, 110)
    }
}

fileprivate class StatusbarView: NSView {

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

@MainActor
class StatusbarController: NSObject, NSMenuDelegate, NSPopoverDelegate {

    var statusItem: NSStatusItem!
    fileprivate var view: StatusbarView!

    var updateTimer: Timer?
    var menu: NSMenu?
    private var popover: NSPopover!

    private var smcReady = false
    private var numFans = 0

    private var peakTemp: Float = 0
    private var peakPower: Float = 0
    private var peakFreq: Float = 0
    private var peakFan: UInt64 = 0

    // Diff-based rendering snapshot tracking
    private var lastReportedMeanFreq: Float = -1
    private var lastReportedMaxFreq: Float = -1
    private var lastReportedTemp: Float = -1
    private var lastReportedPwr: Float = -1
    private var lastReportedGpuTemp: Float = -1
    private var lastReportedGpuPwr: Float = -1
    private var lastReportedFanRPM: UInt64 = 0
    private var lastReportedNetUp: Double = -1
    private var lastReportedNetDown: Double = -1

    override init() {
        super.init()

        let initRes = ProcessorModel.shared.kernelGetUInt64(count: 2, selector: 90)
        smcReady = initRes.count > 0 && initRes[0] == 1
        if smcReady {
            numFans = Int(ProcessorModel.shared.kernelGetUInt64(count: 1, selector: 91).first ?? 0)
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.isVisible = true

        view = StatusbarView()
        view.setup()
        statusItem.button?.wantsLayer = true
        statusItem.button?.addSubview(view)

        statusItem.button?.target = self
        statusItem.button?.action = #selector(itemClicked)
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

        // Setup NSPopover with MenuBarPopoverView
        popover = NSPopover()
        popover.behavior = .transient
        popover.appearance = NSAppearance(named: .vibrantDark)
        popover.contentViewController = NSHostingController(rootView: MenuBarPopoverView())
        popover.delegate = self

        updateLength()
        if let btn = statusItem.button {
            view?.frame = btn.bounds
        }

        addMenuItems()

        restartTimer()

        // Listen for config changes and telemetry updates
        NotificationCenter.default.addObserver(self, selector: #selector(updateLength), name: .init("MenuBarConfigChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(closePopover), name: .init("CloseMenuBarPopover"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(update), name: .init("TelemetryDataUpdated"), object: nil)

        TelemetryModel.shared.setStatusbarActive(true)
    }

    @objc func restartTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
        TelemetryModel.shared.updateTimerState()
    }

    @objc func updateLength() {
        let w = MenuBarConfig.shared.totalWidth
        statusItem.length = w
        view?.frame = statusItem.button?.bounds ?? NSRect(x: 0, y: 0, width: w, height: 22)
        lastReportedTemp = -1 // Reset snapshot to force redraw on layout change
        update()
    }

    func dismiss() {
        updateTimer?.invalidate()
        updateTimer = nil
        TelemetryModel.shared.setStatusbarActive(false)
        NotificationCenter.default.removeObserver(self)
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }

    @objc func update() {
        let tm = TelemetryModel.shared
        let power = Float(tm.cpuWatts)
        let temperature = Float(tm.cpuTempC)
        let meanFre = Float(tm.cpuFreqAvgGHz * 1000.0)
        let maxFre = Float(tm.cpuFreqMaxGHz * 1000.0)
        let gpuTempVal = Float(tm.gpuTempC)
        let gpuPwrVal = Float(tm.gpuPowerW)

        if temperature > peakTemp { peakTemp = temperature }
        if power > peakPower { peakPower = power }
        if maxFre > peakFreq { peakFreq = maxFre }

        let fanIdx = max(0, MenuBarConfig.shared.fanIndex)
        let currentFan: UInt64 = (fanIdx < tm.fans.count) ? tm.fans[fanIdx].rpm : 0
        if currentFan > peakFan { peakFan = currentFan }

        // Diff-based Rendering guard (Skip redraw if change is insignificant)
        let tempDiff = abs(temperature - lastReportedTemp) >= 0.5
        let pwrDiff = abs(power - lastReportedPwr) >= 0.5
        let meanFreqDiff = abs(meanFre - lastReportedMeanFreq) >= 10.0
        let maxFreqDiff = abs(maxFre - lastReportedMaxFreq) >= 10.0
        let gpuTempDiff = abs(gpuTempVal - lastReportedGpuTemp) >= 0.5
        let fanDiff = (currentFan >= lastReportedFanRPM ? currentFan - lastReportedFanRPM : lastReportedFanRPM - currentFan) >= 20
        let netDiff = abs(tm.netUploadMBps - lastReportedNetUp) >= 0.05 || abs(tm.netDownloadMBps - lastReportedNetDown) >= 0.05

        guard tempDiff || pwrDiff || meanFreqDiff || maxFreqDiff || gpuTempDiff || fanDiff || netDiff || lastReportedTemp < 0 else {
            return
        }

        lastReportedMeanFreq = meanFre
        lastReportedMaxFreq = maxFre
        lastReportedTemp = temperature
        lastReportedPwr = power
        lastReportedGpuTemp = gpuTempVal
        lastReportedGpuPwr = gpuPwrVal
        lastReportedFanRPM = currentFan
        lastReportedNetUp = tm.netUploadMBps
        lastReportedNetDown = tm.netDownloadMBps

        view?.meanFreq = meanFre
        view?.maxFreq = maxFre
        view?.temp = temperature
        view?.pwr = power
        view?.gpuTemp = gpuTempVal
        view?.gpuPwr = gpuPwrVal
        view?.gpuVram = tm.gpuVramUsedBytes
        view?.gpuFanRPM = Float(tm.gpuFanRPM)
        view?.fanRPM = currentFan

        view?.memoryUsed = Float((tm.ramUsagePct / 100.0) * Double(tm.sysInfo.ramGB))
        view?.totalMemory = "\(tm.sysInfo.ramGB)G"

        if MenuBarConfig.shared.showNetwork {
            view?.netUpload = tm.netUploadMBps
            view?.netDownload = tm.netDownloadMBps
        }

        view.setNeedsDisplay(view.bounds)
    }

    @objc func itemClicked() {
        guard let event = NSApp.currentEvent else { return }
        switch event.type {
        case .leftMouseUp:
            if let button = statusItem.button {
                if MenuBarConfig.shared.enablePopover {
                    if popover.isShown {
                        closePopover()
                    } else {
                        let clickLocation = button.convert(event.locationInWindow, from: nil)
                        let w = MenuBarConfig.shared.totalWidth
                        let clampedX = max(5, min(w - 5, clickLocation.x))
                        
                        // Physical bottom of the button inside bounds (keep within bounds to prevent AppKit from discarding the rect):
                        // If flipped: bottom is y = bounds.height - 1, edge is .maxY
                        // If not flipped: bottom is y = 0, edge is .minY
                        let bottomY = button.isFlipped ? (button.bounds.height - 1) : 0
                        let edge: NSRectEdge = button.isFlipped ? .maxY : .minY
                        let rect = NSRect(x: clampedX - 5, y: bottomY, width: 10, height: 1)
                        
                        popover.show(relativeTo: rect, of: button, preferredEdge: edge)
                        
                        // Force the popover window to align perfectly below the status bar button in screen coordinates
                        if let popoverWindow = popover.contentViewController?.view.window,
                           let buttonWindow = button.window {
                            let rectInWindow = button.convert(button.bounds, to: nil)
                            let buttonRectInScreen = buttonWindow.convertToScreen(rectInWindow)
                            var popoverFrame = popoverWindow.frame
                            
                            // Set vertical position exactly 2pt below the status bar button
                            popoverFrame.origin.y = buttonRectInScreen.origin.y - popoverFrame.height - 2
                            
                            // Center horizontally relative to the button
                            let buttonCenterX = buttonRectInScreen.origin.x + buttonRectInScreen.width / 2
                            popoverFrame.origin.x = buttonCenterX - popoverFrame.width / 2
                            
                            // Clamp horizontally to the screen's visible frame (multi-monitor safe)
                            if let screen = buttonWindow.screen {
                                let screenFrame = screen.visibleFrame
                                let minX = screenFrame.origin.x + 8
                                let maxX = screenFrame.origin.x + screenFrame.width - popoverFrame.width - 8
                                popoverFrame.origin.x = max(minX, min(maxX, popoverFrame.origin.x))
                            }
                            
                            popoverWindow.setFrame(popoverFrame, display: true, animate: false)
                        }
                        
                        TelemetryModel.shared.setPopoverVisible(true)
                        popover.contentViewController?.view.window?.makeKey()
                    }
                } else {
                    // Fallback to showing the classic dropdown menu
                    if let m = menu {
                        m.delegate = self
                        statusItem.menu = m
                        statusItem.button?.performClick(nil)
                    }
                }
            }
        case .rightMouseUp:
            if let m = menu {
                m.delegate = self
                statusItem.menu = m
                statusItem.button?.performClick(nil)
            }
        default: break
        }
    }

    @objc func closePopover() {
        if popover.isShown {
            popover.close()
            TelemetryModel.shared.setPopoverVisible(false)
        }
    }

    func popoverDidClose(_ notification: Notification) {
        TelemetryModel.shared.setPopoverVisible(false)
    }

    func menuDidClose(_ menu: NSMenu) {
        statusItem.menu = nil
    }

    func menuWillOpen(_ menu: NSMenu) {
        addMenuItems()
    }

    @objc func gadget() {
        ViewController.launch(forceFocus: true)
    }
    
    @objc func tool() {
        ViewController.launch(forceFocus: true)
        TelemetryModel.shared.selectedTab = .advanced
    }
    
    @objc func fans() {
        ViewController.launch(forceFocus: true)
        TelemetryModel.shared.selectedTab = .fanControl
    }
    
    @objc func exitApp() { NSApplication.shared.terminate(nil) }

    @objc func changeNetColor(_ sender: NSMenuItem) {
        MenuBarConfig.shared.netColorIdx = sender.tag
        NotificationCenter.default.post(name: .init("MenuBarConfigChanged"), object: nil)
        if let parentMenu = sender.menu {
            for item in parentMenu.items {
                item.state = (item.tag == sender.tag) ? .on : .off
            }
        }
    }

    @objc func toggleColorAlerts(_ sender: NSMenuItem) {
        MenuBarConfig.shared.enableColorAlerts = !MenuBarConfig.shared.enableColorAlerts
        NotificationCenter.default.post(name: .init("MenuBarConfigChanged"), object: nil)
        sender.state = MenuBarConfig.shared.enableColorAlerts ? .on : .off
    }

    @objc func changeTempColor(_ sender: NSMenuItem) {
        MenuBarConfig.shared.tempColorIdx = sender.tag
        NotificationCenter.default.post(name: .init("MenuBarConfigChanged"), object: nil)
        if let parentMenu = sender.menu {
            for item in parentMenu.items {
                item.state = (item.tag == sender.tag) ? .on : .off
            }
        }
    }

    @objc func changeTempThreshold(_ sender: NSMenuItem) {
        MenuBarConfig.shared.tempThreshold = sender.tag
        NotificationCenter.default.post(name: .init("MenuBarConfigChanged"), object: nil)
        if let parentMenu = sender.menu {
            for item in parentMenu.items {
                item.state = (item.tag == sender.tag) ? .on : .off
            }
        }
    }

    @objc func resetPeaks() {
        peakTemp = 0
        peakPower = 0
        peakFreq = 0
        peakFan = 0
        update()
    }

    @objc func toggleWidget(_ sender: NSMenuItem) {
        guard let typeString = sender.representedObject as? String,
              let type = DesktopWidgetType(rawValue: typeString) else { return }
        
        let key = "widget_enabled_\(type.rawValue)"
        let isEnabled = !UserDefaults.standard.bool(forKey: key)
        UserDefaults.standard.set(isEnabled, forKey: key)
        sender.state = isEnabled ? .on : .off
        DesktopWidgetManager.shared.refreshWidgets()
        NotificationCenter.default.post(name: .init("WidgetSettingsChanged"), object: nil)
    }
    
    @objc func toggleWidgetEdit(_ sender: NSMenuItem) {
        DesktopWidgetManager.shared.isEditingWidgets.toggle()
        sender.state = DesktopWidgetManager.shared.isEditingWidgets ? .on : .off
        NotificationCenter.default.post(name: .init("WidgetSettingsChanged"), object: nil)
    }

    @objc func disableAllWidgets(_ sender: NSMenuItem) {
        for type in DesktopWidgetType.allCases {
            UserDefaults.standard.set(false, forKey: "widget_enabled_\(type.rawValue)")
        }
        DesktopWidgetManager.shared.refreshWidgets()
        NotificationCenter.default.post(name: .init("WidgetSettingsChanged"), object: nil)
    }

    private func addMenuItems() {
        if menu == nil {
            menu = NSMenu()
        } else {
            menu?.removeAllItems()
        }
        guard let m = menu else { return }
        var item = NSMenuItem(title: NSLocalizedString("AMD Power Gadget", comment: ""), action: #selector(gadget), keyEquivalent: ""); item.target = self
        m.addItem(item)
        item = NSMenuItem(title: NSLocalizedString("Advanced", comment: ""), action: #selector(tool), keyEquivalent: ""); item.target = self
        m.addItem(item)
        item = NSMenuItem(title: NSLocalizedString("Fan Control", comment: ""), action: #selector(fans), keyEquivalent: ""); item.target = self
        m.addItem(item)
        
        m.addItem(NSMenuItem.separator())

        // Desktop Widgets submenu (built dynamically)
        let widgetsMenu = NSMenu()
        
        for type in DesktopWidgetType.allCases {
            let key = "widget_enabled_\(type.rawValue)"
            let isEnabled = UserDefaults.standard.bool(forKey: key)
            let wItem = NSMenuItem(title: NSLocalizedString("Show \(type.rawValue) Widget", comment: ""), action: #selector(toggleWidget(_:)), keyEquivalent: "")
            wItem.target = self
            wItem.representedObject = type.rawValue
            wItem.state = isEnabled ? .on : .off
            widgetsMenu.addItem(wItem)
        }
        
        widgetsMenu.addItem(NSMenuItem.separator())
        
        let editItem = NSMenuItem(title: NSLocalizedString("Edit Widget Layout", comment: ""), action: #selector(toggleWidgetEdit(_:)), keyEquivalent: "")
        editItem.target = self
        editItem.state = DesktopWidgetManager.shared.isEditingWidgets ? .on : .off
        widgetsMenu.addItem(editItem)
        
        let disableAllItem = NSMenuItem(title: NSLocalizedString("Disable All Widgets", comment: ""), action: #selector(disableAllWidgets(_:)), keyEquivalent: "")
        disableAllItem.target = self
        widgetsMenu.addItem(disableAllItem)
        
        let widgetsMenuItem = NSMenuItem(title: NSLocalizedString("Desktop Widgets", comment: ""), action: nil, keyEquivalent: "")
        widgetsMenuItem.submenu = widgetsMenu
        m.addItem(widgetsMenuItem)
        
        m.addItem(NSMenuItem.separator())

        // Session Peaks submenu
        let peaksMenu = NSMenu()
        
        var displayPeakTemp = peakTemp
        var unitStr = "°C"
        if MenuBarConfig.shared.useFahrenheit {
            displayPeakTemp = peakTemp * 9.0 / 5.0 + 32.0
            unitStr = "°F"
        }
        
        let tempStr = String(format: "Peak Temp: %.1f\(unitStr)", displayPeakTemp)
        let tempItem = NSMenuItem(title: tempStr, action: nil, keyEquivalent: "")
        tempItem.isEnabled = false
        peaksMenu.addItem(tempItem)

        let pwrStr = String(format: "Peak Power: %.1f W", peakPower)
        let pwrItem = NSMenuItem(title: pwrStr, action: nil, keyEquivalent: "")
        pwrItem.isEnabled = false
        peaksMenu.addItem(pwrItem)

        let freqStr = String(format: "Peak Freq: %.2f GHz", peakFreq * 0.001)
        let freqItem = NSMenuItem(title: freqStr, action: nil, keyEquivalent: "")
        freqItem.isEnabled = false
        peaksMenu.addItem(freqItem)

        if numFans > 0 && peakFan > 0 {
            let fanStr = String(format: "Peak Fan: %d RPM", peakFan)
            let fanItem = NSMenuItem(title: fanStr, action: nil, keyEquivalent: "")
            fanItem.isEnabled = false
            peaksMenu.addItem(fanItem)
        }

        peaksMenu.addItem(NSMenuItem.separator())

        let resetPeaksItem = NSMenuItem(title: NSLocalizedString("Reset Peaks", comment: ""), action: #selector(resetPeaks), keyEquivalent: "")
        resetPeaksItem.target = self
        peaksMenu.addItem(resetPeaksItem)

        let peaksMenuItem = NSMenuItem(title: NSLocalizedString("Session Peaks", comment: ""), action: nil, keyEquivalent: "")
        peaksMenuItem.submenu = peaksMenu
        m.addItem(peaksMenuItem)

        m.addItem(NSMenuItem.separator())
        
        // Dynamic Colors (Temp Only)
        let alertsItem = NSMenuItem(title: NSLocalizedString("Dynamic Colors (Temp Only)", comment: ""), action: #selector(toggleColorAlerts(_:)), keyEquivalent: "")
        alertsItem.target = self
        alertsItem.state = MenuBarConfig.shared.enableColorAlerts ? .on : .off
        m.addItem(alertsItem)

        let tempColorSubmenu = NSMenu()
        let colorsList = ["Green", "Blue", "Orange", "Red", "Purple", "Pink", "Teal"]
        for (idx, colorName) in colorsList.enumerated() {
            let localizedColor = NSLocalizedString(colorName, comment: "")
            let colorItem = NSMenuItem(title: localizedColor, action: #selector(changeTempColor(_:)), keyEquivalent: "")
            colorItem.target = self
            colorItem.tag = idx
            colorItem.state = (MenuBarConfig.shared.tempColorIdx == idx) ? .on : .off
            tempColorSubmenu.addItem(colorItem)
        }
        let tempColorMenuItem = NSMenuItem(title: NSLocalizedString("Temp Alert Color", comment: ""), action: nil, keyEquivalent: "")
        tempColorMenuItem.submenu = tempColorSubmenu
        m.addItem(tempColorMenuItem)

        let tempLimitSubmenu = NSMenu()
        let presets = MenuBarConfig.shared.tempPresetList
            .components(separatedBy: ",")
            .compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        var limitsToShow = Array(Set(presets)).sorted()
        let currentLimit = MenuBarConfig.shared.tempThreshold
        if !limitsToShow.contains(currentLimit) {
            limitsToShow.append(currentLimit)
            limitsToShow.sort()
        }
        for limit in limitsToShow {
            let limitItem = NSMenuItem(title: "\(limit)°C", action: #selector(changeTempThreshold(_:)), keyEquivalent: "")
            limitItem.target = self
            limitItem.tag = limit
            limitItem.state = (currentLimit == limit) ? .on : .off
            tempLimitSubmenu.addItem(limitItem)
        }
        let tempLimitMenuItem = NSMenuItem(title: NSLocalizedString("Temp Alert Limit", comment: ""), action: nil, keyEquivalent: "")
        tempLimitMenuItem.submenu = tempLimitSubmenu
        m.addItem(tempLimitMenuItem)
        
        m.addItem(NSMenuItem.separator())
        
        let colorSubmenu = NSMenu()
        let colors = ["Green", "Blue", "Orange", "Red", "Purple", "Pink", "Teal"]
        for (idx, colorName) in colors.enumerated() {
            let localizedColor = NSLocalizedString(colorName, comment: "")
            let colorItem = NSMenuItem(title: localizedColor, action: #selector(changeNetColor(_:)), keyEquivalent: "")
            colorItem.target = self
            colorItem.tag = idx
            colorItem.state = (MenuBarConfig.shared.netColorIdx == idx) ? .on : .off
            colorSubmenu.addItem(colorItem)
        }
        let colorMenuItem = NSMenuItem(title: NSLocalizedString("Network Arrows Color", comment: ""), action: nil, keyEquivalent: "")
        colorMenuItem.submenu = colorSubmenu
        m.addItem(colorMenuItem)
        
        m.addItem(NSMenuItem.separator())
        
        let popoverItem = NSMenuItem(title: NSLocalizedString("Use Popover Menu", comment: ""), action: #selector(togglePopover(_:)), keyEquivalent: "")
        popoverItem.target = self
        popoverItem.state = MenuBarConfig.shared.enablePopover ? .on : .off
        m.addItem(popoverItem)
        
        m.addItem(NSMenuItem.separator())
        item = NSMenuItem(title: NSLocalizedString("Exit", comment: ""), action: #selector(exitApp), keyEquivalent: ""); item.target = self
        m.addItem(item)
    }

    @objc func togglePopover(_ sender: NSMenuItem) {
        MenuBarConfig.shared.enablePopover = !MenuBarConfig.shared.enablePopover
        sender.state = MenuBarConfig.shared.enablePopover ? .on : .off
        if !MenuBarConfig.shared.enablePopover && popover.isShown {
            closePopover()
        }
        NotificationCenter.default.post(name: .init("MenuBarConfigChanged"), object: nil)
    }

    // MARK: - Helpers
    private func getFreeMemoryMB() -> Int {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        if result == KERN_SUCCESS {
            let pageSize = Int(getpagesize())
            let freePages = Int(stats.free_count) + Int(stats.inactive_count)
            return (freePages * pageSize) / (1024 * 1024)
        }
        return 0
    }
}

// Custom NSHostingView subclass to handle window dragging in edit mode
class WidgetHostingView<Content: View>: NSHostingView<Content> {
    override func mouseDown(with event: NSEvent) {
        if DesktopWidgetManager.shared.isEditingWidgets {
            // Turn off auto-alignment if the user starts dragging
            if UserDefaults.standard.bool(forKey: "widget_auto_align") {
                UserDefaults.standard.set(false, forKey: "widget_auto_align")
                NotificationCenter.default.post(name: .init("WidgetSettingsChanged"), object: nil)
            }
            if let window = self.window {
                window.performDrag(with: event)
                DesktopWidgetManager.shared.snapWindow(window)
            }
        } else {
            super.mouseDown(with: event)
        }
    }
}

enum DesktopWidgetType: String, CaseIterable {
    case cpu = "CPU"
    case gpu = "GPU"
    case ram = "RAM"
    case disk = "Disk"
    case net = "Net"
    case fan = "Fan"
    case clock = "Clock"
    case united = "United"
    
    var color1: Color {
        switch self {
        case .cpu: return .blue
        case .gpu: return .purple
        case .ram: return .orange
        case .disk: return .pink
        case .net: return .green
        case .fan: return .teal
        case .clock: return .orange
        case .united: return .blue
        }
    }
    
    var color2: Color {
        switch self {
        case .cpu: return .cyan
        case .gpu: return Color(red: 0.5, green: 0.3, blue: 0.9)
        case .ram: return .yellow
        case .disk: return Color(red: 0.9, green: 0.4, blue: 0.6)
        case .net: return .mint
        case .fan: return Color(red: 0.2, green: 0.7, blue: 0.8)
        case .clock: return .yellow
        case .united: return .purple
        }
    }
}

@MainActor
class DesktopWidgetManager: NSObject, ObservableObject, NSWindowDelegate {
    static let shared = DesktopWidgetManager()
    
    @Published var isEditingWidgets = false {
        didSet { updateWindowModes() }
    }
    
    private var widgetWindows: [DesktopWidgetType: NSWindow] = [:]
    
    var hasActiveWidgets: Bool {
        return !widgetWindows.isEmpty
    }
    
    func refreshWidgets() {
        for type in DesktopWidgetType.allCases {
            let key = "widget_enabled_\(type.rawValue)"
            let isEnabled = UserDefaults.standard.bool(forKey: key)
            
            if isEnabled && widgetWindows[type] == nil {
                spawnWidget(type: type)
            } else if !isEnabled && widgetWindows[type] != nil {
                if let win = widgetWindows[type] {
                    win.orderOut(nil)
                    win.contentView = nil
                }
                widgetWindows.removeValue(forKey: type)
            }
        }
        
        autoAlignActiveWidgets()
        
        DispatchQueue.main.async {
            TelemetryModel.shared.updateTimerState() // Ensure timer runs if widgets are active
        }
    }
    func defaultSizeFor(type: DesktopWidgetType, style: DesktopWidgetStyle) -> NSSize {
        let resolvedStyle = (style == .coreMatrix && type != .cpu) ? .classic : style
        let width: CGFloat
        let height: CGFloat
        
        switch resolvedStyle {
        case .classic:
            if type == .united {
                width = 180
                height = 180
            } else {
                width = 160
                height = 160
            }
        case .proMonitor:
            if type == .united {
                width = 336
                height = 180
            } else {
                width = 336
                height = 160
            }
        case .textList: // Stats Table
            if type == .united {
                width = 248
                height = 180
            } else {
                width = 248
                height = 160
            }
        case .coreMatrix: // CPU only
            width = 248
            height = 160
        }
        return NSSize(width: width, height: height)
    }
    
    private func spawnWidget(type: DesktopWidgetType) {
        let widgetView = DesktopWidgetView(model: TelemetryModel.shared, manager: self, type: type)
        let hostingView = WidgetHostingView(rootView: widgetView)
        
        let screen = NSScreen.main ?? NSScreen.screens.first
        let screenRect = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        
        let styleRaw = UserDefaults.standard.string(forKey: "widget_style_v2_\(type.rawValue)") ?? DesktopWidgetStyle.classic.rawValue
        let style = DesktopWidgetStyle(rawValue: styleRaw) ?? .classic
        let defSize = defaultSizeFor(type: type, style: style)
        
        let savedWKey = "widget_width_\(type.rawValue)"
        let savedHKey = "widget_height_\(type.rawValue)"
        let width = UserDefaults.standard.object(forKey: savedWKey) != nil ? CGFloat(UserDefaults.standard.double(forKey: savedWKey)) : defSize.width
        let height = UserDefaults.standard.object(forKey: savedHKey) != nil ? CGFloat(UserDefaults.standard.double(forKey: savedHKey)) : defSize.height
        
        let savedXKey = "widget_x_\(type.rawValue)"
        let savedYKey = "widget_y_\(type.rawValue)"
        let hasSavedPos = UserDefaults.standard.object(forKey: savedXKey) != nil
        
        let windowRect: NSRect
        if hasSavedPos {
            let loadedX = CGFloat(UserDefaults.standard.double(forKey: savedXKey))
            let loadedY = CGFloat(UserDefaults.standard.double(forKey: savedYKey))
            let margin: CGFloat = 16
            let x = max(screenRect.minX + margin, min(loadedX, screenRect.maxX - width - margin))
            let y = max(screenRect.minY + margin, min(loadedY, screenRect.maxY - height - margin))
            windowRect = NSRect(x: x, y: y, width: width, height: height)
        } else {
            let offsetMultiplier: CGFloat
            switch type {
            case .cpu: offsetMultiplier = 0
            case .gpu: offsetMultiplier = 1
            case .ram: offsetMultiplier = 2
            case .disk: offsetMultiplier = 3
            case .net: offsetMultiplier = 4
            case .fan: offsetMultiplier = 5
            case .clock: offsetMultiplier = 6
            case .united: offsetMultiplier = 7
            }
            let margin: CGFloat = 16
            let spacing: CGFloat = 16
            let x = screenRect.maxX - width - margin
            let y = screenRect.maxY - height - margin - (offsetMultiplier * (height + spacing))
            windowRect = NSRect(x: x, y: y, width: width, height: height)
        }
        
        let styleMask: NSWindow.StyleMask = isEditingWidgets ? [.borderless, .resizable] : [.borderless]
        let widgetWindow = NSWindow(
            contentRect: windowRect,
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        
        widgetWindow.contentView = hostingView
        widgetWindow.isOpaque = false
        widgetWindow.backgroundColor = .clear
        widgetWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        widgetWindow.hasShadow = true
        widgetWindow.delegate = self
        
        widgetWindows[type] = widgetWindow
        updateWindowModes()
        widgetWindow.orderFront(nil)
    }
    
    private func updateWindowModes() {
        for (_, window) in widgetWindows {
            if isEditingWidgets {
                window.styleMask = [.borderless, .resizable]
                window.level = .normal
                window.ignoresMouseEvents = false
            } else {
                window.styleMask = [.borderless]
                // Places the widgets 1 level above the wallpaper to make them visible but behind standard apps and desktop icons
                window.level = NSWindow.Level(Int(CGWindowLevelForKey(.desktopWindow)) + 1)
                window.ignoresMouseEvents = true
            }
        }
    }
    
    func resizeWidget(type: DesktopWidgetType, style: DesktopWidgetStyle) {
        guard let window = widgetWindows[type] else { return }
        let size = defaultSizeFor(type: type, style: style)
        
        let oldFrame = window.frame
        let newX = oldFrame.maxX - size.width
        let newY = oldFrame.maxY - size.height
        
        window.setFrame(NSRect(x: newX, y: newY, width: size.width, height: size.height), display: true, animate: true)
        
        UserDefaults.standard.set(Double(newX), forKey: "widget_x_\(type.rawValue)")
        UserDefaults.standard.set(Double(newY), forKey: "widget_y_\(type.rawValue)")
        UserDefaults.standard.set(Double(size.width), forKey: "widget_width_\(type.rawValue)")
        UserDefaults.standard.set(Double(size.height), forKey: "widget_height_\(type.rawValue)")
    }
    
    func snapWindow(_ window: NSWindow) {
        let screen = window.screen ?? NSScreen.main ?? NSScreen.screens.first
        let screenRect = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        
        let margin: CGFloat = 16.0
        let spacing: CGFloat = 16.0
        let gridSize: CGFloat = 20.0
        let snapThreshold: CGFloat = 10.0 // Magnetic snapping to other widgets when within 10px
        
        let frame = window.frame
        var newX = frame.origin.x
        var newY = frame.origin.y
        
        // 1. Grid Snapping
        // We round the position relative to the screen bounds plus margins to fit a 20px grid
        let relativeX = newX - (screenRect.minX + margin)
        let relativeY = newY - (screenRect.minY + margin)
        
        let snappedRelativeX = round(relativeX / gridSize) * gridSize
        let snappedRelativeY = round(relativeY / gridSize) * gridSize
        
        newX = screenRect.minX + margin + snappedRelativeX
        newY = screenRect.minY + margin + snappedRelativeY
        
        // 2. Strict bounds check to keep widgets inside the screen visible frame
        newX = max(screenRect.minX + margin, min(newX, screenRect.maxX - frame.width - margin))
        newY = max(screenRect.minY + margin, min(newY, screenRect.maxY - frame.height - margin))
        
        // 3. Magnetic alignment to other active widgets
        for (otherType, otherWin) in widgetWindows {
            if otherWin == window { continue }
            let otherFrame = otherWin.frame
            
            // Snap X edges:
            if abs(newX - otherFrame.minX) < snapThreshold {
                newX = otherFrame.minX
            } else if abs((newX + frame.width) - otherFrame.maxX) < snapThreshold {
                newX = otherFrame.maxX - frame.width
            } else if abs(newX - (otherFrame.maxX + spacing)) < snapThreshold {
                newX = otherFrame.maxX + spacing
            } else if abs((newX + frame.width) - (otherFrame.minX - spacing)) < snapThreshold {
                newX = otherFrame.minX - frame.width - spacing
            }
            
            // Snap Y edges:
            if abs((newY + frame.height) - otherFrame.maxY) < snapThreshold {
                newY = otherFrame.maxY - frame.height
            } else if abs(newY - otherFrame.minY) < snapThreshold {
                newY = otherFrame.minY
            } else if abs((newY + frame.height) - (otherFrame.minY - spacing)) < snapThreshold {
                newY = otherFrame.minY - spacing - frame.height
            } else if abs(newY - (otherFrame.maxY + spacing)) < snapThreshold {
                newY = otherFrame.maxY + spacing
            }
        }
        
        // Double clamp after magnetic snaps to avoid any widget sticking outside
        newX = max(screenRect.minX + margin, min(newX, screenRect.maxX - frame.width - margin))
        newY = max(screenRect.minY + margin, min(newY, screenRect.maxY - frame.height - margin))
        
        // Apply frame with animation
        if newX != frame.origin.x || newY != frame.origin.y {
            window.setFrame(NSRect(x: newX, y: newY, width: frame.width, height: frame.height), display: true, animate: true)
        }
        
        // Save the safe, clamped position to user settings
        for (type, win) in widgetWindows {
            if win == window {
                UserDefaults.standard.set(Double(newX), forKey: "widget_x_\(type.rawValue)")
                UserDefaults.standard.set(Double(newY), forKey: "widget_y_\(type.rawValue)")
                break
            }
        }
    }
    
    func autoAlignActiveWidgets() {
        let autoAlign = UserDefaults.standard.bool(forKey: "widget_auto_align")
        guard autoAlign else { return }
        
        let corner = UserDefaults.standard.string(forKey: "widget_align_corner") ?? "topRight"
        let screen = NSScreen.main ?? NSScreen.screens.first
        let screenRect = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        
        let activeTypes = DesktopWidgetType.allCases.filter { UserDefaults.standard.bool(forKey: "widget_enabled_\($0.rawValue)") }
        
        var currentY: CGFloat = 0
        let margin: CGFloat = 16
        let spacing: CGFloat = 16
        
        for (index, type) in activeTypes.enumerated() {
            guard let window = widgetWindows[type] else { continue }
            let w = window.frame.width
            let h = window.frame.height
            
            let x: CGFloat
            let y: CGFloat
            
            switch corner {
            case "topRight":
                x = screenRect.maxX - w - margin
                if index == 0 {
                    currentY = screenRect.maxY - h - margin
                } else {
                    currentY -= (h + spacing)
                }
                y = currentY
            case "topLeft":
                x = screenRect.minX + margin
                if index == 0 {
                    currentY = screenRect.maxY - h - margin
                } else {
                    currentY -= (h + spacing)
                }
                y = currentY
            case "bottomRight":
                x = screenRect.maxX - w - margin
                if index == 0 {
                    currentY = screenRect.minY + margin
                } else {
                    currentY += (h + spacing)
                }
                y = currentY
            case "bottomLeft":
                x = screenRect.minX + margin
                if index == 0 {
                    currentY = screenRect.minY + margin
                } else {
                    currentY += (h + spacing)
                }
                y = currentY
            default:
                continue
            }
            
            window.setFrame(NSRect(x: x, y: y, width: w, height: h), display: true, animate: true)
            
            UserDefaults.standard.set(Double(x), forKey: "widget_x_\(type.rawValue)")
            UserDefaults.standard.set(Double(y), forKey: "widget_y_\(type.rawValue)")
        }
    }
    
    func windowDidMove(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        for (type, win) in widgetWindows {
            if win == window {
                let origin = window.frame.origin
                let screen = window.screen ?? NSScreen.main ?? NSScreen.screens.first
                let screenRect = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
                let margin: CGFloat = 16
                
                let clampedX = max(screenRect.minX + margin, min(origin.x, screenRect.maxX - window.frame.width - margin))
                let clampedY = max(screenRect.minY + margin, min(origin.y, screenRect.maxY - window.frame.height - margin))
                
                UserDefaults.standard.set(Double(clampedX), forKey: "widget_x_\(type.rawValue)")
                UserDefaults.standard.set(Double(clampedY), forKey: "widget_y_\(type.rawValue)")
                break
            }
        }
    }
    
    func windowDidResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        for (type, win) in widgetWindows {
            if win == window {
                let size = window.frame.size
                UserDefaults.standard.set(Double(size.width), forKey: "widget_width_\(type.rawValue)")
                UserDefaults.standard.set(Double(size.height), forKey: "widget_height_\(type.rawValue)")
                break
            }
        }
    }
}

enum DesktopWidgetStyle: String, CaseIterable, Identifiable {
    case classic = "Classic Glass"
    case proMonitor = "Pro Monitor"
    case coreMatrix = "Core Matrix"
    case textList = "Stats Table"
    var id: String { self.rawValue }
}

struct MiniCircularGauge: View {
    let title: String
    let progress: Double
    let colors: [Color]
    
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.06), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: CGFloat(min(1.0, max(0.0, progress))))
                    .stroke(
                        LinearGradient(gradient: Gradient(colors: colors), startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(Angle(degrees: -90))
                
                Text(String(format: "%.0f%%", progress * 100))
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(width: 44, height: 44)
            
            Text(title)
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(width: 56, height: 56)
    }
}

struct DesktopWidgetView: View {
    @ObservedObject var model: TelemetryModel
    @ObservedObject var manager: DesktopWidgetManager
    let type: DesktopWidgetType
    
    @AppStorage private var styleRaw: String
    @State private var isHovered = false
    
    @AppStorage("widget_united_show_cpu") private var unitedShowCpu = true
    @AppStorage("widget_united_show_gpu") private var unitedShowGpu = true
    @AppStorage("widget_united_show_ram") private var unitedShowRam = true
    @AppStorage("widget_united_show_disk") private var unitedShowDisk = true
    @AppStorage("widget_united_show_net") private var unitedShowNet = false
    @AppStorage("widget_united_show_fan") private var unitedShowFan = false
    
    struct UnitedItem: Identifiable {
        let id: String
        let title: String
        let progress: Double
        let colors: [Color]
        let valueString: String
        let historyValue: (TelemetryPoint) -> Double
        let type: DesktopWidgetType
    }
    
    var activeUnitedItems: [UnitedItem] {
        var items: [UnitedItem] = []
        if unitedShowCpu {
            items.append(UnitedItem(
                id: "cpu",
                title: "CPU",
                progress: model.cpuLoadAvg / 100.0,
                colors: [DesktopWidgetType.cpu.color1, DesktopWidgetType.cpu.color2],
                valueString: String(format: "%.1f°C", model.cpuTempC),
                historyValue: { $0.cpuLoad },
                type: .cpu
            ))
        }
        if unitedShowGpu {
            items.append(UnitedItem(
                id: "gpu",
                title: "GPU",
                progress: model.gpuLoadPct / 100.0,
                colors: [DesktopWidgetType.gpu.color1, DesktopWidgetType.gpu.color2],
                valueString: String(format: "%.1f°C", model.gpuTempC),
                historyValue: { $0.gpuLoad },
                type: .gpu
            ))
        }
        if unitedShowRam {
            items.append(UnitedItem(
                id: "ram",
                title: "RAM",
                progress: model.ramUsagePct / 100.0,
                colors: [DesktopWidgetType.ram.color1, DesktopWidgetType.ram.color2],
                valueString: {
                    let totalGB = Double(ProcessInfo.processInfo.physicalMemory) / (1024.0 * 1024.0 * 1024.0)
                    let usedGB = (model.ramUsagePct / 100.0) * totalGB
                    return String(format: "%.1f GB", usedGB)
                }(),
                historyValue: { $0.ramUsagePct },
                type: .ram
            ))
        }
        if unitedShowDisk {
            items.append(UnitedItem(
                id: "disk",
                title: "Disk",
                progress: model.diskUsagePct / 100.0,
                colors: [DesktopWidgetType.disk.color1, DesktopWidgetType.disk.color2],
                valueString: String(format: "%.0f%%", model.diskUsagePct),
                historyValue: { min(100.0, $0.diskReadMBps + $0.diskWriteMBps) }, // Capped to 100 MB/s max
                type: .disk
            ))
        }
        if unitedShowNet {
            items.append(UnitedItem(
                id: "net",
                title: "Net",
                progress: {
                    let totalMBps = model.netDownloadMBps + model.netUploadMBps
                    return min(1.0, totalMBps / 10.0)
                }(),
                colors: [DesktopWidgetType.net.color1, DesktopWidgetType.net.color2],
                valueString: {
                    let totalSpeed = model.netDownloadMBps + model.netUploadMBps
                    if totalSpeed >= 1.0 {
                        return String(format: "%.1f M/s", totalSpeed)
                    } else {
                        return String(format: "%.0f K/s", totalSpeed * 1024.0)
                    }
                }(),
                historyValue: { min(100.0, (($0.netDownloadMBps + $0.netUploadMBps) / 10.0) * 100.0) }, // Normalized to 10 MB/s max
                type: .net
            ))
        }
        if unitedShowFan {
            items.append(UnitedItem(
                id: "fan",
                title: "Fan",
                progress: {
                    let maxRPM: Double = 5000.0
                    let currentRPM = Double(model.fans.first?.rpm ?? 0)
                    return min(1.0, currentRPM / maxRPM)
                }(),
                colors: [DesktopWidgetType.fan.color1, DesktopWidgetType.fan.color2],
                valueString: {
                    let rpm = model.fans.first?.rpm ?? 0
                    return rpm > 0 ? "\(rpm) RPM" : "0 RPM"
                }(),
                historyValue: { min(100.0, (Double($0.fanRPM) / 5000.0) * 100.0) }, // Normalized to 5000 RPM max
                type: .fan
            ))
        }
        return items
    }
    
    init(model: TelemetryModel, manager: DesktopWidgetManager, type: DesktopWidgetType) {
        self.model = model
        self.manager = manager
        self.type = type
        self._styleRaw = AppStorage(wrappedValue: DesktopWidgetStyle.classic.rawValue, "widget_style_v2_\(type.rawValue)")
    }
    
    var style: DesktopWidgetStyle {
        let s = DesktopWidgetStyle(rawValue: styleRaw) ?? .classic
        if s == .coreMatrix && type != .cpu { return .classic } // Matrix only for CPU
        return s
    }
    
    var valuePct: Double {
        switch type {
        case .cpu: return model.cpuLoadAvg
        case .gpu: return model.gpuLoadPct
        case .ram: return model.ramUsagePct
        case .disk: return model.diskUsagePct
        case .net:
            let totalMBps = model.netDownloadMBps + model.netUploadMBps
            return min(100.0, (totalMBps / 10.0) * 100.0)
        case .fan:
            let maxRPM: Double = 5000.0
            let currentRPM = Double(model.fans.first?.rpm ?? 0)
            return min(100.0, (currentRPM / maxRPM) * 100.0)
        case .clock:
            let calendar = Calendar.current
            let minutes = Double(calendar.component(.minute, from: Date()))
            return (minutes / 60.0) * 100.0
        case .united:
            return model.cpuLoadAvg
        }
    }
    
    var valueString: String {
        switch type {
        case .cpu: return String(format: "%.1f°C", model.cpuTempC)
        case .gpu: return String(format: "%.1f°C", model.gpuTempC)
        case .ram: 
            let usedGB = (model.ramUsagePct / 100.0) * (Double(ProcessInfo.processInfo.physicalMemory) / (1024.0 * 1024.0 * 1024.0))
            return String(format: "%.1f GB", usedGB)
        case .disk:
            return String(format: "%.0f%%", model.diskUsagePct)
        case .net:
            let totalSpeed = model.netDownloadMBps + model.netUploadMBps
            if totalSpeed >= 1.0 {
                return String(format: "%.1f MB/s", totalSpeed)
            } else {
                return String(format: "%.0f KB/s", totalSpeed * 1024.0)
            }
        case .fan:
            let rpm = model.fans.first?.rpm ?? 0
            return rpm > 0 ? "\(rpm) RPM" : "0 RPM"
        case .clock:
            let fmt = DateFormatter()
            fmt.dateFormat = "HH:mm"
            return fmt.string(from: Date())
        case .united:
            return ""
        }
    }
    
    var isMonochrome: Bool {
        return false
    }
    
    private func titleForType(_ type: DesktopWidgetType) -> String {
        switch type {
        case .cpu: return NSLocalizedString("CPU", comment: "")
        case .gpu: return NSLocalizedString("GPU", comment: "")
        case .ram: return NSLocalizedString("RAM", comment: "")
        case .disk: return NSLocalizedString("Disk", comment: "")
        case .net: return NSLocalizedString("Network", comment: "")
        case .fan: return NSLocalizedString("Fan", comment: "")
        case .clock: return NSLocalizedString("Clock", comment: "")
        case .united: return NSLocalizedString("United", comment: "")
        }
    }
    
    private func symbolForType(_ type: DesktopWidgetType) -> String {
        switch type {
        case .cpu: return "cpu.fill"
        case .gpu: return "display"
        case .ram: return "memorycard.fill"
        case .disk: return "internaldrive.fill"
        case .net: return "network"
        case .fan: return "fan.fill"
        case .clock: return "clock.fill"
        case .united: return "square.grid.2x2.fill"
        }
    }
    
    var body: some View {
        Group {
            switch style {
            case .classic:
                classicStyle
            case .proMonitor:
                proMonitorStyle
            case .coreMatrix:
                coreMatrixStyle
            case .textList:
                textListStyle
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16)
        .background(
            VisualEffectBackground(material: .hudWindow, blendingMode: .behindWindow, state: .active, cornerRadius: 24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.04), lineWidth: 1)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(manager.isEditingWidgets ? Color.blue : Color.clear, style: StrokeStyle(lineWidth: manager.isEditingWidgets ? 3 : 1, dash: manager.isEditingWidgets ? [5] : []))
        )
        .grayscale(isMonochrome ? 1.0 : 0.0)
        .opacity(manager.isEditingWidgets ? 0.9 : 1.0)
        .onHover { h in
            withAnimation(.easeInOut(duration: 0.2)) { isHovered = h }
            model.isAnyWidgetHovered = h
        }
        .onChange(of: styleRaw) { newValue in
            let newStyle = DesktopWidgetStyle(rawValue: newValue) ?? .classic
            manager.resizeWidget(type: type, style: newStyle)
        }
        .contextMenu {
            Text("Widget Style")
            Divider()
            ForEach(DesktopWidgetStyle.allCases) { s in
                if s == .coreMatrix && type != .cpu {
                    // Skip
                } else {
                    Button(action: { styleRaw = s.rawValue }) {
                        HStack {
                            Text(s.rawValue)
                            if style == s { Image(systemName: "checkmark") }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Styles
    
    private var classicStyle: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: symbolForType(type))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(type.color1)
                Text(titleForType(type))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            if type == .united {
                let items = activeUnitedItems
                if items.isEmpty {
                    Text("No metrics active").font(.system(size: 9)).foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    let colCount = items.count > 2 ? 2 : items.count
                    let columns = Array(repeating: GridItem(.fixed(56), spacing: 8), count: colCount)
                    LazyVGrid(columns: columns, spacing: 6) {
                        ForEach(items) { item in
                            MiniCircularGauge(title: item.title, progress: item.progress, colors: item.colors)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            } else {
                HStack {
                    Spacer()
                    ZStack {
                        Circle().stroke(Color.white.opacity(0.06), lineWidth: 6)
                        Circle()
                            .trim(from: 0, to: CGFloat(min(1.0, max(0.0, valuePct / 100.0))))
                            .stroke(
                                LinearGradient(gradient: Gradient(colors: [type.color1, type.color2]), startPoint: .topLeading, endPoint: .bottomTrailing),
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .rotationEffect(Angle(degrees: -90))
                        
                        VStack(spacing: 0) {
                            if type == .clock {
                                let clockStrings = getClockStrings()
                                Text(clockStrings.time)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text(clockStrings.day)
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))
                            } else {
                                Text(String(format: "%.0f%%", valuePct))
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text(valueString)
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    .frame(width: 80, height: 80)
                    Spacer()
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var proMonitorStyle: some View {
        HStack(spacing: 16) {
            classicStyle
            
            VStack(alignment: .leading, spacing: 6) {
                if type == .clock {
                    MiniCalendarView()
                } else {
                    Text("Real-time History")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                    
                    if #available(macOS 13.0, *) {
                        let yMax: Double = {
                            switch type {
                            case .cpu, .gpu, .ram, .united:
                                return 100.0
                            case .disk:
                                let maxVal = model.history.map { $0.diskReadMBps + $0.diskWriteMBps }.max() ?? 10.0
                                return max(10.0, maxVal)
                            case .fan:
                                let maxVal = model.history.map { $0.fanRPM }.max() ?? 2000.0
                                return max(1500.0, maxVal)
                            case .net:
                                let maxVal = model.history.map { $0.netDownloadMBps + $0.netUploadMBps }.max() ?? 1.0
                                return max(1.0, maxVal)
                            case .clock:
                                return 100.0
                            }
                        }()
                        let yMin: Double = 0.0
                        let xMin = model.history.first?.time ?? 0.0
                        let xMax = model.history.last?.time ?? 1.0
                        
                        Chart {
                            ForEach(model.history) { point in
                                if type == .united {
                                    ForEach(activeUnitedItems) { item in
                                        LineMark(
                                            x: .value("Time", point.time),
                                            y: .value(item.title, item.historyValue(point))
                                        )
                                        .interpolationMethod(.catmullRom)
                                        .foregroundStyle(item.colors[0])
                                    }
                                } else {
                                    let val: Double = {
                                        switch type {
                                        case .cpu: return point.cpuLoad
                                        case .gpu: return point.gpuLoad
                                        case .ram: return point.ramUsagePct
                                        case .disk: return point.diskReadMBps + point.diskWriteMBps
                                        case .fan: return point.fanRPM
                                        case .net: return point.netDownloadMBps + point.netUploadMBps
                                        case .clock, .united: return 0.0
                                        }
                                    }()
                                    
                                    LineMark(
                                        x: .value("Time", point.time),
                                        y: .value("Value", val)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [type.color1, type.color2]), startPoint: .leading, endPoint: .trailing))
                                    
                                    AreaMark(
                                        x: .value("Time", point.time),
                                        y: .value("Value", val)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [type.color1.opacity(0.12), Color.clear]), startPoint: .top, endPoint: .bottom))
                                }
                            }
                        }
                        .chartXScale(domain: xMin...xMax)
                        .chartXAxis(.hidden)
                        .chartYAxis {
                            let values: [Double] = [0.0, yMax / 2.0, yMax]
                            AxisMarks(position: .leading, values: values) { value in
                                AxisValueLabel() {
                                    if let doubleVal = value.as(Double.self) {
                                        switch type {
                                        case .cpu, .gpu, .ram, .united:
                                            Text(String(format: "%.0f%%", doubleVal)).font(.system(size: 7)).foregroundColor(.white.opacity(0.4))
                                        case .disk:
                                            Text(String(format: "%.1f M/s", doubleVal)).font(.system(size: 7)).foregroundColor(.white.opacity(0.4))
                                        case .net:
                                            if doubleVal >= 1.0 {
                                                Text(String(format: "%.1f M/s", doubleVal)).font(.system(size: 7)).foregroundColor(.white.opacity(0.4))
                                            } else {
                                                Text(String(format: "%.0f K/s", doubleVal * 1024.0)).font(.system(size: 7)).foregroundColor(.white.opacity(0.4))
                                            }
                                        case .fan:
                                            Text(String(format: "%.0f", doubleVal)).font(.system(size: 7)).foregroundColor(.white.opacity(0.4))
                                        case .clock:
                                            Text(String(format: "%.0f%%", doubleVal)).font(.system(size: 7)).foregroundColor(.white.opacity(0.4))
                                        }
                                    }
                                }
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2])).foregroundStyle(Color.white.opacity(0.1))
                            }
                        }
                        .chartYScale(domain: yMin...yMax)
                    } else {
                        Text("Charts require macOS 13+").font(.system(size: 10)).foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private var coreMatrixStyle: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "cpu.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(type.color1)
                Text(NSLocalizedString("AMD CPU Cores", comment: ""))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                Text(String(format: "Avg: %.0f%%", valuePct))
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(type.color1)
            }
            
            Spacer()
            
            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 8)
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(0..<model.cores.count, id: \.self) { i in
                    let load = Double(model.cores[i].loadPct)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(load > 80 ? Color.red : (load > 40 ? Color.orange : type.color1))
                        .opacity(0.2 + (load / 100.0) * 0.8)
                        .frame(height: 12)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var textListStyle: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: symbolForType(type))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(type.color1)
                Text(titleForType(type))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.bottom, 2)
            
            Spacer()
            
            textListContent
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var textListContent: some View {
        switch type {
        case .cpu:
            VStack(spacing: 2) {
                StatListRow(label: "Avg Load", value: String(format: "%.1f%%", model.cpuLoadAvg))
                StatListRow(label: "Temp", value: String(format: "%.1f°C", model.cpuTempC))
                StatListRow(label: "Power", value: String(format: "%.1f W", model.cpuWatts))
                StatListRow(label: "Max Freq", value: String(format: "%.2f GHz", model.cpuFreqMaxGHz))
                StatListRow(label: "Uptime", value: model.systemUptimeFormatted)
            }
        case .gpu:
            VStack(spacing: 2) {
                StatListRow(label: "GPU Load", value: String(format: "%.1f%%", model.gpuLoadPct))
                StatListRow(label: "Temp", value: String(format: "%.1f°C", model.gpuTempC))
                StatListRow(label: "Power", value: String(format: "%.1f W", model.gpuPowerW))
                StatListRow(label: "VRAM Used", value: String(format: "%.1f GB", model.gpuVramUsedBytes / (1024*1024*1024)))
            }
        case .ram:
            VStack(spacing: 2) {
                let ram = getRamStats()
                StatListRow(label: "Used RAM", value: ram.used)
                StatListRow(label: "Free RAM", value: ram.free)
                StatListRow(label: "Swap Total", value: formatBytes(model.ramSwapTotalBytes))
                StatListRow(label: "Swap Used", value: formatBytes(model.ramSwapUsedBytes))
            }
        case .disk:
            VStack(spacing: 2) {
                StatListRow(label: "Disk Usage", value: String(format: "%.1f%%", model.diskUsagePct))
                StatListRow(label: "Read Speed", value: formatSpeed(model.diskReadMBps))
                StatListRow(label: "Write Speed", value: formatSpeed(model.diskWriteMBps))
            }
        case .net:
            VStack(spacing: 2) {
                StatListRow(label: "Upload", value: formatSpeed(model.netUploadMBps))
                StatListRow(label: "Download", value: formatSpeed(model.netDownloadMBps))
                StatListRow(label: "Interface", value: model.netActiveInterface)
                StatListRow(label: "IP Address", value: model.netLocalIP)
            }
        case .fan:
            VStack(spacing: 2) {
                ForEach(0..<min(3, model.fans.count), id: \.self) { idx in
                    StatListRow(label: "Fan \(idx + 1)", value: "\(model.fans[idx].rpm) RPM")
                }
                if model.fans.isEmpty {
                    StatListRow(label: "Fan 1", value: "0 RPM")
                }
            }
        case .clock:
            let clock = getClockTextListStrings()
            VStack(spacing: 2) {
                StatListRow(label: "Local Time", value: clock.local)
                StatListRow(label: "UTC Time", value: clock.utc)
                StatListRow(label: "Weekday", value: clock.weekday)
            }
        case .united:
            VStack(spacing: 2) {
                let items = activeUnitedItems
                if items.isEmpty {
                    Text("No metrics active").font(.system(size: 9)).foregroundColor(.white.opacity(0.5))
                } else {
                    ForEach(items) { item in
                        StatListRow(label: item.title, value: {
                            if item.type == .cpu {
                                return String(format: "%.1f%% (%.0f°C)", model.cpuLoadAvg, model.cpuTempC)
                            } else if item.type == .gpu {
                                return String(format: "%.1f%% (%.0f°C)", model.gpuLoadPct, model.gpuTempC)
                            } else if item.type == .ram {
                                return String(format: "%.1f%%", model.ramUsagePct)
                            } else if item.type == .disk {
                                return String(format: "%.1f%%", model.diskUsagePct)
                            } else {
                                return item.valueString
                            }
                        }())
                    }
                }
            }
        }
    }
    
    private func getClockStrings() -> (time: String, day: String) {
        let date = Date()
        let fmtTime = DateFormatter()
        fmtTime.dateFormat = "HH:mm"
        let fmtDay = DateFormatter()
        fmtDay.dateFormat = "d MMM"
        return (fmtTime.string(from: date), fmtDay.string(from: date))
    }
    
    private func getClockTextListStrings() -> (local: String, utc: String, weekday: String) {
        let date = Date()
        let fmtTime = DateFormatter()
        fmtTime.dateFormat = "HH:mm:ss"
        let fmtUTC = DateFormatter()
        fmtUTC.timeZone = TimeZone(abbreviation: "UTC")
        fmtUTC.dateFormat = "HH:mm:ss"
        let fmtDay = DateFormatter()
        fmtDay.dateFormat = "EEEE"
        return (fmtTime.string(from: date), fmtUTC.string(from: date), fmtDay.string(from: date).capitalized)
    }
    
    private func getRamStats() -> (used: String, free: String, total: String, pct: String) {
        let totalGB = Double(ProcessInfo.processInfo.physicalMemory) / (1024.0 * 1024.0 * 1024.0)
        let usedGB = (model.ramUsagePct / 100.0) * totalGB
        let freeGB = totalGB - usedGB
        return (
            String(format: "%.1f GB", usedGB),
            String(format: "%.1f GB", freeGB),
            String(format: "%.1f GB", totalGB),
            String(format: "%.1f%%", model.ramUsagePct)
        )
    }
    
    private func formatSpeed(_ mbps: Double) -> String {
        let bytesPerSec = mbps * 1024.0 * 1024.0
        if bytesPerSec >= 1024.0 * 1024.0 {
            return String(format: "%.1f MB/s", bytesPerSec / (1024.0 * 1024.0))
        } else if bytesPerSec >= 1.0 {
            return String(format: "%.1f KB/s", bytesPerSec / 1024.0)
        } else {
            return "0 KB/s"
        }
    }
    
    private func formatBytes(_ bytes: Double) -> String {
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
}

struct StatListRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
            Spacer()
            Text(value)
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.vertical, 1)
    }
}

struct MiniCalendarView: View {
    let date = Date()
    let calendar = Calendar.current
    
    var daysInMonth: [Int?] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: date),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))
        else { return [] }
        
        let weekdayOfFirst = calendar.component(.weekday, from: firstDayOfMonth)
        let startOffset = (weekdayOfFirst + 5) % 7
        
        var days: [Int?] = Array(repeating: nil, count: startOffset)
        for day in monthRange {
            days.append(day)
        }
        return days
    }
    
    var weekdays: [String] {
        var symbols = calendar.veryShortWeekdaySymbols
        if !symbols.isEmpty {
            let first = symbols.removeFirst()
            symbols.append(first)
        }
        return symbols
    }
    
    var body: some View {
        VStack(spacing: 3) {
            Text(monthName.uppercased())
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.orange)
            
            HStack(spacing: 4) {
                ForEach(0..<weekdays.count, id: \.self) { idx in
                    Text(weekdays[idx])
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                        .frame(width: 14)
                }
            }
            
            let columns = Array(repeating: GridItem(.fixed(14), spacing: 4), count: 7)
            let today = calendar.component(.day, from: date)
            
            LazyVGrid(columns: columns, spacing: 3) {
                ForEach(0..<daysInMonth.count, id: \.self) { idx in
                    if let day = daysInMonth[idx] {
                        Text("\(day)")
                            .font(.system(size: 7, weight: day == today ? .bold : .medium))
                            .foregroundColor(day == today ? .black : .white)
                            .frame(width: 14, height: 14)
                            .background(day == today ? Color.orange : Color.clear)
                            .cornerRadius(7)
                    } else {
                        Text("")
                            .frame(width: 14, height: 14)
                    }
                }
            }
        }
    }
    
    private var monthName: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM"
        return fmt.string(from: date)
    }
}
