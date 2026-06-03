//
//  MenubarController.swift
//  AMD Power Gadget
//
//  Created by trulyspinach on 7/29/21.
//  Modified by Droga (2026) — Compact classic layout + configurable items
//

import Cocoa

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
        interval = max(0.1, min(5.0, ud.double(forKey: "refresh_interval")))
        if ud.object(forKey: "refresh_interval") == nil {
            interval = 0.7
            ud.set(0.7, forKey: "refresh_interval")
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

    private let ud = UserDefaults.standard

    init() {
        if ud.object(forKey: "mb_showCPU")     == nil { ud.set(true,  forKey: "mb_showCPU")     }
        if ud.object(forKey: "mb_showTemp")    == nil { ud.set(true,  forKey: "mb_showTemp")    }
        if ud.object(forKey: "mb_showPower")   == nil { ud.set(true,  forKey: "mb_showPower")   }
        if ud.object(forKey: "mb_showGPU")     == nil { ud.set(true,  forKey: "mb_showGPU")     }
        if ud.object(forKey: "mb_showGPUtemp") == nil { ud.set(true,  forKey: "mb_showGPUtemp") }
        if ud.object(forKey: "mb_showGPUpwr")  == nil { ud.set(true,  forKey: "mb_showGPUpwr")  }
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
                drawCompactSingle(label: "CPU", val: "\(maxFr)G", color: cpuColor, x: x)
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
            let fanLabel = "F" + String(cfg.fanIndex + 1)
            let fanColor: NSColor = .labelColor
            
            drawCompactDoubleColored(label: fanLabel, up: fan, upColor: fanColor, down: "RPM", downColor: .labelColor, x: x)
            x += 54
        }

        // MEMORY column
        if cfg.showMemory {
            let used = String(format: "%.1fG", memoryUsed)
            let memColor: NSColor = .labelColor
            
            drawCompactDoubleColored(label: "MEM", up: used, upColor: memColor, down: totalMemory, downColor: .labelColor, x: x)
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

class StatusbarController: NSObject, NSMenuDelegate {

    var statusItem: NSStatusItem!
    fileprivate var view: StatusbarView!

    var updateTimer: Timer?
    var menu: NSMenu?

    override init() {
        super.init()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.isVisible = true

        view = StatusbarView()
        view.setup()
        statusItem.button?.wantsLayer = true
        statusItem.button?.addSubview(view)

        statusItem.button?.target = self
        statusItem.button?.action = #selector(itemClicked)
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

        updateLength()
        view.frame = statusItem.button!.bounds

        addMenuItems()

        updateTimer = Timer.scheduledTimer(withTimeInterval: RefreshRateConfig.shared.interval, repeats: true, block: { _ in
            self.update()
        })

        // Listen for config changes
        NotificationCenter.default.addObserver(self, selector: #selector(updateLength), name: .init("MenuBarConfigChanged"), object: nil)
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
    private var lastGPUReadTime: Date = Date.distantPast
    private let gpuCacheInterval: TimeInterval = 3.0

    func update() {
        let numberOfCores = ProcessorModel.shared.getNumOfCore()
        let outputStr: [Float] = ProcessorModel.shared.getMetric(forced: false)

        let power = outputStr[0]
        let temperature = outputStr[1]
        var frequencies: [Float] = []
        for i in 0...(numberOfCores - 1) {
            frequencies.append(outputStr[Int(i + 3)])
        }

        let meanFre = Float(frequencies.reduce(0, +) / Float(frequencies.count))
        let maxFre = Float(frequencies.max()!)

        let now = Date()
        if now.timeIntervalSince(lastGPUReadTime) >= gpuCacheInterval {
            let rawGPUTemp = ProcessorModel.shared.getGPUTemp()
            let rawGPUPower = ProcessorModel.shared.getGPUPower()
            if rawGPUTemp > 0 { cachedGPUTemp = rawGPUTemp }
            if rawGPUPower > 0 { cachedGPUPower = rawGPUPower }
            lastGPUReadTime = now
        }

        view?.meanFreq = meanFre
        view?.maxFreq = maxFre
        view?.temp = temperature
        view?.pwr = power
        view?.gpuTemp = cachedGPUTemp
        view?.gpuPwr = cachedGPUPower

        // Extra items
        // Fan: read from AMDRyzenCPUPowerManagement kext
        let fanIdx = max(0, MenuBarConfig.shared.fanIndex)
        let initRes = ProcessorModel.shared.kernelGetUInt64(count: 2, selector: 90)
        let smcReady = initRes.count > 0 && initRes[0] == 1
        
        if smcReady {
            let numFans = Int(ProcessorModel.shared.kernelGetUInt64(count: 1, selector: 91).first ?? 0)
            if numFans > 0 {
                let rpms = ProcessorModel.shared.kernelGetUInt64(count: numFans, selector: 93)
                view?.fanRPM = (fanIdx < rpms.count) ? rpms[fanIdx] : 0
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
            NSApp.activate(ignoringOtherApps: true)
            ViewController.launch(forceFocus: true)
        case .rightMouseUp:
            if let m = menu {
                m.delegate = self
                statusItem.menu = m
                statusItem.button?.performClick(nil)
            }
        default: break
        }
    }

    func menuDidClose(_ menu: NSMenu) {
        statusItem.menu = nil
    }

    func menuWillOpen(_ menu: NSMenu) {
        addMenuItems()
    }

    @objc func gadget() { ViewController.launch(forceFocus: true) }
    @objc func tool()  { PowerToolViewController.launch(forceFocus: true) }
    @objc func fans()  { SystemMonitorViewController.launch(forceFocus: true) }
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

    private func addMenuItems() {
        if menu == nil {
            menu = NSMenu()
        } else {
            menu?.removeAllItems()
        }
        guard let m = menu else { return }
        var item = NSMenuItem(title: NSLocalizedString("AMD Power Gadget", comment: ""), action: #selector(gadget), keyEquivalent: ""); item.target = self
        m.addItem(item)
        item = NSMenuItem(title: NSLocalizedString("AMD Power Tool", comment: ""), action: #selector(tool), keyEquivalent: ""); item.target = self
        m.addItem(item)
        item = NSMenuItem(title: NSLocalizedString("SMC Fans", comment: ""), action: #selector(fans), keyEquivalent: ""); item.target = self
        m.addItem(item)
        
        m.addItem(NSMenuItem.separator())
        
        // Colores Dinámicos (Solo Temp)
        let alertsItem = NSMenuItem(title: NSLocalizedString("Colores Dinámicos (Solo Temp)", comment: ""), action: #selector(toggleColorAlerts(_:)), keyEquivalent: "")
        alertsItem.target = self
        alertsItem.state = MenuBarConfig.shared.enableColorAlerts ? .on : .off
        m.addItem(alertsItem)

        let tempColorSubmenu = NSMenu()
        let colorsList = ["Verde", "Azul", "Naranja", "Rojo", "Morado", "Rosa", "Turquesa"]
        for (idx, colorName) in colorsList.enumerated() {
            let localizedColor = NSLocalizedString(colorName, comment: "")
            let colorItem = NSMenuItem(title: localizedColor, action: #selector(changeTempColor(_:)), keyEquivalent: "")
            colorItem.target = self
            colorItem.tag = idx
            colorItem.state = (MenuBarConfig.shared.tempColorIdx == idx) ? .on : .off
            tempColorSubmenu.addItem(colorItem)
        }
        let tempColorMenuItem = NSMenuItem(title: NSLocalizedString("Color de Alerta de Temp", comment: ""), action: nil, keyEquivalent: "")
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
        let tempLimitMenuItem = NSMenuItem(title: NSLocalizedString("Límite de Temp de Alerta", comment: ""), action: nil, keyEquivalent: "")
        tempLimitMenuItem.submenu = tempLimitSubmenu
        m.addItem(tempLimitMenuItem)
        
        m.addItem(NSMenuItem.separator())
        
        let colorSubmenu = NSMenu()
        let colors = ["Verde", "Azul", "Naranja", "Rojo", "Morado", "Rosa", "Turquesa"]
        for (idx, colorName) in colors.enumerated() {
            let localizedColor = NSLocalizedString(colorName, comment: "")
            let colorItem = NSMenuItem(title: localizedColor, action: #selector(changeNetColor(_:)), keyEquivalent: "")
            colorItem.target = self
            colorItem.tag = idx
            colorItem.state = (MenuBarConfig.shared.netColorIdx == idx) ? .on : .off
            colorSubmenu.addItem(colorItem)
        }
        let colorMenuItem = NSMenuItem(title: NSLocalizedString("Color de Flechas de Red", comment: ""), action: nil, keyEquivalent: "")
        colorMenuItem.submenu = colorSubmenu
        m.addItem(colorMenuItem)
        
        m.addItem(NSMenuItem.separator())
        item = NSMenuItem(title: NSLocalizedString("Exit", comment: ""), action: #selector(exitApp), keyEquivalent: ""); item.target = self
        m.addItem(item)
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