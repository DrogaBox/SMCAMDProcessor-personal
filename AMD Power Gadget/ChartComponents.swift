//
//  ChartComponents.swift
//  AMD Power Gadget
//
//  Extracted from MainDashboardView.swift (2026) — Reusable Chart Components
//  Enhanced with new lightweight chart styles (2026-07-14)
//

import SwiftUI
import Charts

// MARK: - Resizable Chart Wrapper with Native Right-Click Menu
//
// Uses NSMenu.popUpContextMenu() directly (AppKit) instead of SwiftUI's .contextMenu().
// SwiftUI's context menu is attached to the view lifecycle and flickers/dismisses when
// the chart content re-renders on every telemetry tick (~1s). The native NSMenu runs
// in AppKit's own menu tracking loop and is completely unaffected by SwiftUI updates.
//
struct ResizableChart<Content: View>: View {
    let chartId: String
    let small: CGFloat
    let medium: CGFloat
    let large: CGFloat
    @ViewBuilder let content: (CGFloat) -> Content

    @State private var currentHeight: CGFloat

    init(chartId: String, small: CGFloat = 60, medium: CGFloat = 100, large: CGFloat = 160, @ViewBuilder content: @escaping (CGFloat) -> Content) {
        self.chartId = chartId
        self.small = small
        self.medium = medium
        self.large = large
        self.content = content
        let saved = UserDefaults.standard.double(forKey: "chart_h_\(chartId)")
        _currentHeight = State(initialValue: saved > 0 ? CGFloat(saved) : medium)
    }

    var body: some View {
        content(currentHeight)
            .onReceive(NotificationCenter.default.publisher(for: .init("DashboardLayoutChanged"))) { _ in
                let saved = UserDefaults.standard.double(forKey: "chart_h_\(chartId)")
                if saved > 0 {
                    currentHeight = CGFloat(saved)
                }
            }
            .overlay(NativeContextMenuView(chartId: chartId))
    }

    private var cleanChartName: String {
        chartId
            .replacingOccurrences(of: "dash_", with: "")
            .replacingOccurrences(of: "_size", with: "")
            .replacingOccurrences(of: "mem", with: "memory")
            .replacingOccurrences(of: "net", with: "network")
    }

    private func setHeight(_ h: CGFloat) {
        currentHeight = h
        UserDefaults.standard.set(Double(h), forKey: "chart_h_\(chartId)")
    }
}

// MARK: - Native NSMenu Right-Click (Replaces SwiftUI .contextMenu)
//
// Architecture:
//   NativeContextMenuView  (NSViewRepresentable) — sits in SwiftUI overlay
//     └─ MenuHostView      (NSView subclass)
//          └─ rightMouseDown → MenuCoordinator.buildMenu() → NSMenu.popUpContextMenu()
//
// The coordinator stores the chart name and uses @objc selectors for NSMenuItem actions.
// All chart visibility/order/height state is read/written directly via UserDefaults,
// avoiding any @AppStorage bindings (which would couple the menu to SwiftUI's lifecycle).

/// NSViewRepresentable that overlays a right-click → NSMenu handler on any SwiftUI view.
/// The underlying NSView overrides `rightMouseDown(with:)` to show a context menu built
/// by `MenuCoordinator.buildMenu()`. Mouse-move and left-click events pass through
/// because the view does NOT set up an NSTrackingArea (so mouseMoved is not received)
/// and does NOT override `hitTest`, allowing AppKit to fall through normally.
struct NativeContextMenuView: NSViewRepresentable {
    let chartId: String

    func makeCoordinator() -> MenuCoordinator {
        MenuCoordinator(chartId: chartId)
    }

    func makeNSView(context: Context) -> NSView {
        let view = MenuHostView()
        view.coordinator = context.coordinator
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? MenuHostView)?.coordinator = context.coordinator
    }
}

/// Minimal NSView that intercepts right-clicks and shows an NSMenu.
/// Does NOT override hitTest — relies on default NSView.hitTest (returns self when point
/// is in bounds and the layer is valid). mouseMoved events are NOT received because
/// no NSTrackingArea is set up, so the chart's hover tracking (in its own overlay)
/// continues to work undisturbed.
class MenuHostView: NSView {
    weak var coordinator: MenuCoordinator?

