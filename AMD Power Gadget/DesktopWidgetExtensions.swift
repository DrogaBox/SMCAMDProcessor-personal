//
//  DesktopWidgetExtensions.swift
//  AMD Power Gadget
//
//  Extracted from StatusbarController.swift (2026) — Desktop Widget Views & Manager
//

import Cocoa
import SwiftUI
import Combine
import Charts

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
        let widgetWindow = DesktopWidgetWindow(
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
        for (_, otherWin) in widgetWindows {
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
    @AppStorage("widget_united_chart_style") private var unitedChartStyle = 0
    @AppStorage("widget_united_chart_metric") private var unitedChartMetric = "all"
    
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
            if type == .united && style == .proMonitor {
                Divider()
                Menu("Chart Metric") {
                    Button(action: { unitedChartMetric = "all" }) {
                        HStack { Text("All Combined"); if unitedChartMetric == "all" { Image(systemName: "checkmark") } }
                    }
                    Button(action: { unitedChartMetric = "cpu" }) {
                        HStack { Text("CPU Load"); if unitedChartMetric == "cpu" { Image(systemName: "checkmark") } }
                    }
                    Button(action: { unitedChartMetric = "gpu" }) {
                        HStack { Text("GPU Load"); if unitedChartMetric == "gpu" { Image(systemName: "checkmark") } }
                    }
                    Button(action: { unitedChartMetric = "ram" }) {
                        HStack { Text("RAM Usage"); if unitedChartMetric == "ram" { Image(systemName: "checkmark") } }
                    }
                    Button(action: { unitedChartMetric = "disk" }) {
                        HStack { Text("Disk I/O"); if unitedChartMetric == "disk" { Image(systemName: "checkmark") } }
                    }
                    Button(action: { unitedChartMetric = "net" }) {
                        HStack { Text("Network Speed"); if unitedChartMetric == "net" { Image(systemName: "checkmark") } }
                    }
                }
                Menu("Chart Type") {
                    Button(action: { unitedChartStyle = 0 }) {
                        HStack { Text("Smooth Curves"); if unitedChartStyle == 0 { Image(systemName: "checkmark") } }
                    }
                    Button(action: { unitedChartStyle = 1 }) {
                        HStack { Text("Filled Area"); if unitedChartStyle == 1 { Image(systemName: "checkmark") } }
                    }
                    Button(action: { unitedChartStyle = 2 }) {
                        HStack { Text("Column Bars"); if unitedChartStyle == 2 { Image(systemName: "checkmark") } }
                    }
                    Button(action: { unitedChartStyle = 3 }) {
                        HStack { Text("Line Only"); if unitedChartStyle == 3 { Image(systemName: "checkmark") } }
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
                        let indexedData = Array(model.history.enumerated())
                        let maxIndex = Double(max(1, indexedData.count - 1))
                        
                        Chart {
                            if type == .united {
                                let chartItems = unitedChartMetric == "all" ? activeUnitedItems : activeUnitedItems.filter { $0.id == unitedChartMetric }
                                ForEach(chartItems) { item in
                                    ForEach(indexedData, id: \.element.id) { index, point in
                                        let val = item.historyValue(point)
                                        if unitedChartStyle == 2 {
                                            BarMark(
                                                x: .value("Index", Double(index)),
                                                y: .value("Value", val)
                                            )
                                            .foregroundStyle(by: .value("Series", item.title))
                                        } else if unitedChartStyle == 1 {
                                            AreaMark(
                                                x: .value("Index", Double(index)),
                                                y: .value("Value", val)
                                            )
                                            .interpolationMethod(.catmullRom)
                                            .foregroundStyle(by: .value("Series", item.title))
                                        } else if unitedChartStyle == 3 {
                                            LineMark(
                                                x: .value("Index", Double(index)),
                                                y: .value("Value", val)
                                            )
                                            .interpolationMethod(.catmullRom)
                                            .foregroundStyle(by: .value("Series", item.title))
                                            .lineStyle(StrokeStyle(lineWidth: 1.5))
                                        } else {
                                            LineMark(
                                                x: .value("Index", Double(index)),
                                                y: .value("Value", val)
                                            )
                                            .interpolationMethod(.catmullRom)
                                            .foregroundStyle(by: .value("Series", item.title))
                                            .lineStyle(StrokeStyle(lineWidth: 1.5))
                                            
                                            AreaMark(
                                                x: .value("Index", Double(index)),
                                                y: .value("Value", val)
                                            )
                                            .interpolationMethod(.catmullRom)
                                            .foregroundStyle(by: .value("Series", item.title))
                                            .opacity(0.12)
                                        }
                                    }
                                }
                            } else {
                                ForEach(indexedData, id: \.element.id) { index, point in
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
                                        x: .value("Index", Double(index)),
                                        y: .value("Value", val)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [type.color1, type.color2]), startPoint: .leading, endPoint: .trailing))
                                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                                    
                                    AreaMark(
                                        x: .value("Index", Double(index)),
                                        y: .value("Value", val)
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [type.color1.opacity(0.12), Color.clear]), startPoint: .top, endPoint: .bottom))
                                }
                            }
                        }
                        .chartForegroundStyleScale([
                            "CPU": DesktopWidgetType.cpu.color1,
                            "GPU": DesktopWidgetType.gpu.color1,
                            "RAM": DesktopWidgetType.ram.color1,
                            "Disk": DesktopWidgetType.disk.color1,
                            "Net": DesktopWidgetType.net.color1,
                            "Fan": DesktopWidgetType.fan.color1
                        ])
                        .chartXScale(domain: 0...maxIndex)
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

class DesktopWidgetWindow: NSWindow {
    let gridSize: CGFloat = 20.0
    
    override func setFrameOrigin(_ newOrigin: NSPoint) {
        let snappedX = round(newOrigin.x / gridSize) * gridSize
        let snappedY = round(newOrigin.y / gridSize) * gridSize
        super.setFrameOrigin(NSPoint(x: snappedX, y: snappedY))
    }
    
    override func setFrame(_ frameRect: NSRect, display flag: Bool) {
        let snappedX = round(frameRect.origin.x / gridSize) * gridSize
        let snappedY = round(frameRect.origin.y / gridSize) * gridSize
        var newRect = frameRect
        newRect.origin = NSPoint(x: snappedX, y: snappedY)
        super.setFrame(newRect, display: flag)
    }
    
    override func setFrame(_ frameRect: NSRect, display displayFlag: Bool, animate animateFlag: Bool) {
        let snappedX = round(frameRect.origin.x / gridSize) * gridSize
        let snappedY = round(frameRect.origin.y / gridSize) * gridSize
        var newRect = frameRect
        newRect.origin = NSPoint(x: snappedX, y: snappedY)
        super.setFrame(newRect, display: displayFlag, animate: animateFlag)
    }
}
