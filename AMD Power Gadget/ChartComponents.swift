//
//  ChartComponents.swift
//  AMD Power Gadget
//
//  Extracted from MainDashboardView.swift (2026) — Reusable Chart Components
//  Enhanced with new lightweight chart styles (2026-07-14)
//

import SwiftUI
import Charts

// MARK: - Resizable Chart Wrapper with Right-Click Menu
struct ResizableChart<Content: View>: View {
    let chartId: String
    let small: CGFloat
    let medium: CGFloat
    let large: CGFloat
    @ViewBuilder let content: (CGFloat) -> Content

    @State private var currentHeight: CGFloat
    @State private var showMenu = false

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
            .contextMenu { ChartContextMenu(chart: cleanChartName) }
            .onReceive(NotificationCenter.default.publisher(for: .init("DashboardLayoutChanged"))) { _ in
                let saved = UserDefaults.standard.double(forKey: "chart_h_\(chartId)")
                if saved > 0 {
                    currentHeight = CGFloat(saved)
                }
            }
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

// MARK: - Chart Context Menu
struct ChartContextMenu: View {
    let chart: String
    
    @AppStorage("dash_showFreq") var showFrequency = true
    @AppStorage("dash_showTemp") var showTemperature = true
    @AppStorage("dash_showPwr") var showPower = true
    @AppStorage("dash_showCores") var showCores = true
    @AppStorage("mb_showNet") var showNetwork = false
    @AppStorage("mb_showMem") var showMemory = true
    
    @AppStorage("dash_chart_order") var chartOrder = "freq,temp,pwr"
    @AppStorage("dash_vertical_order") var verticalOrder = "charts,memory,network,cores"

    var body: some View {
        Menu("Size") {
            Button("Small") { setChartHeight(for: chart, heightType: "small") }
            Button("Medium") { setChartHeight(for: chart, heightType: "medium") }
            Button("Large") { setChartHeight(for: chart, heightType: "large") }
        }
        
        Button("Hide Chart") {
            setChartVisibility(for: chart, visible: false)
        }
        
        let hasHiddenCharts = !showFrequency || !showTemperature || !showPower || !showMemory || !showNetwork || !showCores
        if hasHiddenCharts {
            Menu("Show Chart") {
                if !showFrequency { Button("Frequency") { showFrequency = true } }
                if !showTemperature { Button("Temperature") { showTemperature = true } }
                if !showPower { Button("Power") { showPower = true } }
                if !showMemory { Button("Memory") { showMemory = true } }
                if !showNetwork { Button("Network") { showNetwork = true } }
                if !showCores { Button("Core Grid") { showCores = true } }
            }
        }
        
        Menu("Move Position") {
            if ["freq", "temp", "pwr"].contains(chart) {
                Button("Move Left") { moveChart(chart, direction: -1) }
                Button("Move Right") { moveChart(chart, direction: 1) }
            } else {
                Button("Move Up") { moveChart(chart, direction: -1) }
                Button("Move Down") { moveChart(chart, direction: 1) }
            }
        }
    }

    private func setChartHeight(for chart: String, heightType: String) {
        let mappedChart = (chart == "network") ? "net" : chart
        let key = "chart_h_dash_" + (mappedChart == "memory" ? "mem_size" : mappedChart == "cores" ? "cores_size" : mappedChart)
        let actualHeight: CGFloat
        switch chart {
        case "memory":
            actualHeight = (heightType == "small") ? 130 : (heightType == "medium") ? 160 : 220
        case "cores":
            actualHeight = (heightType == "small") ? 300 : (heightType == "medium") ? 400 : 500
        default:
            actualHeight = (heightType == "small") ? 70 : (heightType == "medium") ? 100 : 150
        }
        UserDefaults.standard.set(Double(actualHeight), forKey: key)
        NotificationCenter.default.post(name: .init("DashboardLayoutChanged"), object: nil)
    }

    private func setChartVisibility(for chart: String, visible: Bool) {
        switch chart {
        case "freq": showFrequency = visible
        case "temp": showTemperature = visible
        case "pwr": showPower = visible
        case "memory": showMemory = visible
        case "network": showNetwork = visible
        case "cores": showCores = visible
        default: break
        }
    }

    private func moveChart(_ chart: String, direction: Int) {
        let normalizedId = chart.replacingOccurrences(of: "dash_", with: "")
        
        if ["freq", "temp", "pwr"].contains(normalizedId) {
            var arr = chartOrder.split(separator: ",").map(String.init)
            if let idx = arr.firstIndex(of: normalizedId) {
                let newIdx = idx + direction
                if newIdx >= 0 && newIdx < arr.count {
                    arr.swapAt(idx, newIdx)
                    chartOrder = arr.joined(separator: ",")
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
                var arr = verticalOrder.split(separator: ",").map(String.init)
                if let idx = arr.firstIndex(of: targetId) {
                    let newIdx = idx + direction
                    if newIdx >= 0 && newIdx < arr.count {
                        arr.swapAt(idx, newIdx)
                        verticalOrder = arr.joined(separator: ",")
                    }
                }
            }
        }
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
