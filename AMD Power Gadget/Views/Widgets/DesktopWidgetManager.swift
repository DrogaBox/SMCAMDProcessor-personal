//
// Auto-extracted during Phase 2 restructure
//

import Cocoa
import SwiftUI
import Combine

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