    override func rightMouseDown(with event: NSEvent) {
        guard let coordinator = coordinator else {
            super.rightMouseDown(with: event)
            return
        }
        let menu = coordinator.buildMenu()
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }
}

/// Coordinator that builds an NSMenu with Size / Hide / Show / Move items,
/// matching the old ChartContextMenu's behavior. All UserDefaults keys match
/// the @AppStorage keys used elsewhere in the app.
class MenuCoordinator: NSObject {
    let chartId: String

    /// Normalized chart name (e.g. "freq", "temp", "pwr", "memory", "network", "cores")
    private var chartName: String {
        var name = chartId
            .replacingOccurrences(of: "dash_", with: "")
            .replacingOccurrences(of: "_size", with: "")
        if name == "mem" { name = "memory" }
        if name == "net" { name = "network" }
        return name
    }

    init(chartId: String) {
        self.chartId = chartId
    }

    // MARK: - Menu Actions

    @objc func sizeSmall()  { setHeight("small") }
    @objc func sizeMedium() { setHeight("medium") }
    @objc func sizeLarge()  { setHeight("large") }

    @objc func hideChart() { setVisibility(visible: false) }

    @objc func showFreq()  { UserDefaults.standard.set(true, forKey: "dash_showFreq") }
    @objc func showTemp()  { UserDefaults.standard.set(true, forKey: "dash_showTemp") }
    @objc func showPwr()   { UserDefaults.standard.set(true, forKey: "dash_showPwr") }
    @objc func showMem()   { UserDefaults.standard.set(true, forKey: "mb_showMem") }
    @objc func showNet()   { UserDefaults.standard.set(true, forKey: "mb_showNet") }
    @objc func showCores() { UserDefaults.standard.set(true, forKey: "dash_showCores") }

    @objc func moveLeft()  { moveChart(direction: -1) }
    @objc func moveRight() { moveChart(direction: 1) }
    @objc func moveUp()    { moveChart(direction: -1) }
    @objc func moveDown()  { moveChart(direction: 1) }

    // MARK: - Height

    private func setHeight(_ heightType: String) {
        // ⚠️  The key MUST match exactly what ResizableChart.init() reads:
        //       UserDefaults.standard.double(forKey: "chart_h_\(chartId)")
        let key = "chart_h_" + chartId
        let actualHeight: CGFloat
        switch chartName {
        case "memory":
            actualHeight = (heightType == "small") ? 130 : (heightType == "medium") ? 160 : 220
        case "cores":
            actualHeight = (heightType == "small") ? 300 : (heightType == "medium") ? 400 : 500
        default:
            actualHeight = (heightType == "small") ? 70 : (heightType == "medium") ? 100 : 150
        }
        UserDefaults.standard.set(Double(actualHeight), forKey: key)
        NotificationCenter.default.post(name: NSNotification.Name("DashboardLayoutChanged"), object: nil)
    }

    // MARK: - Visibility

    private func setVisibility(visible: Bool) {
        let key: String = {
            switch chartName {
            case "freq":    return "dash_showFreq"
            case "temp":    return "dash_showTemp"
            case "pwr":     return "dash_showPwr"
            case "memory":  return "mb_showMem"
            case "network": return "mb_showNet"
            case "cores":   return "dash_showCores"
            default:         return ""
            }
        }()
        if !key.isEmpty {
            UserDefaults.standard.set(visible, forKey: key)
        }
    }

    // MARK: - Reorder

    private func moveChart(direction: Int) {
        let normalizedId = chartName
        if ["freq", "temp", "pwr"].contains(normalizedId) {
            var arr = (UserDefaults.standard.string(forKey: "dash_chart_order") ?? "freq,temp,pwr")
                .split(separator: ",").map(String.init)
            if let idx = arr.firstIndex(of: normalizedId) {
                let newIdx = idx + direction
                if newIdx >= 0, newIdx < arr.count {
                    arr.swapAt(idx, newIdx)
                    UserDefaults.standard.set(arr.joined(separator: ","), forKey: "dash_chart_order")
                }
            }
        } else {
            let verticalId: String? = {
                if normalizedId.contains("mem") { return "memory" }
                if normalizedId.contains("net") { return "network" }
                if normalizedId.contains("cores") { return "cores" }
                return nil
            }()
            if let targetId = verticalId {
                var arr = (UserDefaults.standard.string(forKey: "dash_vertical_order") ?? "charts,memory,network,cores")
                    .split(separator: ",").map(String.init)
                if let idx = arr.firstIndex(of: targetId) {
                    let newIdx = idx + direction
                    if newIdx >= 0, newIdx < arr.count {
                        arr.swapAt(idx, newIdx)
                        UserDefaults.standard.set(arr.joined(separator: ","), forKey: "dash_vertical_order")
                    }
                }
            }
        }
    }

