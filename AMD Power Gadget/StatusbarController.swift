//
//  MenubarController.swift
//  AMD Power Gadget
//
//  Created by trulyspinach on 7/29/21.
//  Modified by Droga (2026) — Compact classic layout + configurable items
//

import Cocoa
import SwiftUI

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
            NSAttributedString.Key.font: NSFont(name: "Monaco", size: 7.2)!,
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
            let fan = fanRPM > 0 ? String(fanRPM) : "—"
            let fanColor: NSColor = .labelColor
            
            if cfg.showGPU && cfg.showGPUfan {
                let gFanStr = gpuFanRPM > 0 ? String(format: "G:%.0f", gpuFanRPM) : "G:—"
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
        view.frame = statusItem.button!.bounds

        addMenuItems()

        restartTimer()

        // Listen for config changes
        NotificationCenter.default.addObserver(self, selector: #selector(updateLength), name: .init("MenuBarConfigChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(closePopover), name: .init("CloseMenuBarPopover"), object: nil)
    }

    @objc func restartTimer() {
        updateTimer?.invalidate()
        let baseInterval = RefreshRateConfig.shared.interval
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: baseInterval, repeats: true, block: { [weak self] _ in
            self?.update()
        })
    }

    @objc func updateLength() {
        let w = MenuBarConfig.shared.totalWidth
        statusItem.length = w
        view?.frame = statusItem.button?.bounds ?? NSRect(x: 0, y: 0, width: w, height: 22)
        update()
    }

    func dismiss() {
        updateTimer?.invalidate()
        NSStatusBar.system.removeStatusItem(statusItem!)
        statusItem = nil
    }

    // MARK: - Cached GPU readings (3s cache)
    private var cachedGPUTemp: Float = 0
    private var cachedGPUPower: Float = 0
    private var cachedGPUVram: Float = 0
    private var cachedGPUFanRPM: Float = 0
    private var lastGPUReadTime: Date = Date.distantPast
    private let gpuCacheInterval: TimeInterval = 3.0

    func update() {
        let numberOfCores = ProcessorModel.shared.getNumOfCore()
        let outputStr: [Float] = ProcessorModel.shared.getMetric(forced: false)

        guard outputStr.count > numberOfCores + 2 else { return }

        let power = outputStr[0]
        let temperature = outputStr[1]
        var frequencies: [Float] = []
        for i in 0...(numberOfCores - 1) {
            frequencies.append(outputStr[Int(i + 3)])
        }

        let meanFre = Float(frequencies.reduce(0, +) / Float(frequencies.count))
        let maxFre = frequencies.max() ?? 0

        if temperature > peakTemp { peakTemp = temperature }
        if power > peakPower { peakPower = power }
        if maxFre > peakFreq { peakFreq = maxFre }

        let now = Date()
        if now.timeIntervalSince(lastGPUReadTime) >= gpuCacheInterval {
            let rawGPUTemp = ProcessorModel.shared.getGPUTemp()
            let rawGPUPower = ProcessorModel.shared.getGPUPower()
            let rawGPUVram = ProcessorModel.shared.getGPUVramUsed()
            let rawGPUFan = ProcessorModel.shared.getGPUFanRPM()
            if rawGPUTemp > 0 { cachedGPUTemp = rawGPUTemp }
            if rawGPUPower > 0 { cachedGPUPower = rawGPUPower }
            cachedGPUVram = rawGPUVram
            cachedGPUFanRPM = rawGPUFan
            lastGPUReadTime = now
        }

        view?.meanFreq = meanFre
        view?.maxFreq = maxFre
        view?.temp = temperature
        view?.pwr = power
        view?.gpuTemp = cachedGPUTemp
        view?.gpuPwr = cachedGPUPower
        view?.gpuVram = Double(cachedGPUVram)
        view?.gpuFanRPM = cachedGPUFanRPM

        // Extra items
        // Fan: read from AMDRyzenCPUPowerManagement kext
        let fanIdx = max(0, MenuBarConfig.shared.fanIndex)
        
        if smcReady {
            if numFans > 0 {
                let rpms = ProcessorModel.shared.kernelGetUInt64(count: numFans, selector: 93)
                let currentFan = (fanIdx < rpms.count) ? rpms[fanIdx] : 0
                view?.fanRPM = currentFan
                if currentFan > peakFan { peakFan = currentFan }
            } else {
                view?.fanRPM = 0
            }
        } else {
            view?.fanRPM = 0
        }

        if let memStr = ProcessorModel.shared.systemConfig["mem"], let totalMB = Int(memStr) {
            let freeMB = getFreeMemoryMB()
            view?.memoryUsed = Float(totalMB - freeMB) / 1024.0
            view?.totalMemory = String(format: "%.0fG", Float(totalMB) / 1024.0)
        } else {
            view?.memoryUsed = 0
            view?.totalMemory = "0G"
        }

        if MenuBarConfig.shared.showNetwork {
            if let netSnap = NetworkStats.shared.update() {
                view?.netUpload = netSnap.uploadMBps
                view?.netDownload = netSnap.downloadMBps
            }
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
    
    @objc func exitApp() { exit(0) }

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