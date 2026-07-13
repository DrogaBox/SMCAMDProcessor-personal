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
import Combine

// MARK: - Refresh Rate Config
class RefreshRateConfig: ObservableObject {
    static let shared = RefreshRateConfig()
    private let ud = UserDefaults.standard

    /// User-selected sampling interval (seconds). Honored as-is by TelemetryModel.
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
@MainActor
class StatusbarController: NSObject, NSMenuDelegate, NSPopoverDelegate {

    var statusItem: NSStatusItem!
    fileprivate var view: StatusbarView!

    var updateTimer: Timer?
    var statusBarButton: NSStatusBarButton?
    private var customPanel: NSPanel!
    private var eventMonitor: Any?
    
    var menu: NSMenu?
    private var telemetrySubscription: AnyCancellable?

    private var smcReady = false
    private var numFans = 0

    private var peakTemp: Float = 0
    private var peakPower: Float = 0
    private var peakFreq: Float = 0
    private var peakFan: UInt64 = 0

    private var lowestTemp: Float = Float.greatestFiniteMagnitude
    private var lowestPower: Float = Float.greatestFiniteMagnitude
    private var lowestFreq: Float = Float.greatestFiniteMagnitude
    private var lowestFan: UInt64 = UInt64.max

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
        
        if let button = statusItem.button {
            button.wantsLayer = true
            button.addSubview(view)
            button.cell?.usesSingleLineMode = false // Allow stacked multi-line custom views
            button.target = self
            button.action = #selector(itemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        // Setup custom panel instead of NSPopover for edge-to-edge custom coloring
        let hostingController = NSHostingController(rootView: MenuBarPopoverView())
        
        customPanel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 340, height: 600),
                              styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
                              backing: .buffered,
                              defer: false)
        customPanel.isFloatingPanel = true
        customPanel.level = .statusBar
        customPanel.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]
        customPanel.backgroundColor = .clear
        customPanel.isOpaque = false
        customPanel.hasShadow = true
        customPanel.contentViewController = hostingController
        
        updateLength()
        if let btn = statusItem.button {
            view?.frame = btn.bounds
        }

        addMenuItems()

        restartTimer()

        // Listen for config changes and telemetry updates
        NotificationCenter.default.addObserver(self, selector: #selector(updateLength), name: .init("MenuBarConfigChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(closePopover), name: .init("CloseMenuBarPopover"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(rebuildPopoverTheme), name: .init("AppThemeChanged"), object: nil)
        
        // objectWillChange already hops to main via receive(on:) — avoid double async enqueue
        telemetrySubscription = TelemetryModel.shared.objectWillChange
            .receive(on: RunLoop.main)
            .throttle(for: .milliseconds(200), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] _ in
                self?.update()
            }

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
        if customPanel != nil {
            // Panel behavior is handled manually via eventMonitor and pin open config
        }
        update()
    }

    func dismiss() {
        updateTimer?.invalidate()
        updateTimer = nil
        TelemetryModel.shared.setStatusbarActive(false)
        
        // Cancel Combine subscription to prevent memory leak
        telemetrySubscription?.cancel()
        telemetrySubscription = nil
        
        // Remove global event monitor to prevent memory leak
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        
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
        if temperature > 0 {
            if lowestTemp == Float.greatestFiniteMagnitude || temperature < lowestTemp {
                lowestTemp = temperature
            }
        }
        
        if power > peakPower { peakPower = power }
        if power > 0 {
            if lowestPower == Float.greatestFiniteMagnitude || power < lowestPower {
                lowestPower = power
            }
        }
        
        if maxFre > peakFreq { peakFreq = maxFre }
        if maxFre > 0 {
            if lowestFreq == Float.greatestFiniteMagnitude || maxFre < lowestFreq {
                lowestFreq = maxFre
            }
        }

        let fanIdx = max(0, MenuBarConfig.shared.fanIndex)
        let currentFan: UInt64 = (fanIdx < tm.fans.count) ? tm.fans[fanIdx].rpm : 0
        if currentFan > peakFan { peakFan = currentFan }
        if currentFan > 0 {
            if lowestFan == UInt64.max || currentFan < lowestFan {
                lowestFan = currentFan
            }
        }

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
                    if customPanel.isVisible {
                        closePopover()
                    } else {
                        // Force the custom panel window to align perfectly below the status bar button in screen coordinates
                        if let buttonWindow = button.window {
                            let rectInWindow = button.convert(button.bounds, to: nil)
                            let buttonRectInScreen = buttonWindow.convertToScreen(rectInWindow)
                            
                            if let host = customPanel.contentViewController as? NSHostingController<MenuBarPopoverView> {
                                let targetSize = host.sizeThatFits(in: NSSize(width: 340, height: 10000))
                                customPanel.setContentSize(NSSize(width: 340, height: targetSize.height))
                            }
                            
                            var panelFrame = customPanel.frame
                            
                            // Set vertical position exactly 2pt below the status bar button
                            panelFrame.origin.y = buttonRectInScreen.origin.y - panelFrame.height - 4
                            
                            // Center horizontally relative to the button
                            let buttonCenterX = buttonRectInScreen.origin.x + buttonRectInScreen.width / 2
                            panelFrame.origin.x = buttonCenterX - panelFrame.width / 2
                            
                            // Clamp horizontally to the screen's visible frame (multi-monitor safe)
                            if let screen = buttonWindow.screen {
                                let screenFrame = screen.visibleFrame
                                let minX = screenFrame.origin.x + 8
                                let maxX = screenFrame.origin.x + screenFrame.width - panelFrame.width - 8
                                panelFrame.origin.x = max(minX, min(maxX, panelFrame.origin.x))
                            }
                            
                            customPanel.setFrame(panelFrame, display: true, animate: false)
                        }
                        
                        customPanel.makeKeyAndOrderFront(nil)
                        NSApp.activate(ignoringOtherApps: true)
                        TelemetryModel.shared.setPopoverVisible(true)
                        
                        // Setup global monitor to dismiss panel when clicking outside
                        if eventMonitor == nil && !MenuBarConfig.shared.popoverPinOpen {
                            eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
                                if !MenuBarConfig.shared.popoverPinOpen {
                                    self?.closePopover()
                                }
                            }
                        }
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
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        if customPanel.isVisible {
            customPanel.orderOut(nil)
            TelemetryModel.shared.setPopoverVisible(false)
        }
    }

    /// Rebuild SwiftUI root when app theme changes (RTL-aligned presets).
    @objc func rebuildPopoverTheme() {
        let wasPinned = MenuBarConfig.shared.popoverPinOpen
        if let host = customPanel.contentViewController as? NSHostingController<MenuBarPopoverView> {
            host.rootView = MenuBarPopoverView()
        }
        
        if wasPinned && !customPanel.isVisible {
            if statusItem.button != nil {
                itemClicked() // Re-trigger open to reposition if needed
            }
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
        lowestTemp = Float.greatestFiniteMagnitude
        lowestPower = Float.greatestFiniteMagnitude
        lowestFreq = Float.greatestFiniteMagnitude
        lowestFan = UInt64.max
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

    @objc func toggleKeepAwake(_ sender: NSMenuItem) {
        CaffeinateManager.shared.toggle()
        sender.state = CaffeinateManager.shared.isAwake ? .on : .off
    }
    
    @objc func keepAwakeFor(_ sender: NSMenuItem) {
        guard let hours = sender.representedObject as? Double else { return }
        CaffeinateManager.shared.keepAwakeFor(hours: hours)
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
        var displayLowestTemp = lowestTemp
        var unitStr = "°C"
        if MenuBarConfig.shared.useFahrenheit {
            displayPeakTemp = peakTemp * 9.0 / 5.0 + 32.0
            if lowestTemp != Float.greatestFiniteMagnitude {
                displayLowestTemp = lowestTemp * 9.0 / 5.0 + 32.0
            }
            unitStr = "°F"
        }
        
        let tempMinStr = lowestTemp == Float.greatestFiniteMagnitude ? "--" : String(format: "%.1f\(unitStr)", displayLowestTemp)
        let tempStr = "Peak Temp: \(String(format: "%.1f\(unitStr)", displayPeakTemp))  |  Min: \(tempMinStr)"
        let tempItem = NSMenuItem(title: tempStr, action: nil, keyEquivalent: "")
        tempItem.isEnabled = false
        peaksMenu.addItem(tempItem)

        let pwrMinStr = lowestPower == Float.greatestFiniteMagnitude ? "--" : String(format: "%.1f W", lowestPower)
        let pwrStr = "Peak Power: \(String(format: "%.1f W", peakPower))  |  Min: \(pwrMinStr)"
        let pwrItem = NSMenuItem(title: pwrStr, action: nil, keyEquivalent: "")
        pwrItem.isEnabled = false
        peaksMenu.addItem(pwrItem)

        let freqMinStr = lowestFreq == Float.greatestFiniteMagnitude ? "--" : String(format: "%.2f GHz", lowestFreq * 0.001)
        let freqStr = "Peak Freq: \(String(format: "%.2f GHz", peakFreq * 0.001))  |  Min: \(freqMinStr)"
        let freqItem = NSMenuItem(title: freqStr, action: nil, keyEquivalent: "")
        freqItem.isEnabled = false
        peaksMenu.addItem(freqItem)

        if numFans > 0 {
            let fanMinStr = lowestFan == UInt64.max ? "--" : String(format: "%d RPM", lowestFan)
            let fanStr = "Peak Fan: \(peakFan) RPM  |  Min: \(fanMinStr)"
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
        
        // Caffeinate Submenu
        let caffeinateMenu = NSMenu()
        
        let toggleAwake = NSMenuItem(title: NSLocalizedString("Keep Awake", comment: ""), action: #selector(toggleKeepAwake(_:)), keyEquivalent: "")
        toggleAwake.target = self
        toggleAwake.state = CaffeinateManager.shared.isAwake ? .on : .off
        caffeinateMenu.addItem(toggleAwake)
        
        caffeinateMenu.addItem(NSMenuItem.separator())
        
        let times: [(String, Double)] = [
            ("For 1 Hour", 1.0),
            ("For 2 Hours", 2.0),
            ("For 4 Hours", 4.0),
            ("For 8 Hours", 8.0)
        ]
        
        for time in times {
            let timeItem = NSMenuItem(title: NSLocalizedString(time.0, comment: ""), action: #selector(keepAwakeFor(_:)), keyEquivalent: "")
            timeItem.target = self
            timeItem.representedObject = time.1
            caffeinateMenu.addItem(timeItem)
        }
        
        let caffeinateMenuItem = NSMenuItem(title: NSLocalizedString("Sleep Prevention", comment: ""), action: nil, keyEquivalent: "")
        caffeinateMenuItem.submenu = caffeinateMenu
        m.addItem(caffeinateMenuItem)
        
        m.addItem(NSMenuItem.separator())

        item = NSMenuItem(title: NSLocalizedString("Exit", comment: ""), action: #selector(exitApp), keyEquivalent: ""); item.target = self
        m.addItem(item)
    }

    @objc func togglePopover(_ sender: NSMenuItem) {
        MenuBarConfig.shared.enablePopover = !MenuBarConfig.shared.enablePopover
        sender.state = MenuBarConfig.shared.enablePopover ? .on : .off
        if !MenuBarConfig.shared.enablePopover && customPanel.isVisible {
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