    // MARK: - Build Menu

    /// Builds a complete NSMenu with Size / Hide / Show / Move items.
    /// Called lazily from rightMouseDown — reads current UserDefaults values.
    func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false

        // ── Size submenu (disabled for Core Grid — fixed size) ──
        let sizeMenu = NSMenu()
        sizeMenu.addItem(withTitle: "Small",  action: #selector(sizeSmall),  keyEquivalent: "")
        sizeMenu.addItem(withTitle: "Medium", action: #selector(sizeMedium), keyEquivalent: "")
        sizeMenu.addItem(withTitle: "Large",  action: #selector(sizeLarge),  keyEquivalent: "")
        let sizeItem = NSMenuItem(title: "Size", action: nil, keyEquivalent: "")
        sizeItem.submenu = sizeMenu
        sizeItem.isEnabled = (chartName != "cores")
        menu.addItem(sizeItem)

        menu.addItem(NSMenuItem.separator())

        // ── Hide ──
        menu.addItem(withTitle: "Hide Chart", action: #selector(hideChart), keyEquivalent: "")

        // ── Show submenu (only if some charts are hidden) ──
        let showMenu = NSMenu()
        if !UserDefaults.standard.bool(forKey: "dash_showFreq") { showMenu.addItem(withTitle: "Frequency",  action: #selector(showFreq),  keyEquivalent: "") }
        if !UserDefaults.standard.bool(forKey: "dash_showTemp") { showMenu.addItem(withTitle: "Temperature", action: #selector(showTemp),  keyEquivalent: "") }
        if !UserDefaults.standard.bool(forKey: "dash_showPwr")  { showMenu.addItem(withTitle: "Power",       action: #selector(showPwr),   keyEquivalent: "") }
        if !UserDefaults.standard.bool(forKey: "mb_showMem")    { showMenu.addItem(withTitle: "Memory",      action: #selector(showMem),   keyEquivalent: "") }
        if !UserDefaults.standard.bool(forKey: "mb_showNet")    { showMenu.addItem(withTitle: "Network",     action: #selector(showNet),   keyEquivalent: "") }
        if !UserDefaults.standard.bool(forKey: "dash_showCores"){ showMenu.addItem(withTitle: "Core Grid",   action: #selector(showCores), keyEquivalent: "") }
        if showMenu.items.count > 0 {
            let showItem = NSMenuItem(title: "Show Chart", action: nil, keyEquivalent: "")
            showItem.submenu = showMenu
            menu.addItem(showItem)
        }

        menu.addItem(NSMenuItem.separator())

        // ── Move submenu ──
        let moveMenu = NSMenu()
        if ["freq", "temp", "pwr"].contains(chartName) {
            moveMenu.addItem(withTitle: "Move Left",  action: #selector(moveLeft),  keyEquivalent: "")
            moveMenu.addItem(withTitle: "Move Right", action: #selector(moveRight), keyEquivalent: "")
        } else {
            moveMenu.addItem(withTitle: "Move Up",   action: #selector(moveUp),   keyEquivalent: "")
            moveMenu.addItem(withTitle: "Move Down", action: #selector(moveDown), keyEquivalent: "")
        }
        let moveItem = NSMenuItem(title: "Move Position", action: nil, keyEquivalent: "")
        moveItem.submenu = moveMenu
        menu.addItem(moveItem)

        // Set target on all items recursively
        func setTarget(_ m: NSMenu) {
            for item in m.items {
                if item.hasSubmenu {
                    if let sub = item.submenu { setTarget(sub) }
                } else {
                    item.target = self
                }
            }
        }
        setTarget(menu)

        return menu
    }
}

// MARK: - New Lightweight Chart Styles (2026-07-14)

/// Lightweight area chart with gradient fill - optimized for low CPU usage
struct LightweightAreaChart: View {
    let data: [Double]
    let color: Color
    let minValue: Double?
    let maxValue: Double?
    
    init(data: [Double], color: Color, minValue: Double? = nil, maxValue: Double? = nil) {
        self.data = data
        self.color = color
        self.minValue = minValue
        self.maxValue = maxValue
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            guard data.count > 1 else {
                return AnyView(EmptyView())
            }
            
            let minY = minValue ?? data.min() ?? 0
            let maxY = maxValue ?? data.max() ?? 100
            let range = max(0.01, maxY - minY)
            
            let path = Path { path in
                let stepX = width / CGFloat(data.count - 1)
                
                // Start from bottom left
                path.move(to: CGPoint(x: 0, y: height))
                
                // Draw data points
                for (index, value) in data.enumerated() {
                    let x = CGFloat(index) * stepX
                    let normalizedY = CGFloat((value - minY) / range)
                    let y = height * (1.0 - normalizedY)
                    
                    if index == 0 {
                        path.addLine(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                
                // Close path at bottom right
                path.addLine(to: CGPoint(x: width, y: height))
                path.closeSubpath()
            }
            
            return AnyView(
                ZStack {
                    // Gradient fill
                    path
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.4), color.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    // Line stroke
                    path
                        .trim(from: 0, to: 1)
                        .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                }
            )
        }
    }
}

/// Compact gradient bar chart - minimal draw calls for maximum performance
struct CompactGradientBar: View {
    let value: Double
    let maxValue: Double
    let colors: [Color]
    let showPercentage: Bool
    
    init(value: Double, maxValue: Double = 100, colors: [Color], showPercentage: Bool = true) {
        self.value = value
        self.maxValue = maxValue
        self.colors = colors
        self.showPercentage = showPercentage
    }
    
    var body: some View {
        GeometryReader { geometry in
            let fillWidth = geometry.size.width * CGFloat(min(1.0, max(0.0, value / maxValue)))
            
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.05))
                
                // Gradient fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: fillWidth)
                
                // Percentage text
                if showPercentage {
                    Text(String(format: "%.0f%%", min(100, value)))
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

/// Minimalist sparkline - single color, minimal rendering
struct MinimalistSparkline: View {
    let values: [Double]
    let color: Color
    let lineWidth: CGFloat
    
    init(values: [Double], color: Color, lineWidth: CGFloat = 1.5) {
        self.values = values
        self.color = color
        self.lineWidth = lineWidth
    }
    
    var body: some View {
        GeometryReader { geometry in
            guard values.count > 1 else {
                return AnyView(EmptyView())
            }
            
            let minVal = values.min() ?? 0
            let maxVal = values.max() ?? 100
            let range = max(0.01, maxVal - minVal)
            
            let path = Path { path in
                let stepX = geometry.size.width / CGFloat(values.count - 1)
                
                for (index, value) in values.enumerated() {
                    let x = CGFloat(index) * stepX
                    let normalizedY = CGFloat((value - minVal) / range)
                    let y = geometry.size.height * (1.0 - normalizedY)
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            
            return AnyView(
                path
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            )
        }
    }
}

/// Circular progress indicator - single arc, efficient drawing
struct CircularProgressIndicator: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    let showText: Bool
    
    init(progress: Double, color: Color, lineWidth: CGFloat = 8, showText: Bool = true) {
        self.progress = progress
        self.color = color
        self.lineWidth = lineWidth
        self.showText = showText
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: lineWidth)
            
            // Progress arc
            Circle()
                .trim(from: 0, to: min(1.0, max(0.0, progress / 100.0)))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.2), value: progress)
            
            // Center text
            if showText {
                VStack(spacing: 2) {
                    Text(String(format: "%.0f", progress))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("%")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(lineWidth / 2)
    }
}

/// Heat map cell - for CPU core visualization with minimal overhead
struct HeatMapCell: View {
    let value: Double
    let maxValue: Double
    let colorGradient: [Color]
    
    init(value: Double, maxValue: Double = 100, colorGradient: [Color] = [.blue, .green, .yellow, .red]) {
        self.value = value
        self.maxValue = maxValue
        self.colorGradient = colorGradient
    }
    
    private var cellColor: Color {
        let normalized = min(1.0, max(0.0, value / maxValue))
        let index = Int(normalized * Double(colorGradient.count - 1))
        return colorGradient[min(index, colorGradient.count - 1)]
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(cellColor.opacity(0.8))
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
            )
    }
}

/// Compact line chart card with minimal decorations
struct CompactLineChartCard: View {
    let title: LocalizedStringKey
    let data: [Double]
    let color: Color
    let unit: String
    let height: CGFloat
    
    var currentValue: String {
        guard let last = data.last else { return "—" }
        return String(format: "%.1f%@", last, unit)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.tahoeSubtext)
                Spacer()
                Text(currentValue)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
            }
            
            MinimalistSparkline(values: data, color: color, lineWidth: 1.8)
                .frame(height: height)
        }
        .padding(12)
        .background(Color.tahoeCard)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.3), lineWidth: 1))
        .cornerRadius(10)
    }
}

// MARK: - Interactive Chart Components (v3.31.0)

/// Shared interaction state for Swift Charts-based charts.
/// Tracks hovered index for tooltip display and zoom state for range selection.
class ChartInteractionState: ObservableObject {
    @Published var hoveredIndex: Int? = nil
    @Published var hoveredLocation: CGPoint? = nil
    @Published var isPaused: Bool = false
    @Published var pausedSnapshot: [TelemetryPoint] = []
    @Published var zoomRange: ClosedRange<Int>? = nil
    
    var fullRange: ClosedRange<Int> {
        0...(max(0, dataCount - 1))
    }
    var dataCount: Int = 0
    
    var visibleRange: ClosedRange<Int> {
        zoomRange ?? fullRange
    }
    
    func resetZoom() {
        zoomRange = nil
        hoveredIndex = nil
    }
    
    func togglePause(currentData: [TelemetryPoint]) {
        isPaused.toggle()
        if isPaused {
            pausedSnapshot = currentData
        } else {
            pausedSnapshot = []
        }
    }
}

/// Floating tooltip overlay for chart hover interaction.
struct ChartTooltipView: View {
    let accent: Color
    let line1Label: LocalizedStringKey
    let line1Value: String
    let line2Label: LocalizedStringKey?
    let line2Value: String?
    let timestamp: Date
    
    init(accent: Color,
         line1Label: LocalizedStringKey, line1Value: String,
         line2Label: LocalizedStringKey? = nil, line2Value: String? = nil,
         timestamp: Date? = nil) {
        self.accent = accent
        self.line1Label = line1Label
        self.line1Value = line1Value
        self.line2Label = line2Label
        self.line2Value = line2Value
        self.timestamp = timestamp ?? Date()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            // Line 1
            HStack(spacing: 5) {
                Circle()
                    .fill(accent)
                    .frame(width: 5, height: 5)
                Text(line1Label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.tahoeSubtext)
                Text(line1Value)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(accent)
            }
            
            // Line 2 (optional, for dual-metric charts like Freq: avg+max)
            if let l2 = line2Label, let v2 = line2Value {
                HStack(spacing: 5) {
                    Circle()
                        .fill(accent.opacity(0.5))
                        .frame(width: 5, height: 5)
                    Text(l2)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.tahoeSubtext)
                    Text(v2)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(accent.opacity(0.8))
                }
            }
            
            // Timestamp
            Text(timestamp, style: .time)
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(.tahoeSubtext.opacity(0.7))
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.tahoeCardBorder, lineWidth: 0.5))
        )
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        .transition(.opacity.animation(.easeInOut(duration: 0.12)))
    }
}

/// NSView subclass with NSTrackingArea for fine-grained mouse tracking.
///
/// Behavior:
/// - On mouse movement: hides tooltip immediately, stores location, starts 0.3s debounce
/// - After 0.3s idle: shows tooltip at the stopped position
/// - On mouse exit: hides tooltip immediately (no delay — avoids interfering with context menus)
class TrackingNSView: NSView {
    var onMove: ((CGPoint) -> Void)?
    var onExit: (() -> Void)?
    private let debounceSeconds: TimeInterval = 0.3
    private var pendingLocation: CGPoint? = nil
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach { removeTrackingArea($0) }
        let options: NSTrackingArea.Options = [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect]
        let area = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(area)
    }
    
    override func mouseMoved(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        pendingLocation = location
        // Hide tooltip immediately on movement, cancel pending debounce
        onExit?()
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(handleHover), object: nil)
        perform(#selector(handleHover), with: nil, afterDelay: debounceSeconds)
    }
    
    override func mouseExited(with event: NSEvent) {
        // Hide tooltip immediately (no delay) — user left the chart area
        onExit?()
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(handleHover), object: nil)
        pendingLocation = nil
    }
    
    @objc private func handleHover() {
        guard let location = pendingLocation else { return }
        onMove?(location)
    }
}

/// NSViewRepresentable that wraps TrackingNSView for use inside chartOverlay.
/// Uses ChartProxy.value(atX:as:) for pixel-to-data-value conversion,
/// which is more reliable than manual linear interpolation.
struct ChartMouseTrackingView: NSViewRepresentable {
    let interaction: ChartInteractionState
    /// Closure created inside chartOverlay — captures fresh ChartProxy and chartWidth.
    /// Converts pixel X position → data index.
    let indexForX: (CGFloat) -> Int
    
    func makeNSView(context: Context) -> TrackingNSView {
        let view = TrackingNSView()
        view.onExit = { [weak interaction] in
            guard let interaction = interaction else { return }
            if interaction.hoveredIndex != nil {
                interaction.hoveredIndex = nil
                interaction.hoveredLocation = nil
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: TrackingNSView, context: Context) {
        // Re-create onMove on every update so it captures the LATEST indexForX closure
        // (which in turn captures a fresh ChartProxy from the chartOverlay).
        // Without this, the proxy captured at makeNSView time would be stale after
        // chart re-renders (new telemetry data arrives every second).
        let freshIndexForX = indexForX
        nsView.onMove = { [weak interaction] location in
            guard let interaction = interaction else { return }
            guard interaction.dataCount > 1 else { return }
            let clamped = freshIndexForX(location.x)
            // -1 means layout not ready — don't update tooltip, leave previous state
            guard clamped >= 0 else { return }
            interaction.hoveredIndex = clamped
            interaction.hoveredLocation = location
        }
    }
}

/// Modifier that attaches an NSTrackingArea-based hover overlay to a Swift Charts chart.
struct ChartHoverModifier: ViewModifier {
    @ObservedObject var interaction: ChartInteractionState
    
    init(interaction: ChartInteractionState, dataCount: Int) {
        self.interaction = interaction
        // CRITICAL: set dataCount so visibleRange computes correctly.
        // Without this, dataCount = 0 → fullRange = 0...0 → chartXScale(0...0) = vertical line.
        interaction.dataCount = dataCount
    }
    
    func body(content: Content) -> some View {
        content
            .chartOverlay { proxy in
                GeometryReader { geo in
                    ChartMouseTrackingView(
                        interaction: interaction,
                        indexForX: { x in
                            // CRITICAL: guard against 0 chartWidth when layout is not ready.
                            // Without this, max(1.0, 0) = 1.0 → ratio = x/1.0 for any x > 1,
                            // making the fallback always clamp to the last index.
                            // Charts not yet laid out (scrolled into view) can report 0 width.
                            guard geo.size.width > 1 else { return -1 }
                            if let value = proxy.value(atX: x, as: Double.self) {
                                let idx = Int(value.rounded())
                                return min(max(idx, 0), interaction.dataCount - 1)
                            }
                            // Fallback: linear interpolation if proxy fails
                            let ratio = x / geo.size.width
                            let idx = ratio * Double(interaction.dataCount - 1)
                            return min(max(Int(idx.rounded()), 0), interaction.dataCount - 1)
                        }
                    )
                }
            }
    }
}

extension View {
    /// Attach hover/touch interaction to a Swift Charts chart.
    /// Uses NSTrackingArea for mouse-move detection (no click required).
    /// - Parameters:
    ///   - interaction: The shared ChartInteractionState
    ///   - dataCount: Total number of data points
    func chartHover(interaction: ChartInteractionState, dataCount: Int) -> some View {
        self.modifier(ChartHoverModifier(interaction: interaction, dataCount: dataCount))
    }
}
