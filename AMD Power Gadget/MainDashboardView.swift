//
//  MainDashboardView.swift
//  AMD Power Gadget
//
//  Created by Droga (2026) — SwiftUI Tahoe Redesign
//

import SwiftUI
import Charts
import Metal

// MARK: - Visual Effect Blur Background (macOS)
struct VisualEffectBackground: View {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    let state: NSVisualEffectView.State
    let cornerRadius: CGFloat
    
    @AppStorage("low_performance_mode") private var isLowPerformanceMode = false

    var body: some View {
        if isLowPerformanceMode {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.12)) // Solid dark fallback
        } else {
            VisualEffectNSView(material: material, blendingMode: blendingMode, state: state, cornerRadius: cornerRadius)
        }
    }
}

struct VisualEffectNSView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    let state: NSVisualEffectView.State
    let cornerRadius: CGFloat

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        view.wantsLayer = true
        view.layer?.cornerRadius = cornerRadius
        view.layer?.cornerCurve = .continuous
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
        nsView.layer?.cornerRadius = cornerRadius
    }
}

// MARK: - Design Tokens & Themes Engine
enum AppTheme: String, CaseIterable, Identifiable {
    case tahoe = "Tahoe Glass"
    case cyberpunk = "Cyberpunk Neon"
    case solarized = "Solarized Amber"
    case monochrome = "Monochrome Stealth"
    case nordic = "Nordic Frost"
    case custom = "Personalizado"
    
    var id: String { rawValue }

    static var current: AppTheme {
        if let raw = UserDefaults.standard.string(forKey: "app_theme_preset"), let theme = AppTheme(rawValue: raw) {
            return theme
        }
        return .tahoe
    }

    var card: Color {
        switch self {
        case .tahoe: return Color(red: 0.10, green: 0.12, blue: 0.17).opacity(0.82)
        case .cyberpunk: return Color(red: 0.12, green: 0.08, blue: 0.22).opacity(0.85)
        case .solarized: return Color(red: 0.15, green: 0.18, blue: 0.20).opacity(0.85)
        case .monochrome: return Color(red: 0.12, green: 0.12, blue: 0.12).opacity(0.85)
        case .nordic: return Color(red: 0.18, green: 0.22, blue: 0.28).opacity(0.85)
        case .custom:
            let hex = UserDefaults.standard.string(forKey: "custom_hex_card") ?? "#16213E"
            return Color(hexString: hex) ?? Color(red: 0.10, green: 0.12, blue: 0.17).opacity(0.82)
        }
    }

    var accentCyan: Color {
        switch self {
        case .tahoe: return Color(red: 0.0, green: 0.85, blue: 0.95)
        case .cyberpunk: return Color(red: 0.0, green: 0.96, blue: 1.0)
        case .solarized: return Color(red: 0.16, green: 0.63, blue: 0.60)
        case .monochrome: return Color(white: 0.90)
        case .nordic: return Color(red: 0.53, green: 0.75, blue: 0.82)
        case .custom:
            let hex = UserDefaults.standard.string(forKey: "custom_hex_cyan") ?? "#4CC9F0"
            return Color(hexString: hex) ?? Color(red: 0.0, green: 0.85, blue: 0.95)
        }
    }

    var accentOrange: Color {
        switch self {
        case .tahoe: return Color(red: 1.0, green: 0.55, blue: 0.10)
        case .cyberpunk: return Color(red: 1.0, green: 0.16, blue: 0.43)
        case .solarized: return Color(red: 0.80, green: 0.29, blue: 0.09)
        case .monochrome: return Color(white: 0.70)
        case .nordic: return Color(red: 0.82, green: 0.53, blue: 0.44)
        case .custom:
            let hex = UserDefaults.standard.string(forKey: "custom_hex_orange") ?? "#FF8C00"
            return Color(hexString: hex) ?? Color(red: 1.0, green: 0.55, blue: 0.10)
        }
    }

    var accentGreen: Color {
        switch self {
        case .tahoe: return Color(red: 0.1, green: 0.95, blue: 0.45)
        case .cyberpunk: return Color(red: 0.0, green: 1.0, blue: 0.5)
        case .solarized: return Color(red: 0.52, green: 0.60, blue: 0.0)
        case .monochrome: return Color(white: 0.80)
        case .nordic: return Color(red: 0.64, green: 0.75, blue: 0.55)
        case .custom:
            let hex = UserDefaults.standard.string(forKey: "custom_hex_green") ?? "#00FF7F"
            return Color(hexString: hex) ?? Color(red: 0.1, green: 0.95, blue: 0.45)
        }
    }

    var accentPurple: Color {
        switch self {
        case .tahoe: return Color(red: 0.65, green: 0.40, blue: 1.0)
        case .cyberpunk: return Color(red: 0.75, green: 0.0, blue: 1.0)
        case .solarized: return Color(red: 0.82, green: 0.21, blue: 0.51)
        case .monochrome: return Color(white: 0.60)
        case .nordic: return Color(red: 0.71, green: 0.55, blue: 0.66)
        case .custom:
            let hex = UserDefaults.standard.string(forKey: "custom_hex_purple") ?? "#A020F0"
            return Color(hexString: hex) ?? Color(red: 0.65, green: 0.40, blue: 1.0)
        }
    }
}

private extension Color {
    static var tahoeBackground   : Color { Color(red: 0.06, green: 0.07, blue: 0.10).opacity(0.72) }
    static var tahoeSidebar      : Color { Color(red: 0.08, green: 0.09, blue: 0.13).opacity(0.25) }
    static var tahoeCard         : Color { AppTheme.current.card }
    static var tahoeCardBorder   : Color { Color(white: 1.0, opacity: 0.07) }
    static var tahoeAccentCyan   : Color { AppTheme.current.accentCyan }
    static var tahoeAccentOrange : Color { AppTheme.current.accentOrange }
    static var tahoeAccentGreen  : Color { AppTheme.current.accentGreen }
    static var tahoeAccentPurple : Color { AppTheme.current.accentPurple }
    static var tahoeAccentRed    : Color { Color(red: 1.0,  green: 0.30, blue: 0.30) }
    static var tahoeAccentBlue   : Color { Color(red: 0.35, green: 0.55, blue: 1.0) }
    static var tahoeAccentYellow : Color { Color(red: 1.0,  green: 0.80, blue: 0.20) }
    static var tahoeText         : Color { Color(white: 0.90) }
    static var tahoeSubtext      : Color { Color(white: 0.50) }
    static var tahoeSidebarActive : Color { Color(red: 0.12, green: 0.15, blue: 0.24) }
}

enum DashboardTab: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case dashboard  = "Dashboard"
    case telemetry  = "Telemetry"
    case fanControl = "Fan Control"
    case themes     = "Temas & Apariencia"
    case profiles   = "Profiles"
    case advanced   = "Advanced"
    case menuBar    = "Menu Bar"
    case popover    = "Popover Menu"
    case desktopWidgets = "Desktop Widgets"
    case systemInfo = "System Info"
    case analysis   = "Análisis"

    var icon: String {
        switch self {
        case .dashboard:  return "gauge.medium"
        case .telemetry:  return "waveform.path.ecg"
        case .fanControl: return "fan"
        case .themes:     return "paintpalette"
        case .profiles:   return "slider.horizontal.3"
        case .advanced:   return "gearshape.2"
        case .menuBar:    return "menubar.rectangle"
        case .popover:    return "macwindow.badge.plus"
        case .desktopWidgets: return "square.grid.2x2"
        case .systemInfo: return "info.circle"
        case .analysis:   return "chart.xyaxis.line"
        }
    }
}

struct MainDashboardView: View {
    @ObservedObject var model: TelemetryModel

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(selectedTab: $model.selectedTab, model: model)
                .frame(width: 188)
            Divider().background(Color.tahoeCardBorder)
            ZStack {
                VisualEffectBackground(
                    material: .sidebar,
                    blendingMode: .behindWindow,
                    state: .active,
                    cornerRadius: 0
                )
                .ignoresSafeArea()
                contentForTab
                    .transition(.opacity)
            }
        }
        .background(
            VisualEffectBackground(
                material: .sidebar,
                blendingMode: .behindWindow,
                state: .active,
                cornerRadius: 0
            )
        )
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var contentForTab: some View {
        switch model.selectedTab {
        case .dashboard:  DashboardContentView(model: model)
        case .telemetry:  TelemetryContentView(model: model)
        case .fanControl: FanControlContentView(model: model)
        case .themes:     ThemesContentView()
        case .profiles:   ProfilesContentView(model: model)
        case .advanced:   AdvancedContentView(model: model)
        case .menuBar:    MenuBarConfigView(model: model)
        case .popover:    PopoverConfigView(model: model)
        case .desktopWidgets: DesktopWidgetsConfigView(model: model)
        case .systemInfo: SystemInfoContentView(model: model)
        case .analysis:   AnalysisContentView()
        }
    }
}

// MARK: - Sidebar
private struct SidebarView: View {
    @Binding var selectedTab: DashboardTab
    @ObservedObject var model: TelemetryModel

    var body: some View {
        ZStack {
            // Glass effect like Finder sidebar in macOS Tahoe
            VisualEffectBackground(
                material: .sidebar,
                blendingMode: .behindWindow,
                state: .active,
                cornerRadius: 0
            )
            .ignoresSafeArea()

            // Subtle tint overlay to match the dark glass aesthetic
            Color.tahoeSidebar.opacity(0.15)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("AMD Power").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundColor(.tahoeText)
                    Text("Gadget").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundColor(.tahoeAccentCyan)
                }
                .padding(.horizontal, 18).padding(.top, 24).padding(.bottom, 14)

                VStack(alignment: .leading, spacing: 5) {
                    TinyStatRow(label: "CPU", value: String(format: "%.1f°C / %.0fW", model.cpuTempC, model.cpuWatts), color: .tahoeAccentCyan)
                    TinyStatRow(label: "GPU", value: String(format: "%.1f°C / %.0fW", model.gpuTempC, model.gpuPowerW), color: .tahoeAccentOrange)
                    TinyStatRow(label: "Freq", value: String(format: "%.2f GHz", model.cpuFreqMaxGHz), color: .tahoeAccentGreen)
                }
                .padding(.horizontal, 12).padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.ultraThinMaterial)
                        .opacity(0.7)
                )
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.tahoeCardBorder))
                .cornerRadius(10)
                .padding(.horizontal, 10).padding(.bottom, 12)

                ForEach(DashboardTab.allCases) { tab in
                    SidebarItem(tab: tab, isSelected: selectedTab == tab) {
                        withAnimation(.easeInOut(duration: 0.15)) { selectedTab = tab }
                    }
                }
                Spacer()
                Link(destination: URL(string: "https://github.com/DrogaBox/SMCAMDProcessor-personal")!) {
                    Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.0.0") · macOS Tahoe")
                        .font(.system(size: 9, weight: .regular))
                        .foregroundColor(Color(white: 0.35))
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 14)
            }
        }
    }
}

private struct TinyStatRow: View {
    let label: String; let value: String; let color: Color
    var body: some View {
        HStack {
            Text(label).font(.system(size: 10, weight: .semibold)).foregroundColor(.tahoeSubtext).frame(width: 30, alignment: .leading)
            Text(value).font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundColor(color)
        }
    }
}

private struct SidebarItem: View {
    let tab: DashboardTab; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 2).fill(isSelected ? Color.tahoeAccentCyan : Color.clear).frame(width: 3, height: 20)
                Image(systemName: tab.icon).font(.system(size: 13, weight: .medium)).foregroundColor(isSelected ? .tahoeAccentCyan : .tahoeSubtext).frame(width: 18)
                Text(LocalizedStringKey(tab.rawValue)).font(.system(size: 13, weight: isSelected ? .semibold : .regular)).foregroundColor(isSelected ? .tahoeText : .tahoeSubtext)
                Spacer()
            }
            .padding(.vertical, 7).padding(.trailing, 12)
            .background(isSelected ? Color.tahoeSidebarActive : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Reusable Components
private struct SectionTitle: View {
    let text: LocalizedStringKey
    init(_ text: LocalizedStringKey) { self.text = text }
    var body: some View {
        Text(text).font(.system(size: 13, weight: .semibold)).foregroundColor(.tahoeText).padding(.bottom, 2)
    }
}

private struct InfoRow: View {
    let label: LocalizedStringKey; let value: String
    var body: some View {
        HStack {
            Text(label).font(.system(size: 12, weight: .medium)).foregroundColor(.tahoeSubtext)
            Spacer()
            Text(value).font(.system(size: 12, weight: .semibold, design: .monospaced)).foregroundColor(.tahoeText).multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
    }
}

private struct TahoeCard<Content: View>: View {
    let accent: Color
    @ViewBuilder let content: Content
    @AppStorage("theme_glass_material") private var glassMaterial: Int = 0

    init(accent: Color = .tahoeCardBorder, @ViewBuilder content: () -> Content) {
        self.accent = accent; self.content = content()
    }

    private var materialStyle: Material {
        switch glassMaterial {
        case 1: return .thinMaterial
        case 2: return .regularMaterial
        case 3: return .thickMaterial
        default: return .ultraThinMaterial
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.tahoeCard)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(materialStyle)
                    )
            )
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent, lineWidth: 1))
            .cornerRadius(14)
    }
}

private struct TahoeButton: View {
    let label: LocalizedStringKey; let icon: String; let accent: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon).font(.system(size: 12, weight: .semibold))
                Text(label).font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(accent)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity)
            .background(accent.opacity(0.12))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(accent.opacity(0.35)))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

private struct ToggleRow: View {
    let label: LocalizedStringKey; let detail: LocalizedStringKey; @Binding var isOn: Bool; let accent: Color; let onChange: (Bool) -> Void
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                Text(detail).font(.system(size: 10)).foregroundColor(.tahoeSubtext)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: accent))
                .labelsHidden()
                .onChange(of: isOn) { newValue in onChange(newValue) }
        }
        .padding(.vertical, 8).padding(.horizontal, 14)
        .background(Color.tahoeCard)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.tahoeCardBorder))
        .cornerRadius(8)
    }
}

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
            .contextMenu {
                Button("Small (\(Int(small))pt)") { setHeight(small) }
                Button("Medium (\(Int(medium))pt)") { setHeight(medium) }
                Button("Large (\(Int(large))pt)") { setHeight(large) }
            }
    }

    private func setHeight(_ h: CGFloat) {
        currentHeight = h
        UserDefaults.standard.set(Double(h), forKey: "chart_h_\(chartId)")
    }
}

// MARK: - Dashboard Tab (3 charts separados, tamaño configurable)
// MARK: - WIP Placeholder Card
struct WIPCard: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey

    var body: some View {
        TahoeCard(accent: Color.gray.opacity(0.15)) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(Color.gray.opacity(0.5))
                        Text(subtitle)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.gray.opacity(0.35))
                    }
                    Spacer()
                    Text("WIP")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(Color.gray.opacity(0.4))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.gray.opacity(0.12))
                        .cornerRadius(4)
                }

                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.05))
                    .frame(height: 100)
                    .overlay(
                        HStack(spacing: 6) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color.gray.opacity(0.3))
                            Text("Disabled — work in progress")
                                .font(.system(size: 11))
                                .foregroundColor(Color.gray.opacity(0.3))
                        }
                    )
            }
        }
    }
}

struct DashboardContentView: View {
    @ObservedObject var model: TelemetryModel
    @AppStorage("mb_showNet") private var showNetwork: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    StatCard(label: "CPU Temp",  value: String(format: "%.1f°C",   model.cpuTempC),     accent: .tahoeAccentCyan,   icon: "thermometer.medium")
                    StatCard(label: "CPU Power", value: String(format: "%.1fW",    model.cpuWatts),     accent: .tahoeAccentOrange, icon: "bolt.fill")
                    StatCard(label: "GPU Temp",  value: String(format: "%.1f°C",   model.gpuTempC),     accent: .tahoeAccentGreen,  icon: "cpu.fill")
                    StatCard(label: "GPU Power", value: String(format: "%.1fW",    model.gpuPowerW),    accent: .tahoeAccentPurple, icon: "bolt.square.fill")
                }

                HStack(alignment: .top, spacing: 12) {
                    ResizableChart(chartId: "dash_freq", small: 70, medium: 100, large: 150) { height in
                        OriginalLineChartCard(
                            title: "Frequency",
                            subtitle: String(format: NSLocalizedString("Avg: %.2f Ghz, Max: %.2f Ghz", comment: ""),
                                             locale: Locale.current, model.cpuFreqAvgGHz, model.cpuFreqMaxGHz),
                            accent: .tahoeAccentCyan,
                            data: model.history,
                            line1: { $0.cpuFreqGHz },
                            line2: { $0.cpuFreqMaxGHz },
                            line1Label: "Avg",
                            line2Label: "Max",
                            height: height
                        )
                    }
                    .frame(maxHeight: .infinity, alignment: .top)

                    ResizableChart(chartId: "dash_temp", small: 70, medium: 100, large: 150) { height in
                        OriginalLineChartCard(
                            title: "Temperature",
                            subtitle: String(format: NSLocalizedString("%.2f °C", comment: ""),
                                             locale: Locale.current, model.cpuTempC),
                            accent: .tahoeAccentOrange,
                            data: model.history,
                            line1: { $0.cpuTempC },
                            line2: nil,
                            line1Label: "CPU",
                            line2Label: nil,
                            height: height
                        )
                    }
                    .frame(maxHeight: .infinity, alignment: .top)

                    ResizableChart(chartId: "dash_pwr", small: 70, medium: 100, large: 150) { height in
                        OriginalLineChartCard(
                            title: "Power",
                            subtitle: String(format: NSLocalizedString("%.2f Watt", comment: ""),
                                             locale: Locale.current, model.cpuWatts),
                            accent: .tahoeAccentGreen,
                            data: model.history,
                            line1: { $0.cpuWatts },
                            line2: nil,
                            line1Label: "Package",
                            line2Label: nil,
                            height: height
                        )
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                }

                if showNetwork {
                    ResizableChart(chartId: "dash_net", small: 70, medium: 100, large: 150) { height in
                        NetworkLineChartCard(
                            title: "Network Throughput",
                            model: model,
                            height: height
                        )
                    }
                }

                CoreGridCard(model: model)
            }
            .padding(18)
        }
    }
}

private struct StatCard: View {
    let label: LocalizedStringKey; let value: String; let accent: Color; let icon: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon).font(.system(size: 12)).foregroundColor(accent)
                Text(label).font(.system(size: 11, weight: .medium)).foregroundColor(.tahoeSubtext)
            }
            Text(value).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(.tahoeText)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.tahoeCard)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
        )
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(accent.opacity(0.18)))
        .cornerRadius(12)
    }
}

// MARK: - Original-style Line Chart Card
struct OriginalLineChartCard: View {
    let title: LocalizedStringKey
    let subtitle: String
    let accent: Color
    let data: [TelemetryPoint]
    let line1: (TelemetryPoint) -> Double
    let line2: ((TelemetryPoint) -> Double)?
    let line1Label: LocalizedStringKey
    let line2Label: LocalizedStringKey?
    let height: CGFloat

    @AppStorage("app_chart_style") private var selectedChartStyleRaw: String = AppChartStyle.line.rawValue

    private var yMin: Double {
        var vals = data.map(line1)
        if let l2 = line2 { vals.append(contentsOf: data.map(l2)) }
        let m = vals.min() ?? 0
        let mx = vals.max() ?? 1
        let pad = (mx - m) * 0.1
        return m - pad
    }
    private var yMax: Double {
        var vals = data.map(line1)
        if let l2 = line2 { vals.append(contentsOf: data.map(l2)) }
        let m = vals.max() ?? 1
        let mn = vals.min() ?? 0
        let pad = (m - mn) * 0.1
        return m + pad
    }

    var body: some View {
        TahoeCard(accent: accent.opacity(0.2)) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.tahoeText)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.tahoeSubtext)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            if data.count > 1 {
                // Use indexed data so the chart always fills the width
                let indexedData = Array(data.enumerated())
                let maxIndex = Double(indexedData.count - 1)

                Chart(indexedData, id: \.offset) { index, pt in
                    if selectedChartStyleRaw == AppChartStyle.bar.rawValue {
                        BarMark(
                            x: .value("Index", Double(index)),
                            y: .value(line1Label, line1(pt))
                        )
                        .foregroundStyle(accent)
                    } else if selectedChartStyleRaw == AppChartStyle.filledArea.rawValue {
                        AreaMark(
                            x: .value("Index", Double(index)),
                            y: .value(line1Label, line1(pt))
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [accent.opacity(0.65), accent.opacity(0.05)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Index", Double(index)),
                            y: .value(line1Label, line1(pt))
                        )
                        .foregroundStyle(accent)
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                        .interpolationMethod(.catmullRom)
                    } else if selectedChartStyleRaw == AppChartStyle.steppedLine.rawValue {
                        LineMark(
                            x: .value("Index", Double(index)),
                            y: .value(line1Label, line1(pt))
                        )
                        .foregroundStyle(accent)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.stepCenter)
                    } else {
                        LineMark(
                            x: .value("Index", Double(index)),
                            y: .value(line1Label, line1(pt))
                        )
                        .foregroundStyle(accent)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartYScale(domain: yMin...yMax)
                .chartXScale(domain: 0...maxIndex)
                .chartYAxis {
                    AxisMarks(position: .leading, values: .stride(by: max(1, (yMax - yMin) / 3))) { val in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.08))
                        AxisValueLabel {
                            if let v = val.as(Double.self) {
                                Text(String(format: "%.0f", v))
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(.tahoeSubtext)
                            }
                        }
                    }
                }
                .chartXAxis(.hidden)
                .frame(height: height)
            } else {
                RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.03))
                    .frame(height: height)
                    .overlay(Text("Collecting data…").font(.system(size: 11)).foregroundColor(.tahoeSubtext))
            }
        }
    }
}

// MARK: - Telemetry Tab
struct TelemetryContentView: View {
    @ObservedObject var model: TelemetryModel

    @AppStorage("tele_show_cputemp") private var showCpuTemp = true
    @AppStorage("tele_show_gputemp") private var showGpuTemp = true
    @AppStorage("tele_show_cpupwr") private var showCpuPwr = true
    @AppStorage("tele_show_gpupwr") private var showGpuPwr = true
    @AppStorage("tele_show_ram") private var showRam = true
    @AppStorage("tele_show_disk") private var showDisk = true
    @AppStorage("tele_show_net") private var showNet = true
    @AppStorage("tele_show_fan") private var showFan = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle("CPU Frequency & Demand")
                ResizableChart(chartId: "tele_bar", small: 100, medium: 140, large: 200) { height in
                    PowerToolBarChart(model: model, height: height)
                }

                HStack {
                    SectionTitle("Live Telemetry History")
                    Spacer()
                    Menu {
                        Toggle("CPU Temperature", isOn: $showCpuTemp)
                        Toggle("GPU Temperature", isOn: $showGpuTemp)
                        Toggle("CPU Package Power", isOn: $showCpuPwr)
                        Toggle("GPU Power", isOn: $showGpuPwr)
                        Toggle("RAM Utilization", isOn: $showRam)
                        Toggle("Disk Activity", isOn: $showDisk)
                        Toggle("Network Speed", isOn: $showNet)
                        Toggle("Fan Speed", isOn: $showFan)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 11))
                            Text("Configure Charts")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(.tahoeText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(6)
                    }
                    .menuStyle(BorderlessButtonMenuStyle())
                }

                if showCpuTemp {
                    ResizableChart(chartId: "tele_cputemp", small: 50, medium: 80, large: 120) { height in
                        TahoeCard {
                            SimpleLineChart(title: "CPU Temperature", unit: "°C", color: .tahoeAccentOrange, data: model.history, value: { $0.cpuTempC }, height: height)
                        }
                    }
                }
                if showGpuTemp {
                    ResizableChart(chartId: "tele_gputemp", small: 50, medium: 80, large: 120) { height in
                        TahoeCard {
                            SimpleLineChart(title: "GPU Temperature", unit: "°C", color: Color(red: 0.8, green: 0.5, blue: 1.0), data: model.history, value: { $0.gpuTempC }, height: height)
                        }
                    }
                }
                if showCpuPwr {
                    ResizableChart(chartId: "tele_cpupwr", small: 50, medium: 80, large: 120) { height in
                        TahoeCard {
                            SimpleLineChart(title: "CPU Package Power", unit: "W", color: .tahoeAccentGreen, data: model.history, value: { $0.cpuWatts }, height: height)
                        }
                    }
                }
                if showGpuPwr {
                    ResizableChart(chartId: "tele_gpupwr", small: 50, medium: 80, large: 120) { height in
                        TahoeCard {
                            SimpleLineChart(title: "GPU Power", unit: "W", color: .tahoeAccentPurple, data: model.history, value: { $0.gpuWatts }, height: height)
                        }
                    }
                }
                if showRam {
                    ResizableChart(chartId: "tele_ram", small: 50, medium: 80, large: 120) { height in
                        TahoeCard {
                            SimpleLineChart(title: "RAM Utilization", unit: "%", color: .tahoeAccentYellow, data: model.history, value: { $0.ramUsagePct }, height: height)
                        }
                    }
                }
                if showDisk {
                    ResizableChart(chartId: "tele_disk", small: 50, medium: 80, large: 120) { height in
                        TahoeCard {
                            SimpleLineChart(title: "Disk Activity (Read+Write)", unit: "MB/s", color: .tahoeAccentBlue, data: model.history, value: { $0.diskReadMBps + $0.diskWriteMBps }, height: height)
                        }
                    }
                }
                if showNet {
                    ResizableChart(chartId: "tele_net", small: 50, medium: 80, large: 120) { height in
                        TahoeCard {
                            SimpleLineChart(title: "Network Total Speed", unit: "MB/s", color: .tahoeAccentCyan, data: model.history, value: { $0.netDownloadMBps + $0.netUploadMBps }, height: height)
                        }
                    }
                }
                if showFan {
                    ResizableChart(chartId: "tele_fan", small: 50, medium: 80, large: 120) { height in
                        TahoeCard {
                            SimpleLineChart(title: "Fan Speed", unit: "RPM", color: Color(red: 0.2, green: 0.8, blue: 0.6), data: model.history, value: { $0.fanRPM }, height: height)
                        }
                    }
                }

                SectionTitle("Current Values")
                TahoeCard {
                    InfoRow(label: "CPU Model",       value: model.sysInfo.cpuBrand)
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "Avg Frequency",   value: String(format: "%.3f GHz", model.cpuFreqAvgGHz))
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "Max Frequency",   value: String(format: "%.3f GHz", model.cpuFreqMaxGHz))
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "CPU Temperature", value: String(format: "%.2f °C",  model.cpuTempC))
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "Package Power",   value: String(format: "%.2f W",   model.cpuWatts))
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "GPU Model",       value: model.sysInfo.gpuModel.isEmpty || model.sysInfo.gpuModel == "Unknown" ? "Radeon GPU" : model.sysInfo.gpuModel)
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "Metal Version",   value: model.sysInfo.metalVersion)
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "GPU Temperature", value: String(format: "%.2f °C",  model.gpuTempC))
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "GPU Power",       value: String(format: "%.2f W",   model.gpuPowerW))
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "GPU Fan Speed",   value: model.gpuFanRPM > 0 ? String(format: "%.0f RPM", model.gpuFanRPM) : "0 RPM (Zero RPM Mode)")
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "GPU VRAM Used",   value: String(format: "%.2f GB",  model.gpuVramUsedBytes / (1024.0 * 1024.0 * 1024.0)))
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "GPU Utilization", value: String(format: "%.1f %%",  model.gpuLoadPct))
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "VDA Decoder",     value: model.sysInfo.vdaAcceleration)
                }

                SectionTitle("Diagnostics & CSV Logging")
                TahoeCard(accent: Color.tahoeAccentGreen.opacity(0.15)) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Export Telemetry History").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                                Text("Export the history of samples currently in memory to a CSV file").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                            }
                            Spacer()
                            TahoeButton(label: "Export CSV", icon: "square.and.arrow.up", accent: .tahoeAccentGreen) {
                                let op = NSSavePanel()
                                op.allowedContentTypes = [.init(filenameExtension: "csv") ?? .data]
                                if op.runModal() == .OK, let url = op.url {
                                    model.exportHistoryToCSV(url: url)
                                }
                            }
                        }
                        
                        Divider().background(Color.tahoeCardBorder)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Continuous Background Logging").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                                Text("Continuously write telemetry samples to a CSV file in the background").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                            }
                            Spacer()
                            Toggle("", isOn: $model.isLoggingEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentGreen)).labelsHidden()
                        }
                        
                        if model.isLoggingEnabled || !model.logFilePath.isEmpty {
                            Divider().background(Color.tahoeCardBorder)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Log File Location").font(.system(size: 11, weight: .semibold)).foregroundColor(.tahoeText)
                                    Text(model.logFilePath.isEmpty ? "No location selected" : model.logFilePath)
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(model.logFilePath.isEmpty ? .tahoeAccentOrange : .tahoeSubtext)
                                        .lineLimit(1)
                                }
                                Spacer()
                                TahoeButton(label: "Select File...", icon: "folder", accent: .tahoeAccentGreen) {
                                    let op = NSSavePanel()
                                    op.allowedContentTypes = [.init(filenameExtension: "csv") ?? .data]
                                    if op.runModal() == .OK, let url = op.url {
                                        model.logFilePath = url.path
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(18)
        }
    }
}

// MARK: - Simple Line Chart (for telemetry secondary charts)
struct SimpleLineChart: View {
    let title: String
    let unit: String
    let color: Color
    let data: [TelemetryPoint]
    let value: (TelemetryPoint) -> Double
    let height: CGFloat

    private var yMin: Double {
        let vals = data.map(value)
        let m = vals.min() ?? 0
        let mx = vals.max() ?? 1
        return m - (mx - m) * 0.1
    }
    private var yMax: Double {
        let vals = data.map(value)
        let m = vals.max() ?? 1
        let mn = vals.min() ?? 0
        return m + (m - mn) * 0.1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(title).font(.system(size: 11, weight: .semibold)).foregroundColor(.tahoeText)
                Spacer()
                if let last = data.last {
                    Text(String(format: "%.1f %@", value(last), unit))
                        .font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundColor(color)
                }
            }
            if data.count > 1 {
                let indexedData = Array(data.enumerated())
                let maxIndex = Double(indexedData.count - 1)

                Chart(indexedData, id: \.offset) { index, pt in
                    AreaMark(x: .value("Index", Double(index)), y: .value(title, value(pt)))
                        .foregroundStyle(LinearGradient(colors: [color.opacity(0.28), color.opacity(0.0)], startPoint: .top, endPoint: .bottom))
                        .interpolationMethod(.catmullRom)
                    LineMark(x: .value("Index", Double(index)), y: .value(title, value(pt)))
                        .foregroundStyle(color)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)
                }
                .chartYScale(domain: yMin...yMax)
                .chartXScale(domain: 0...maxIndex)
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading, values: .stride(by: max(1, (yMax - yMin) / 4))) { val in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(Color.white.opacity(0.07))
                        AxisValueLabel {
                            if let v = val.as(Double.self) {
                                Text(String(format: "%.0f", v)).font(.system(size: 9)).foregroundColor(.tahoeSubtext)
                            }
                        }
                    }
                }
                .frame(height: height)
                .shadow(color: color.opacity(0.25), radius: 4)
            } else {
                RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.03)).frame(height: height)
                    .overlay(Text("Collecting data…").font(.system(size: 11)).foregroundColor(.tahoeSubtext))
            }
        }
    }
}

// MARK: - Power Tool Style Bar Chart
struct PowerToolBarChart: View {
    @ObservedObject var model: TelemetryModel
    let height: CGFloat

    var body: some View {
        TahoeCard(accent: Color.tahoeCardBorder) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Frequency Max:").font(.system(size: 11)).foregroundColor(.tahoeAccentCyan)
                        Text(String(format: "%.1f Ghz", model.cpuFreqMaxGHz))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.tahoeText)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Inst(s) Retired:").font(.system(size: 11)).foregroundColor(.tahoeAccentRed)
                        Text(model.instRetiredFormatted)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.tahoeText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                }
                .frame(width: 140, alignment: .leading)

                if model.history.count > 1 {
                    let recent = Array(model.history.suffix(30))
                    let maxFreq = recent.map { $0.cpuFreqMaxGHz }.max() ?? 4.0
                    let maxInst = recent.map { Double($0.instRetired) }.max() ?? 1.0

                    GeometryReader { geo in
                        HStack(alignment: .bottom, spacing: 2) {
                            ForEach(recent) { pt in
                                ZStack(alignment: .bottom) {
                                    Rectangle()
                                        .fill(Color.tahoeAccentCyan.opacity(0.7))
                                        .frame(
                                            width: max(2, (geo.size.width / CGFloat(recent.count)) - 2),
                                            height: geo.size.height * CGFloat(pt.cpuFreqMaxGHz / max(maxFreq, 0.1))
                                        )
                                    Rectangle()
                                        .fill(Color.tahoeAccentRed.opacity(0.5))
                                        .frame(
                                            width: max(2, (geo.size.width / CGFloat(recent.count)) - 2),
                                            height: geo.size.height * CGFloat(min(Double(pt.instRetired) / max(maxInst, 1.0), 1.0))
                                        )
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    }
                    .frame(height: height)
                } else {
                    RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.03)).frame(height: height)
                        .overlay(Text("Collecting data…").font(.system(size: 11)).foregroundColor(.tahoeSubtext))
                }
            }
        }
    }
}

// MARK: - Network Line Chart Card
struct NetworkLineChartCard: View {
    let title: LocalizedStringKey
    @ObservedObject var model: TelemetryModel
    let height: CGFloat

    @AppStorage("net_chart_style") private var chartStyle: Int = 0 // 0: Bars, 1: Overlapping Areas, 2: Total & Average

    private func formatSpeed(_ mbps: Double) -> String {
        let absMbps = abs(mbps)
        let bytesPerSec = absMbps * 1024.0 * 1024.0
        if bytesPerSec >= 1024.0 * 1024.0 {
            let val = bytesPerSec / (1024.0 * 1024.0)
            return String(format: "%.2f MB/s", locale: Locale.current, val)
        } else if bytesPerSec >= 1024.0 {
            let val = bytesPerSec / 1024.0
            return String(format: "%.2f KB/s", locale: Locale.current, val)
        } else if bytesPerSec >= 1.0 {
            let val = bytesPerSec / 1024.0
            return String(format: "%.3f KB/s", locale: Locale.current, val)
        } else {
            return "0 KB/s"
        }
    }

    private var maxUpload: Double {
        model.history.map { $0.netUploadMBps }.max() ?? 0.05
    }

    private var maxDownload: Double {
        model.history.map { $0.netDownloadMBps }.max() ?? 0.05
    }

    private var yScaleLimit: Double {
        max(maxUpload, maxDownload, 0.05)
    }

    private var yMax: Double {
        yScaleLimit
    }

    private var yMin: Double {
        -yScaleLimit
    }

    private var yDomainMax: Double {
        yScaleLimit * 1.15
    }

    private var yDomainMin: Double {
        -yScaleLimit * 1.15
    }

    private var xMin: Double {
        model.history.first?.time ?? 0.0
    }

    private var xMax: Double {
        model.history.last?.time ?? 1.0
    }

    var body: some View {
        TahoeCard(accent: Color.tahoeAccentRed.opacity(0.2)) {
            VStack(alignment: .leading, spacing: 8) {
                // Header (Title & Style Switcher & Upload Speed)
                HStack(alignment: .center) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.tahoeText)
                    
                    Spacer()
                    
                    // Segmented Switcher (Tab bar style)
                    HStack(spacing: 2) {
                        ForEach(0..<3) { styleIdx in
                            let label = styleIdx == 0 ? "Barras" : (styleIdx == 1 ? "Curvas" : "Total")
                            Text(label)
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                                .foregroundColor(chartStyle == styleIdx ? .white : .tahoeSubtext)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(chartStyle == styleIdx ? Color.tahoeSidebarActive : Color.clear)
                                .cornerRadius(5)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        chartStyle = styleIdx
                                    }
                                }
                        }
                    }
                    .padding(2)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(6)

                    Spacer().frame(width: 12)

                    // Upload Speed on far right of header (fixed width container prevents button jitter)
                    if let last = model.history.last {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.tahoeAccentPurple)
                            Text(formatSpeed(last.netUploadMBps))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.tahoeAccentPurple)
                        }
                        .frame(minWidth: 95, alignment: .trailing)
                    }
                }

                // Chart in the middle (changes based on style selection)
                if model.history.count > 1 {
                    let indexedData = Array(model.history.enumerated())
                    let maxIndex = Double(max(1, indexedData.count - 1))

                    if chartStyle == 0 {
                        // Style 0: Bidirectional Bars (Quantitative X-axis)
                        Chart {
                            ForEach(indexedData, id: \.offset) { index, pt in
                                BarMark(
                                    x: .value("Index", Double(index)),
                                    y: .value("Upload", pt.netUploadMBps)
                                )
                                .foregroundStyle(Color.tahoeAccentPurple)
                            }

                            ForEach(indexedData, id: \.offset) { index, pt in
                                BarMark(
                                    x: .value("Index", Double(index)),
                                    y: .value("Download", -pt.netDownloadMBps)
                                )
                                .foregroundStyle(Color.tahoeAccentBlue)
                            }
                        }
                        .chartYScale(domain: yDomainMin...yDomainMax)
                        .chartXScale(domain: 0...maxIndex)
                        .chartYAxis {
                            AxisMarks(position: .leading, values: [yMin, 0.0, yMax]) { val in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(Color.white.opacity(0.08))
                                AxisValueLabel {
                                    if let v = val.as(Double.self) {
                                        Text(formatSpeed(v))
                                            .font(.system(size: 8, design: .monospaced))
                                            .foregroundColor(.tahoeSubtext)
                                    }
                                }
                            }
                        }
                        .chartXAxis(.hidden)
                        .frame(height: height)
                    } else if chartStyle == 1 {
                        // Style 1: Overlapping Area Curves (Quantitative X-axis, smooth)
                        let maxVal = max(maxUpload, maxDownload, 0.05)
                        let yLimitMax = maxVal * 1.15
                        let yAxisVals = [0.0, maxVal / 2.0, maxVal]

                        Chart {
                            ForEach(indexedData, id: \.offset) { index, pt in
                                AreaMark(
                                    x: .value("Index", Double(index)),
                                    y: .value("Speed", pt.netDownloadMBps)
                                )
                                .foregroundStyle(by: .value("Series", "Download"))
                                .opacity(0.25)
                                .interpolationMethod(.catmullRom)

                                LineMark(
                                    x: .value("Index", Double(index)),
                                    y: .value("Speed", pt.netDownloadMBps)
                                )
                                .foregroundStyle(by: .value("Series", "Download"))
                                .lineStyle(StrokeStyle(lineWidth: 2))
                                .interpolationMethod(.catmullRom)

                                AreaMark(
                                    x: .value("Index", Double(index)),
                                    y: .value("Speed", pt.netUploadMBps)
                                )
                                .foregroundStyle(by: .value("Series", "Upload"))
                                .opacity(0.20)
                                .interpolationMethod(.catmullRom)

                                LineMark(
                                    x: .value("Index", Double(index)),
                                    y: .value("Speed", pt.netUploadMBps)
                                )
                                .foregroundStyle(by: .value("Series", "Upload"))
                                .lineStyle(StrokeStyle(lineWidth: 1.5))
                                .interpolationMethod(.catmullRom)
                            }
                        }
                        .chartForegroundStyleScale([
                            "Download": Color.tahoeAccentBlue,
                            "Upload": Color.tahoeAccentPurple
                        ])
                        .chartYScale(domain: 0.0...yLimitMax)
                        .chartXScale(domain: 0...maxIndex)
                        .chartYAxis {
                            AxisMarks(position: .leading, values: yAxisVals) { val in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(Color.white.opacity(0.08))
                                AxisValueLabel {
                                    if let v = val.as(Double.self) {
                                        Text(formatSpeed(v))
                                            .font(.system(size: 8, design: .monospaced))
                                            .foregroundColor(.tahoeSubtext)
                                    }
                                }
                            }
                        }
                        .chartXAxis(.hidden)
                        .frame(height: height)
                    } else {
                        // Style 2: Total & Split (Layered Download & Upload with Total Line)
                        let maxTotal = model.history.map { $0.netUploadMBps + $0.netDownloadMBps }.max() ?? 0.05
                        let yLimitMax = maxTotal * 1.15
                        let yAxisVals = [0.0, maxTotal / 2.0, maxTotal]
                        let averageTotal = model.history.map { $0.netUploadMBps + $0.netDownloadMBps }.reduce(0, +) / Double(max(1, model.history.count))

                        Chart {
                            ForEach(indexedData, id: \.offset) { index, pt in
                                AreaMark(
                                    x: .value("Index", Double(index)),
                                    y: .value("Speed", pt.netDownloadMBps)
                                )
                                .foregroundStyle(by: .value("Series", "Download"))
                                .opacity(0.30)
                                .interpolationMethod(.catmullRom)

                                AreaMark(
                                    x: .value("Index", Double(index)),
                                    y: .value("Speed", pt.netDownloadMBps + pt.netUploadMBps)
                                )
                                .foregroundStyle(by: .value("Series", "Upload"))
                                .opacity(0.20)
                                .interpolationMethod(.catmullRom)

                                LineMark(
                                    x: .value("Index", Double(index)),
                                    y: .value("Speed", pt.netDownloadMBps + pt.netUploadMBps)
                                )
                                .foregroundStyle(Color.tahoeAccentOrange)
                                .lineStyle(StrokeStyle(lineWidth: 2.0))
                                .interpolationMethod(.catmullRom)
                            }

                            RuleMark(y: .value("Average", averageTotal))
                                .foregroundStyle(Color.tahoeSubtext.opacity(0.6))
                                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                                .annotation(position: .top, alignment: .trailing) {
                                    Text("Avg: \(formatSpeed(averageTotal))")
                                        .font(.system(size: 8, weight: .bold, design: .rounded))
                                        .foregroundColor(.tahoeSubtext)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Color.tahoeBackground.opacity(0.75))
                                        .cornerRadius(4)
                                }
                        }
                        .chartForegroundStyleScale([
                            "Download": Color.tahoeAccentBlue,
                            "Upload": Color.tahoeAccentPurple
                        ])
                        .chartYScale(domain: 0.0...yLimitMax)
                        .chartXScale(domain: 0...maxIndex)
                        .chartYAxis {
                            AxisMarks(position: .leading, values: yAxisVals) { val in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(Color.white.opacity(0.08))
                                AxisValueLabel {
                                    if let v = val.as(Double.self) {
                                        Text(formatSpeed(v))
                                            .font(.system(size: 8, design: .monospaced))
                                            .foregroundColor(.tahoeSubtext)
                                    }
                                }
                            }
                        }
                        .chartXAxis(.hidden)
                        .frame(height: height)
                    }
                } else {
                    RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.03))
                        .frame(height: height)
                        .overlay(Text("Collecting data…").font(.system(size: 11)).foregroundColor(.tahoeSubtext))
                }

                // Footer (Download Speed, aligned down at the bottom of the card)
                if let last = model.history.last {
                    HStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.tahoeAccentBlue)
                            Text(formatSpeed(last.netDownloadMBps))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.tahoeAccentBlue)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Core Grid
struct CoreGridCard: View {
    @ObservedObject var model: TelemetryModel
    @AppStorage("sort_cores_by_ranking") private var sortCoresByRanking = false
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 8)

    private var displayCores: [CoreSnapshot] {
        if sortCoresByRanking {
            return model.cores.sorted { (c1, c2) -> Bool in
                let r1 = c1.coreRank ?? 999
                let r2 = c2.coreRank ?? 999
                if r1 != r2 {
                    return r1 < r2
                }
                if c1.isLogical != c2.isLogical {
                    return !c1.isLogical
                }
                return c1.id < c2.id
            }
        } else {
            return model.cores
        }
    }

    var body: some View {
        TahoeCard {
            HStack(alignment: .center) {
                SectionTitle("Current Utilization — \(model.sysInfo.logicalCores) Threads (\(model.sysInfo.physicalCores) Cores)")
                Spacer()
                HStack(spacing: 8) {
                    Toggle(NSLocalizedString("Sort by Rank", comment: ""), isOn: $sortCoresByRanking)
                        .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentBlue))
                        .font(.system(size: 10, weight: .semibold))
                        .scaleEffect(0.85)
                    
                    if model.cppcSupported {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.tahoeAccentGreen)
                            Text(model.cppcScoresEstimated ? "CPPC: Estimated" : "CPPC: Active")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(model.cppcScoresEstimated ? .tahoeAccentOrange : .tahoeAccentGreen)
                            if model.cppcScoresEstimated {
                                Text("~")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.tahoeAccentOrange)
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(4)
                        .help(model.cppcScoresEstimated ? "CPPC hardware values could not be read. Rankings are estimated from the maximum observed clock frequency of each core." : "CPPC hardware rankings are active and loaded from the processor.")
                    }
                }
            }
            .padding(.bottom, 4)

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(displayCores) { CoreCell(core: $0, showRanking: sortCoresByRanking) }
            }
        }
    }
}

private struct CoreCell: View {
    let core: CoreSnapshot
    let showRanking: Bool
    private var loadColor: Color {
        if core.loadPct > 80 { return Color(red: 1.0, green: 0.35, blue: 0.3) }
        if core.loadPct > 50 { return Color(red: 1.0, green: 0.75, blue: 0.1) }
        return Color.tahoeAccentGreen
    }
    private var labelText: String {
        let base = core.isLogical ? "T\(core.id + 1)" : "C\(core.id + 1)"
        var parts: [String] = []
        if showRanking, let rank = core.coreRank {
            parts.append("#\(rank)")
        }
        parts.append(base)
        if let score = core.cppcScore, score > 0 {
            let prefix = core.cppcScoreEstimated ? "~" : ""
            parts.append("[\(prefix)\(score)]")
        }
        return parts.joined(separator: " ")
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(labelText)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(core.isLogical ? Color.tahoeSubtext.opacity(0.7) : .tahoeSubtext)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer()
                Text(String(format: "%.0f%%", core.loadPct))
                    .font(.system(size: 10, weight: .bold, design: .rounded)).foregroundColor(loadColor)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.06)).frame(height: 3)
                    Capsule().fill(loadColor)
                        .frame(width: geo.size.width * CGFloat(core.loadPct / 100.0), height: 3)
                        .shadow(color: loadColor.opacity(0.7), radius: 2)
                }
            }
            .frame(height: 3)
            Text(String(format: "%.0f MHz", core.freqMHz))
                .font(.system(size: 8, design: .monospaced)).foregroundColor(.tahoeSubtext)
        }
        .padding(6)
        .background(Color.tahoeBackground.opacity(0.6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(loadColor.opacity(0.2)))
        .cornerRadius(6)
    }
}

// MARK: - Fan Control Tab
struct FanControlContentView: View {
    @ObservedObject var model: TelemetryModel
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !model.smcDriverLoaded {
                    SMCNotAvailableView()
                } else if model.fans.isEmpty {
                    Text("No fans detected.").foregroundColor(.tahoeSubtext).frame(maxWidth: .infinity).padding(32)
                } else {
                    SectionTitle("SMC Fan Control")
                    ForEach(model.fans) { fan in FanControlCard(fan: fan, model: model) }
                    HStack(spacing: 10) {
                        TahoeButton(label: "All Auto", icon: "arrow.circlepath", accent: .tahoeAccentCyan) { model.setAllFansAuto() }
                        TahoeButton(label: "Max Speed", icon: "wind", accent: .tahoeAccentOrange) { model.setAllFansTakeOff() }
                    }
                    
                    Divider().background(Color.tahoeCardBorder)
                    
                    SectionTitle("Closed-Loop Thermal Fan Curve & Protection")
                    TahoeCard(accent: Color.tahoeAccentOrange.opacity(0.2)) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Dynamic Auto-Curve & Thermal Guard").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                                    Text("Scales fan PWM automatically with temperature and forces 80% at 85°C").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                                }
                                Spacer()
                                Toggle("", isOn: $model.autoFanCurveEnabled)
                                    .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentOrange)).labelsHidden()
                            }
                            if model.autoFanCurveEnabled {
                                Divider().background(Color.white.opacity(0.1))
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Minimum Temp (20% PWM)").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                                        Spacer()
                                        Text(String(format: "%.0f°C", model.fanCurveMinTemp))
                                            .font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.tahoeAccentOrange)
                                    }
                                    Slider(value: $model.fanCurveMinTemp, in: 30...60, step: 5)
                                        .accentColor(.tahoeAccentOrange)
                                    
                                    HStack {
                                        Text("Maximum Temp (80% PWM)").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                                        Spacer()
                                        Text(String(format: "%.0f°C", model.fanCurveMaxTemp))
                                            .font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.tahoeAccentOrange)
                                    }
                                    Slider(value: $model.fanCurveMaxTemp, in: 65...85, step: 5)
                                        .accentColor(.tahoeAccentOrange)
                                }
                            }
                        }
                    }
                }
                
                Divider().background(Color.tahoeCardBorder)
                
                GPUFanControlGuideView()
            }
            .padding(18)
        }
    }
}

private struct GPUFanControlGuideView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle("GPU Fan Control (Zero RPM / Curves)")
            TahoeCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.tahoeAccentCyan)
                            .font(.system(size: 16))
                        Text("macOS Hardware Limitation")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.tahoeText)
                    }
                    Text("Direct software-based GPU fan speed overrides (such as zero-rpm toggle or drawing fan curves in macOS) are not supported by the macOS kernel/IOKit driver for AMD GPUs. The GPU's onboard firmware (vBIOS) manages the fans.")
                        .font(.system(size: 11.5))
                        .foregroundColor(.tahoeSubtext)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("Standard Hackintosh Solution:")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.tahoeText)
                        .padding(.top, 4)
                    Text("The only way to modify this behavior (like forcing fans to spin at lower temperatures or disabling Zero RPM) is by exporting the vBIOS, creating a Soft PowerPlay Table (SPPT), and injecting it via OpenCore's config.plist under DeviceProperties.")
                        .font(.system(size: 11.5))
                        .foregroundColor(.tahoeSubtext)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack(spacing: 10) {
                        TahoeButton(label: "Open SPPT Guide", icon: "safari", accent: .tahoeAccentCyan) {
                            NSWorkspace.shared.open(URL(string: "https://github.com/perez987/6600XT-on-macOS-with-softPowerPlayTable")!)
                        }
                        TahoeButton(label: "MorePowerTool", icon: "arrow.down.circle", accent: .tahoeAccentOrange) {
                            NSWorkspace.shared.open(URL(string: "https://www.igorslab.de/en/red-bios-editor-and-morepowertool-adjust-and-optimize-your-radeon-rx-5700-xt-and-radeon-vii-bios-instructions-and-downloads/")!)
                        }
                    }
                    .padding(.top, 6)
                }
            }
        }
    }
}


private struct SMCNotAvailableView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 32)).foregroundColor(.tahoeAccentOrange)
            Text("SMC driver not available").font(.system(size: 14, weight: .semibold)).foregroundColor(.tahoeText)
            Text("Your SMC chip may not be supported.").font(.system(size: 12)).foregroundColor(.tahoeSubtext)
        }
        .frame(maxWidth: .infinity).padding(32)
    }
}

private struct FanControlCard: View {
    let fan: FanSnapshot; @ObservedObject var model: TelemetryModel
    @State private var sliderValue: Double = 0
    var body: some View {
        TahoeCard(accent: fan.isOverrided ? Color.tahoeAccentOrange.opacity(0.4) : Color.tahoeCardBorder) {
            HStack {
                Image(systemName: "fan").foregroundColor(.tahoeAccentCyan).font(.system(size: 14))
                Text(fan.name.isEmpty ? "Fan \(fan.id + 1)" : fan.name).font(.system(size: 13, weight: .semibold)).foregroundColor(.tahoeText)
                Spacer()
                HStack(spacing: 6) {
                    Text("\(fan.rpm) RPM").font(.system(size: 11, design: .monospaced)).foregroundColor(.tahoeAccentCyan)
                    Text("·").foregroundColor(.tahoeSubtext)
                    Text(String(format: "%.0f%%", Double(fan.throttle) / 255.0 * 100.0))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(fan.isOverrided ? .tahoeAccentOrange : .tahoeSubtext)
                }
            }
            HStack(spacing: 12) {
                Text("Throttle").font(.system(size: 11)).foregroundColor(.tahoeSubtext)
                Slider(value: $sliderValue, in: 0...255, step: 1) { editing in
                    if !editing { model.setFanThrottle(fanIndex: fan.id, throttle: UInt8(sliderValue)) }
                }
                .tint(Color.tahoeAccentCyan)
                Text(String(format: "%.0f%%", sliderValue / 255.0 * 100.0))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.tahoeAccentCyan)
                    .frame(width: 36, alignment: .trailing)
            }
            if fan.isOverrided {
                Button("↩ Reset to Auto") { model.setFanOverride(fanIndex: fan.id, overrideEnabled: false) }
                    .font(.system(size: 11)).foregroundColor(.tahoeAccentOrange).buttonStyle(.plain)
            }
        }
        .onAppear { sliderValue = Double(fan.throttle) }
        .onChange(of: fan.throttle) { newVal in sliderValue = Double(newVal) }
    }
}

// MARK: - Profiles Tab
struct ProfilesContentView: View {
    @ObservedObject var model: TelemetryModel
    private var stepLabels: [String] {
        model.speedStepClocks.enumerated().map { i, freq in
            let ghz = freq * 0.001
            switch i {
            case 0: return String(format: "Performance\n%.1f GHz", ghz)
            case 1: return String(format: "Balanced\n%.1f GHz", ghz)
            case 2: return String(format: "Base\n%.1f GHz", ghz)
            case 3: return String(format: "Efficient\n%.1f GHz", ghz)
            case 4: return String(format: "Low Power\n%.1f GHz", ghz)
            default: return String(format: "P%d\n%.1f GHz", i, ghz)
            }
        }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle("Power Management Mode")
                
                // 1. CPPC Mode Switch
                TahoeCard(accent: Color.tahoeAccentCyan.opacity(0.15)) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Native CPPC Active Mode (EPP)").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                            Text("Enables autonomous hardware frequency scaling (recommended)").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(get: { model.cppcActiveMode }, set: { model.setCPPCActiveMode(active: $0) }))
                            .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentCyan)).labelsHidden()
                    }
                }
                
                if model.cppcActiveMode {
                    // 2. Dynamic Auto-EPP Engine
                    TahoeCard(accent: Color.tahoeAccentCyan.opacity(0.15)) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Dynamic Auto-EPP Workload Engine").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                                    Text("Automatically switches EPP profiles based on live CPU load").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                                }
                                Spacer()
                                Toggle("", isOn: $model.autoEPPEnabled)
                                    .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentCyan)).labelsHidden()
                            }
                            if model.autoEPPEnabled {
                                Divider().background(Color.white.opacity(0.1))
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Idle Threshold (Power Save)").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                                        Spacer()
                                        Text(String(format: "%.0f%%", model.autoEPPIdleThreshold))
                                            .font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.tahoeAccentCyan)
                                    }
                                    Slider(value: $model.autoEPPIdleThreshold, in: 5...30, step: 5)
                                        .accentColor(.tahoeAccentCyan)
                                    
                                    HStack {
                                        Text("High Load Threshold (Performance)").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                                        Spacer()
                                        Text(String(format: "%.0f%%", model.autoEPPHighThreshold))
                                            .font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.tahoeAccentCyan)
                                    }
                                    Slider(value: $model.autoEPPHighThreshold, in: 40...90, step: 5)
                                        .accentColor(.tahoeAccentCyan)
                                }
                            }
                        }
                    }

                    // 3. CPPC EPP Picker
                    SectionTitle("Energy Preference (EPP)")
                    Text("Select a hardware autonomous profile. The CPU will scale frequency dynamically.")
                        .font(.system(size: 11)).foregroundColor(.tahoeSubtext)
                    TahoeCard(accent: Color.tahoeAccentCyan.opacity(0.15)) {
                        Picker("", selection: Binding(get: {
                            if model.cppcEPPValue <= 0x1F { return 0 }
                            else if model.cppcEPPValue <= 0x5F { return 1 }
                            else if model.cppcEPPValue <= 0x9F { return 2 }
                            else { return 3 }
                                                }, set: { (val: Int) in
                            let eppBytes: [UInt8] = [0x00, 0x3F, 0x7F, 0xFF]
                            model.setCPPCEPPValue(epp: eppBytes[val])
                        })) {
                            Text("Performance").tag(0)
                            Text("Balanced Perf").tag(1)
                            Text("Balanced Power").tag(2)
                            Text("Power Save").tag(3)
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: .infinity)
                        .disabled(model.autoEPPEnabled)
                    }
                } else {
                    // 3. Legacy Speed Step Profiles
                    SectionTitle("CPU Speed Profiles (Legacy)")
                    Text("Select a manual P-State override profile. Frequencies will be restricted to the selected step.")
                        .font(.system(size: 11)).foregroundColor(.tahoeSubtext)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(Array(stepLabels.enumerated()), id: \.offset) { i, label in
                            SpeedStepCard(label: label, isActive: model.selectedSpeedStep == i) { model.setSpeedStep(i) }
                        }
                    }
                }
                
                SectionTitle("Active Profile Status")
                TahoeCard {
                    if model.cppcActiveMode {
                        let eppLabels = ["Performance", "Balanced Perf", "Balanced Power", "Power Save"]
                        let activeIdx: Int = {
                            if model.cppcEPPValue <= 0x1F { return 0 }
                            else if model.cppcEPPValue <= 0x5F { return 1 }
                            else if model.cppcEPPValue <= 0x9F { return 2 }
                            else { return 3 }
                        }()
                        InfoRow(label: "Mode", value: "Native CPPC (EPP)")
                        Divider().background(Color.tahoeCardBorder)
                        InfoRow(label: "EPP Profile", value: NSLocalizedString(eppLabels[activeIdx], comment: ""))
                        Divider().background(Color.tahoeCardBorder)
                        InfoRow(label: "Auto-EPP Engine", value: model.autoEPPEnabled ? "Active (Dynamic Load)" : "Disabled")
                    } else if stepLabels.indices.contains(model.selectedSpeedStep) {
                        InfoRow(label: "Mode", value: "Legacy P-States")
                        Divider().background(Color.tahoeCardBorder)
                        InfoRow(label: "Profile", value: stepLabels[model.selectedSpeedStep].replacingOccurrences(of: "\n", with: " — "))
                    }
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "Avg Frequency", value: String(format: "%.3f GHz", model.cpuFreqAvgGHz))
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "Max Frequency", value: String(format: "%.3f GHz", model.cpuFreqMaxGHz))
                }
            }
            .padding(18)
        }
    }
}


private struct SpeedStepCard: View {
    let label: String; let isActive: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: isActive ? "bolt.fill" : "bolt").font(.system(size: 20))
                    .foregroundColor(isActive ? .tahoeAccentCyan : .tahoeSubtext)
                    .shadow(color: isActive ? Color.tahoeAccentCyan.opacity(0.8) : .clear, radius: 6)
                Text(label).font(.system(size: 12, weight: isActive ? .semibold : .regular))
                    .foregroundColor(isActive ? .tahoeText : .tahoeSubtext).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 18)
            .background(isActive ? Color.tahoeAccentCyan.opacity(0.12) : Color.tahoeCard)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(isActive ? Color.tahoeAccentCyan.opacity(0.6) : Color.tahoeCardBorder, lineWidth: isActive ? 1.5 : 1))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Advanced Tab
struct AdvancedContentView: View {
    @ObservedObject var model: TelemetryModel
    @State private var showApplyConfirm = false
    @State private var applyOK: Bool? = nil
    
    @AppStorage("low_performance_mode") private var isLowPerformanceMode = false
    @AppStorage("user_forced_low_performance") private var userForced = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionTitle("CPU Power Controls")
                TahoeCard(accent: Color.tahoeAccentCyan.opacity(0.15)) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Core Performance Boost (CPB)").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                            Text(model.cpbSupported ? "Supported by your CPU" : "Not supported by your CPU").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                        }
                        Spacer()
                        if model.cpbSupported {
                            Toggle("", isOn: Binding(get: { model.cpbEnabled }, set: { model.setCPB(enabled: $0) }))
                                .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentCyan)).labelsHidden()
                        } else {
                            Text("N/A").font(.system(size: 11)).foregroundColor(.tahoeSubtext)
                        }
                    }
                }
                TahoeCard(accent: Color.tahoeAccentOrange.opacity(0.15)) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("AMD Processor Power Manager (PPM)").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                            Text("Allows macOS to auto-manage CPU frequency").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(get: { model.ppmEnabled }, set: { model.setPPM(enabled: $0) }))
                            .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentOrange)).labelsHidden()
                    }
                }
                TahoeCard(accent: Color.tahoeAccentGreen.opacity(0.15)) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Low Power Mode (LPM)").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                            Text("Forces CPU to lowest frequency for minimum power").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(get: { model.lpmEnabled }, set: { model.setLPM(enabled: $0) }))
                            .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentGreen)).labelsHidden()
                    }
                }

                Divider().background(Color.tahoeCardBorder)
                SectionTitle("Refresh Rate")
                Text("Adjust how frequently telemetry data updates. Lower = more responsive, higher = less CPU usage.")
                    .font(.system(size: 11)).foregroundColor(.tahoeSubtext)
                TahoeCard(accent: Color.tahoeAccentPurple.opacity(0.15)) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Update Interval").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                            Spacer()
                            Text(String(format: "%.1f s", RefreshRateConfig.shared.interval))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.tahoeAccentPurple)
                        }
                        Slider(value: .init(
                            get: { RefreshRateConfig.shared.interval },
                            set: { RefreshRateConfig.shared.interval = $0; model.restartTimer() }
                        ), in: 0.1...5.0, step: 0.1)
                        .tint(Color.tahoeAccentPurple)
                        HStack {
                            Text("0.1s").font(.system(size: 9)).foregroundColor(.tahoeSubtext)
                            Spacer()
                            Text("5.0s").font(.system(size: 9)).foregroundColor(.tahoeSubtext)
                        }
                    }
                }

                Divider().background(Color.tahoeCardBorder)
                SectionTitle("Performance & Fallback")
                Text("Disable heavy visual effects if your system lacks Metal graphics acceleration.")
                    .font(.system(size: 11)).foregroundColor(.tahoeSubtext)
                TahoeCard(accent: Color.tahoeSubtext.opacity(0.15)) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Low Performance Mode").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                            Text("Replaces translucent blurs with solid colors to save CPU").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { isLowPerformanceMode },
                            set: { newValue in
                                isLowPerformanceMode = newValue
                                userForced = true // User manually overrode auto-detection
                            }
                        ))
                        .toggleStyle(SwitchToggleStyle(tint: .tahoeSubtext)).labelsHidden()
                    }
                }

                Divider().background(Color.tahoeCardBorder)
                SectionTitle("System Alert Notifications")
                Text("Receive native macOS alerts when the CPU exceeds configured thermal or power limits.")
                    .font(.system(size: 11)).foregroundColor(.tahoeSubtext)
                TahoeCard(accent: Color.tahoeAccentRed.opacity(0.15)) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Enable System Alerts").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                                Text("Requests permission and enables hardware limit warnings").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                            }
                            Spacer()
                            Toggle("", isOn: $model.notificationsEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentRed)).labelsHidden()
                        }
                        
                        if model.notificationsEnabled {
                            Divider().background(Color.tahoeCardBorder)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Temperature Warning Threshold").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                                    Spacer()
                                    Text("\(model.tempAlertThreshold) °C")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(.tahoeAccentRed)
                                }
                                Slider(value: Binding(
                                    get: { Double(model.tempAlertThreshold) },
                                    set: { model.tempAlertThreshold = Int($0) }
                                ), in: 60...100, step: 1)
                                .tint(Color.tahoeAccentRed)
                                HStack {
                                    Text("60°C").font(.system(size: 9)).foregroundColor(.tahoeSubtext)
                                    Spacer()
                                    Text("100°C").font(.system(size: 9)).foregroundColor(.tahoeSubtext)
                                }
                            }
                            
                            Divider().background(Color.tahoeCardBorder)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Power Warning Threshold (PPT)").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                                    Spacer()
                                    Text("\(model.powerAlertThreshold) W")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(.tahoeAccentRed)
                                }
                                Slider(value: Binding(
                                    get: { Double(model.powerAlertThreshold) },
                                    set: { model.powerAlertThreshold = Int($0) }
                                ), in: 45...250, step: 5)
                                .tint(Color.tahoeAccentRed)
                                HStack {
                                    Text("45W").font(.system(size: 9)).foregroundColor(.tahoeSubtext)
                                    Spacer()
                                    Text("250W").font(.system(size: 9)).foregroundColor(.tahoeSubtext)
                                }
                            }
                            
                            Divider().background(Color.tahoeCardBorder)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Sustained Duration").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                                    Spacer()
                                    Text("\(model.powerAlertDuration) seconds")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(.tahoeAccentRed)
                                }
                                Slider(value: Binding(
                                    get: { Double(model.powerAlertDuration) },
                                    set: { model.powerAlertDuration = Int($0) }
                                ), in: 1...60, step: 1)
                                .tint(Color.tahoeAccentRed)
                                HStack {
                                    Text("1s").font(.system(size: 9)).foregroundColor(.tahoeSubtext)
                                    Spacer()
                                    Text("60s").font(.system(size: 9)).foregroundColor(.tahoeSubtext)
                                }
                            }
                        }
                    }
                }

                Divider().background(Color.tahoeCardBorder)
                SectionTitle("P-State Editor")
                Text("Directly edit raw P-State registers. Requires kext privilege check disabled via boot-arg or root.")
                    .font(.system(size: 11)).foregroundColor(.tahoeSubtext)
                PStateEditorView(model: model)
                if model.smcDriverLoaded {
                    Divider().background(Color.tahoeCardBorder)
                    SectionTitle("Quick Fan Access")
                    HStack(spacing: 10) {
                        TahoeButton(label: "All Fans Auto", icon: "arrow.circlepath", accent: .tahoeAccentCyan) { model.setAllFansAuto() }
                        TahoeButton(label: "Max Speed", icon: "wind", accent: .tahoeAccentOrange) { model.setAllFansTakeOff() }
                    }
                }

                Divider().background(Color.tahoeCardBorder)
                SectionTitle("Software Updates")
                Text("Check for new releases of SMCAMDProcessor and AMD Power Gadget on GitHub.")
                    .font(.system(size: 11)).foregroundColor(.tahoeSubtext)
                TahoeCard(accent: Color.tahoeAccentCyan.opacity(0.15)) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Check for Updates").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                                Text(model.updateCheckMessage.isEmpty ? "Current installed version: v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "3.13.3")" : model.updateCheckMessage)
                                    .font(.system(size: 10))
                                    .foregroundColor(model.updateAvailable ? .tahoeAccentGreen : .tahoeSubtext)
                            }
                            Spacer()
                            if model.isCheckingForUpdates {
                                ProgressView().scaleEffect(0.8)
                            } else {
                                TahoeButton(label: model.updateAvailable ? "Download Update" : "Check Now", icon: model.updateAvailable ? "arrow.down.circle" : "arrow.triangle.2.circlepath", accent: model.updateAvailable ? .tahoeAccentGreen : .tahoeAccentCyan) {
                                    if model.updateAvailable {
                                        if let u = URL(string: model.releaseURLString) { NSWorkspace.shared.open(u) }
                                    } else {
                                        model.checkForUpdates(manual: true)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(18)
        }
    }
}

private struct PStateChartView: View {
    let pStateRows: [PStateRow]
    let isZen5: Bool
    
    var body: some View {
        let enabledRows = pStateRows.filter { $0.enabled == 1 }
            .sorted(by: { $0.computedSpeedMHz < $1.computedSpeedMHz })
            
        let step = isZen5 ? 0.005 : 0.00625
        
        Chart {
            // Plot the line connecting the enabled P-States to form the curve
            if enabledRows.count >= 2 {
                ForEach(enabledRows) { row in
                    LineMark(
                        x: .value("Voltage (V)", 1.55 - Double(row.cpuVid) * step),
                        y: .value("Frequency (MHz)", Double(row.computedSpeedMHz))
                    )
                    .foregroundStyle(Color.tahoeAccentCyan)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.monotone)
                }
            }
            
            // Plot each P-state point (only show active/enabled states)
            ForEach(pStateRows.filter { $0.computedSpeedMHz > 0 && $0.enabled == 1 }) { row in
                let volt = 1.55 - Double(row.cpuVid) * step
                let speed = Double(row.computedSpeedMHz)
                
                PointMark(
                    x: .value("Voltage (V)", volt),
                    y: .value("Frequency (MHz)", speed)
                )
                .foregroundStyle(Color.tahoeAccentCyan)
                .symbolSize(80)
                .annotation(position: .top, alignment: .center) {
                    Text("P\(row.id)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.tahoeText)
                        .padding(2)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(Color.white.opacity(0.05))
                AxisValueLabel {
                    if let volt = value.as(Double.self) {
                        Text(String(format: "%.3f V", volt))
                            .font(.system(size: 8))
                            .foregroundColor(.tahoeSubtext)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(Color.white.opacity(0.05))
                AxisValueLabel {
                    if let speed = value.as(Double.self) {
                        Text(String(format: "%.0f MHz", speed))
                            .font(.system(size: 8))
                            .foregroundColor(.tahoeSubtext)
                    }
                }
            }
        }
    }
}

private struct PStateEditorView: View {
    @ObservedObject var model: TelemetryModel
    @State private var showApplyConfirm = false
    @State private var applyOK: Bool? = nil
    @State private var isUnlocked = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Safety unlock toggle
            HStack(spacing: 10) {
                Image(systemName: isUnlocked ? "lock.open.trianglebadge.exclamationmark.fill" : "lock.fill")
                    .foregroundColor(isUnlocked ? .tahoeAccentCyan : .tahoeAccentOrange)
                    .font(.system(size: 14))
                
                Toggle("Unlock P-State Editor (DANGEROUS: incorrect settings can crash or damage hardware)", isOn: $isUnlocked)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isUnlocked ? .tahoeText : .tahoeAccentOrange)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isUnlocked ? Color.tahoeAccentCyan.opacity(0.06) : Color.tahoeAccentOrange.opacity(0.08))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isUnlocked ? Color.tahoeAccentCyan.opacity(0.2) : Color.tahoeAccentOrange.opacity(0.2), lineWidth: 1)
            )
            
            HStack(alignment: .top, spacing: 18) {
                // Left side: Chart View
                VStack(alignment: .leading, spacing: 8) {
                    Text("V-F Operating Curve")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.tahoeSubtext)
                    
                    PStateChartView(pStateRows: model.pStateRows, isZen5: model.pStateRows.first?.isZen5 ?? false)
                        .frame(height: 280)
                        .padding(12)
                        .background(Color.tahoeBackground.opacity(0.4))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.tahoeCardBorder))
                }
                .frame(width: 320)
                
                // Right side: Controls List
                VStack(alignment: .leading, spacing: 8) {
                    Text("P-States Configuration")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.tahoeSubtext)
                    
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach($model.pStateRows) { $row in
                                PStateRowControlView(row: $row, isDirty: $model.pStateEditorDirty)
                            }
                        }
                        .padding(.trailing, 4)
                    }
                    .frame(height: 280)
                }
            }
            .opacity(isUnlocked ? 1.0 : 0.4)
            .disabled(!isUnlocked)
            .animation(.easeInOut(duration: 0.25), value: isUnlocked)
            
            // Actions
            HStack(spacing: 8) {
                TahoeButton(label: "Apply", icon: "checkmark.circle", accent: .tahoeAccentCyan) { showApplyConfirm = true }
                    .disabled(!isUnlocked)
                TahoeButton(label: "Revert", icon: "arrow.counterclockwise", accent: .tahoeAccentOrange) { model.loadPStateRows() }
                    .disabled(!isUnlocked)
                TahoeButton(label: "Import", icon: "square.and.arrow.down", accent: .tahoeAccentGreen) {
                    let op = NSOpenPanel()
                    op.allowedContentTypes = [.init(filenameExtension: "pstate") ?? .data]
                    if op.runModal() == .OK, let url = op.url { model.importPStates(from: url) }
                }
                .disabled(!isUnlocked)
                TahoeButton(label: "Export", icon: "square.and.arrow.up", accent: .tahoeAccentPurple) {
                    let op = NSSavePanel()
                    op.isExtensionHidden = false
                    op.allowedContentTypes = [.init(filenameExtension: "pstate") ?? .data]
                    if op.runModal() == .OK, let url = op.url { model.exportPStates(to: url) }
                }
                .disabled(!isUnlocked)
            }
            
            if let ok = applyOK {
                Text(ok ? "P-States applied successfully." : "Failed — check kext privileges (-amdpnopchk).")
                    .font(.system(size: 11)).foregroundColor(ok ? .tahoeAccentGreen : .tahoeAccentRed)
            }
        }
        .padding(14)
        .background(Color.tahoeCard.opacity(0.85))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(model.pStateEditorDirty ? Color.tahoeAccentOrange.opacity(0.5) : Color.tahoeCardBorder))
        .cornerRadius(14)
        .confirmationDialog("Apply P-States?", isPresented: $showApplyConfirm, titleVisibility: .visible) {
            Button("Apply", role: .destructive) { applyOK = model.applyPStates() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This will write the raw P-State definitions directly to the CPU. Proceed?") }
    }
}

private struct PStateRowControlView: View {
    @Binding var row: PStateRow
    @Binding var isDirty: Bool
    @State private var isExpanded = false
    
    var body: some View {
        let step = row.isZen5 ? 0.005 : 0.00625
        let currentVoltage = 1.55 - Double(row.cpuVid) * step
        let currentSpeed = Double(row.computedSpeedMHz)
        
        VStack(alignment: .leading, spacing: 6) {
            // Header Row
            HStack {
                Text("P-State \(row.id)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(row.enabled == 1 ? .tahoeText : .tahoeSubtext)
                
                Spacer()
                
                Toggle(row.enabled == 1 ? "Active" : "Inactive", isOn: Binding(
                    get: { row.enabled == 1 },
                    set: { newValue in
                        row.enabled = newValue ? 1 : 0
                        if newValue {
                            // Set safe defaults if the state was uninitialized/zero
                            if row.cpuFid == 0 {
                                if row.isZen5 {
                                    row.cpuFid = 440 // 440 * 5 = 2200 MHz
                                } else {
                                    row.cpuFid = 88 // (88 / 8) * 200 = 2200 MHz
                                    row.cpuDfsId = 8
                                }
                            }
                            if row.cpuVid == 0 || row.cpuVid > 255 {
                                row.cpuVid = 56 // 1.2V
                            }
                        }
                        isDirty = true
                    }
                ))
                .toggleStyle(.switch)
                .scaleEffect(0.7)
                .labelsHidden()
                
                Text(row.enabled == 1 ? "Active" : "Inactive")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(row.enabled == 1 ? .tahoeAccentCyan : .tahoeSubtext)
                    .frame(width: 42, alignment: .trailing)
            }
            
            if row.enabled == 1 {
                VStack(spacing: 8) {
                    // Frequency Control
                    HStack(spacing: 10) {
                        Text("Freq:")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.tahoeSubtext)
                            .frame(width: 32, alignment: .leading)
                        
                        Slider(value: Binding(
                            get: { max(800.0, min(6000.0, Double(row.computedSpeedMHz))) },
                            set: { newValue in
                                if row.isZen5 {
                                    row.cpuFid = UInt32(max(0, min(4095, round(newValue / 5.0))))
                                } else {
                                    let dfs = row.cpuDfsId > 0 ? Double(row.cpuDfsId) : 8.0
                                    row.cpuFid = UInt32(max(0, min(255, round((newValue / 200.0) * dfs))))
                                }
                                isDirty = true
                            }
                        ), in: 800...6000, step: 25)
                        .tint(Color.tahoeAccentCyan)
                        
                        Text(String(format: "%.0f MHz", currentSpeed))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.tahoeAccentCyan)
                            .frame(width: 65, alignment: .trailing)
                    }
                    
                    // Voltage Control
                    HStack(spacing: 10) {
                        Text("Volt:")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.tahoeSubtext)
                            .frame(width: 32, alignment: .leading)
                        
                        Slider(value: Binding(
                            get: { max(0.55, min(1.55, currentVoltage)) },
                            set: { newValue in
                                let rawVid = (1.55 - newValue) / step
                                row.cpuVid = UInt32(max(0, min(255, round(rawVid))))
                                isDirty = true
                            }
                        ), in: 0.55...1.55, step: step)
                        .tint(Color.tahoeAccentOrange)
                        
                        Text(String(format: "%.4f V", currentVoltage))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.tahoeAccentOrange)
                            .frame(width: 65, alignment: .trailing)
                    }
                }
                .padding(.vertical, 4)
                
                // Raw Details Disclosure Group
                DisclosureGroup(isExpanded: $isExpanded) {
                    VStack(spacing: 6) {
                        HStack(spacing: 10) {
                            RawField(label: "FID", value: Binding(
                                get: { String(format: "%X", row.cpuFid) },
                                set: { newValue in
                                    if let v = UInt32(newValue, radix: 16) {
                                        row.cpuFid = v
                                        isDirty = true
                                    }
                                }
                            ))
                            
                            if !row.isZen5 {
                                RawField(label: "DID", value: Binding(
                                    get: { String(format: "%X", row.cpuDfsId) },
                                    set: { newValue in
                                        if let v = UInt32(newValue, radix: 16) {
                                            row.cpuDfsId = v
                                            isDirty = true
                                        }
                                    }
                                ))
                            }
                            
                            RawField(label: "VID", value: Binding(
                                get: { String(format: "%X", row.cpuVid) },
                                set: { newValue in
                                    if let v = UInt32(newValue, radix: 16) {
                                        row.cpuVid = v
                                        isDirty = true
                                    }
                                }
                            ))
                        }
                        
                        HStack(spacing: 10) {
                            RawField(label: "IddDiv", value: Binding(
                                get: { String(format: "%X", row.iddDiv) },
                                set: { newValue in
                                    if let v = UInt32(newValue, radix: 16) {
                                        row.iddDiv = v
                                        isDirty = true
                                    }
                                }
                            ))
                            
                            RawField(label: "IddVal", value: Binding(
                                get: { String(format: "%X", row.iddValue) },
                                set: { newValue in
                                    if let v = UInt32(newValue, radix: 16) {
                                        row.iddValue = v
                                        isDirty = true
                                    }
                                }
                            ))
                        }
                    }
                    .padding(.top, 4)
                } label: {
                    Text("Raw Register Details")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.tahoeSubtext)
                }
                .accentColor(.tahoeSubtext)
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isExpanded)
            }
        }
        .padding(10)
        .background(row.enabled == 1 ? Color.tahoeAccentCyan.opacity(0.04) : Color.tahoeBackground.opacity(0.2))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(row.enabled == 1 ? Color.tahoeAccentCyan.opacity(0.15) : Color.tahoeCardBorder))
    }
}

private struct RawField: View {
    let label: String
    @Binding var value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text("\(label):")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.tahoeSubtext)
            
            TextField("", text: $value)
                .textFieldStyle(.plain)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.tahoeText)
                .multilineTextAlignment(.center)
                .frame(width: 32)
                .padding(.vertical, 2)
                .background(Color.tahoeBackground.opacity(0.6))
                .cornerRadius(4)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.tahoeCardBorder))
        }
    }
}

struct TempThresholdField: View {
    @Binding var value: Int
    @State private var text = ""
    
    var body: some View {
        HStack(spacing: 4) {
            TextField("", text: $text, onEditingChanged: { editing in
                if !editing {
                    if let val = Int(text.trimmingCharacters(in: .whitespacesAndNewlines)) {
                        value = max(30, min(100, val))
                    }
                    text = "\(value)"
                }
            })
            .textFieldStyle(.plain)
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .foregroundColor(.tahoeAccentOrange)
            .multilineTextAlignment(.trailing)
            .frame(width: 45)
            .onAppear {
                text = "\(value)"
            }
            .onChange(of: value) { newValue in
                text = "\(newValue)"
            }
            
            Text("°C")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.tahoeSubtext)
        }
        .padding(.vertical, 4).padding(.horizontal, 8)
        .background(Color.tahoeBackground.opacity(0.4))
        .cornerRadius(6)
    }
}

struct VerticalLabelView: View {
    let text: String
    var body: some View {
        let chars = Array(text.map { String($0) })
        VStack(spacing: -1.5) {
            ForEach(0..<chars.count, id: \.self) { idx in
                Text(chars[idx])
                    .font(.system(size: 7.2, weight: .regular, design: .monospaced))
            }
        }
        .frame(width: 7)
        .foregroundColor(.white.opacity(0.8))
    }
}

struct MenuBarPreview: View {
    let cfg: MenuBarConfig
    @ObservedObject var model: TelemetryModel = TelemetryModel.shared
    
    private func formatSpeed(_ mbps: Double) -> String {
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
    
    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                // CPU Column
                if cfg.showCPU {
                    HStack(spacing: 2) {
                        VerticalLabelView(text: "CPU")
                        
                        let maxFr = String(format: "%.1f", model.cpuFreqMaxGHz)
                        let avgFr = String(format: "%.1f", model.cpuFreqAvgGHz)
                        
                        if cfg.showMaxFreqOnly {
                            Text("\(maxFr)G")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("\(maxFr)Ghz").font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                                Text("\(avgFr)Ghz").font(.system(size: 9, weight: .semibold)).foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    .frame(width: cfg.showMaxFreqOnly ? 48 : 56, alignment: .leading)
                }
                
                // Temp Column
                if cfg.showTemp {
                    let tempVal = model.cpuTempC
                    let cTemp = cfg.useFahrenheit ? (tempVal * 9.0 / 5.0 + 32.0) : tempVal
                    let isAlert = cfg.enableColorAlerts && tempVal >= Double(cfg.tempThreshold)
                    let tempColor = isAlert ? getSwiftUIColor(index: cfg.tempColorIdx) : Color.white
                    
                    HStack(spacing: 2) {
                        VerticalLabelView(text: "TMP")
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text(String(format: "C:%.0f\(cfg.useFahrenheit ? "F" : "º")", cTemp))
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(tempColor)
                            
                            if cfg.showGPU && cfg.showGPUtemp {
                                let gpuTemp = model.gpuTempC
                                let gTemp = cfg.useFahrenheit ? (gpuTemp * 9.0 / 5.0 + 32.0) : gpuTemp
                                let gpuIsAlert = cfg.enableColorAlerts && gpuTemp >= Double(cfg.tempThreshold)
                                let gpuColor = gpuIsAlert ? getSwiftUIColor(index: cfg.tempColorIdx) : Color.white
                                Text(String(format: "G:%.0f\(cfg.useFahrenheit ? "F" : "º")", gTemp))
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(gpuColor)
                            } else {
                                Text("—")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    .frame(width: 56, alignment: .leading)
                }
                
                // Power Column
                if cfg.showPower {
                    let cPwr = String(format: "C:%.0fW", model.cpuWatts)
                    let gPwr = cfg.showGPU && cfg.showGPUpwr ? String(format: "G:%.0fW", model.gpuPowerW) : ""
                    
                    HStack(spacing: 2) {
                        VerticalLabelView(text: "PWR")
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text(cPwr).font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                            if !gPwr.isEmpty {
                                Text(gPwr).font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                            } else {
                                Text("—").font(.system(size: 9, weight: .semibold)).foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    .frame(width: 56, alignment: .leading)
                }
                
                // Fan Column
                if cfg.showFanRPM {
                    let fanVal = model.fans.first?.rpm ?? 0
                    let fan = String(fanVal)
                    
                    HStack(spacing: 2) {
                        VerticalLabelView(text: "FAN")
                        
                        VStack(alignment: .leading, spacing: 0) {
                            if cfg.showGPU && cfg.showGPUfan {
                                let gFanStr = String(format: "G:%.0f", model.gpuFanRPM)
                                Text("C:\(fan)").font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                                Text(gFanStr).font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                            } else {
                                Text(fan).font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                                Text("RPM").font(.system(size: 9, weight: .semibold)).foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    .frame(width: 56, alignment: .leading)
                }
                
                // Memory Column
                if cfg.showMemory {
                    let memoryUsed = Double(model.sysInfo.ramGB) * model.ramUsagePct / 100.0
                    let used = String(format: "%.1fG", memoryUsed)
                    let totalMem = "\(model.sysInfo.ramGB)G"
                    
                    HStack(spacing: 2) {
                        VerticalLabelView(text: "MEM")
                        
                        VStack(alignment: .leading, spacing: 0) {
                            if cfg.showGPU && cfg.showGPUvram {
                                let vramGB = model.gpuVramUsedBytes / (1024.0 * 1024.0 * 1024.0)
                                let vramStr = String(format: "G:%.1fG", vramGB)
                                Text("S:\(used)").font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                                Text(vramStr).font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                            } else {
                                Text(used).font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                                Text(totalMem).font(.system(size: 9, weight: .semibold)).foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    .frame(width: 56, alignment: .leading)
                }
                
                // Network Column
                if cfg.showNetwork {
                    let arrowColor = getSwiftUIColor(index: cfg.netColorIdx)
                    HStack(spacing: 2) {
                        VerticalLabelView(text: "NET")
                        
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 1) {
                                Text("↑").font(.system(size: 9, weight: .bold)).foregroundColor(arrowColor)
                                Text(formatSpeed(model.netUploadMBps)).font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                            }
                            HStack(spacing: 1) {
                                Text("↓").font(.system(size: 9, weight: .bold)).foregroundColor(arrowColor)
                                Text(formatSpeed(model.netDownloadMBps)).font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                            }
                        }
                    }
                    .frame(width: 68, alignment: .leading)
                }
            }
            .padding(.horizontal, 8)
            .frame(height: 22)
            .background(Color.black.opacity(0.35))
            .cornerRadius(4)
        }
    }
    
    private func getSwiftUIColor(index: Int) -> Color {
        switch index {
        case 0: return .green
        case 1: return .blue
        case 2: return .orange
        case 3: return .red
        case 4: return .purple
        case 5: return .pink
        case 6: return Color(red: 0.18, green: 0.80, blue: 0.80) // Teal
        default: return .green
        }
    }
}

// MARK: - Menu Bar Config Tab
struct MenuBarConfigView: View {
    @ObservedObject var model: TelemetryModel
    @State private var cfg = MenuBarConfig.shared
    @State private var needsRestart = false
    @State private var refreshToggle = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle("Menu Bar Layout")
                Text("Choose which items appear in the menu bar. Changes apply immediately.")
                    .font(.system(size: 12)).foregroundColor(.tahoeSubtext)

                ToggleRow(label: "Show CPU", detail: "Frequency column (max/avg GHz)", isOn: .init(
                    get: { cfg.showCPU }, set: { cfg.showCPU = $0; notify() }
                ), accent: .tahoeAccentCyan) { _ in }

                if cfg.showCPU {
                    ToggleRow(label: "   Show Max Freq Only", detail: "Single large value instead of max/avg stack", isOn: .init(
                        get: { cfg.showMaxFreqOnly }, set: { cfg.showMaxFreqOnly = $0; notify() }
                    ), accent: .tahoeAccentCyan.opacity(0.8)) { _ in }
                }

                ToggleRow(label: "Show Temperature", detail: "CPU temp + optional GPU temp", isOn: .init(
                    get: { cfg.showTemp }, set: { cfg.showTemp = $0; notify() }
                ), accent: .tahoeAccentOrange) { _ in }

                if cfg.showTemp {
                    ToggleRow(label: "   Use Fahrenheit", detail: "Convert temperature values from Celsius to Fahrenheit", isOn: .init(
                        get: { cfg.useFahrenheit }, set: { cfg.useFahrenheit = $0; notify() }
                    ), accent: .tahoeAccentOrange.opacity(0.8)) { _ in }
                }

                ToggleRow(label: "Show Power", detail: "CPU watts + optional GPU watts", isOn: .init(
                    get: { cfg.showPower }, set: { cfg.showPower = $0; notify() }
                ), accent: .tahoeAccentGreen) { _ in }

                Divider().background(Color.tahoeCardBorder)

                SectionTitle("Extra Items")
                Text("Additional telemetry for the menu bar.")
                    .font(.system(size: 12)).foregroundColor(.tahoeSubtext)

                ToggleRow(label: "Show Fan RPM", detail: "First fan speed in RPM", isOn: .init(
                    get: { cfg.showFanRPM }, set: { cfg.showFanRPM = $0; notify() }
                ), accent: .tahoeAccentBlue) { _ in }

                if cfg.showFanRPM {
                    HStack {
                        Text("Fan Number").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                        Spacer()
                        Picker("", selection: .init(
                            get: { cfg.fanIndex },
                            set: { cfg.fanIndex = $0; notify() }
                        )) {
                            ForEach(0..<max(1, model.fans.count), id: \.self) { idx in
                                Text(LocalizedStringKey("Fan \(idx + 1)")).tag(idx)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 140)
                    }
                    .padding(.vertical, 8).padding(.horizontal, 14)
                    .background(Color.tahoeCard)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.tahoeCardBorder))
                    .cornerRadius(8)
                }

                ToggleRow(label: "Show Memory", detail: "Used memory in GB", isOn: .init(
                    get: { cfg.showMemory }, set: { cfg.showMemory = $0; notify() }
                ), accent: .tahoeAccentPurple) { _ in }

                ToggleRow(label: "Show Network", detail: "Real-time upload / download speed (↑/↓)", isOn: .init(
                    get: { cfg.showNetwork }, set: { cfg.showNetwork = $0; notify() }
                ), accent: .tahoeAccentRed) { _ in }

                if cfg.showNetwork {
                    HStack {
                        Text("Arrow Color").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                        Spacer()
                        Picker("", selection: .init(
                            get: { cfg.netColorIdx },
                            set: { cfg.netColorIdx = $0; notify() }
                        )) {
                            Text("Green").tag(0)
                            Text("Blue").tag(1)
                            Text("Orange").tag(2)
                            Text("Red").tag(3)
                            Text("Purple").tag(4)
                            Text("Pink").tag(5)
                            Text("Teal").tag(6)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 150)
                    }
                    .padding(.vertical, 8).padding(.horizontal, 14)
                    .background(Color.tahoeCard)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.tahoeCardBorder))
                    .cornerRadius(8)
                }

                Divider().background(Color.tahoeCardBorder)
                SectionTitle("GPU Items")
                Text("GPU data is shown inside Temp, Power, Memory and Fan columns when enabled.")
                    .font(.system(size: 12)).foregroundColor(.tahoeSubtext)

                ToggleRow(label: "Show GPU Temp", detail: "G:XX°C in Temp column", isOn: .init(
                    get: { cfg.showGPUtemp }, set: { cfg.showGPUtemp = $0; notify() }
                ), accent: .tahoeAccentPurple) { _ in }

                ToggleRow(label: "Show GPU Power", detail: "G:XXW in Power column", isOn: .init(
                    get: { cfg.showGPUpwr }, set: { cfg.showGPUpwr = $0; notify() }
                ), accent: .tahoeAccentPurple) { _ in }

                ToggleRow(label: "Show GPU VRAM", detail: "G:X.XG in Memory column", isOn: .init(
                    get: { cfg.showGPUvram }, set: { cfg.showGPUvram = $0; notify() }
                ), accent: .tahoeAccentPurple) { _ in }

                ToggleRow(label: "Show GPU Fan Speed", detail: "G:XXXX in Fan column", isOn: .init(
                    get: { cfg.showGPUfan }, set: { cfg.showGPUfan = $0; notify() }
                ), accent: .tahoeAccentPurple) { _ in }

                Divider().background(Color.tahoeCardBorder)
                SectionTitle("Styles & Themes")
                Text("Customize the visual appearance of the menu bar items.")
                    .font(.system(size: 12)).foregroundColor(.tahoeSubtext)

                ToggleRow(label: "Dynamic Color Alerts", detail: "Color values based on temperature and load status", isOn: .init(
                    get: { cfg.enableColorAlerts }, set: { cfg.enableColorAlerts = $0; notify() }
                ), accent: .tahoeAccentRed) { _ in }

                if cfg.enableColorAlerts {
                    HStack {
                        Text("Temp Alert Color").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                        Spacer()
                        Picker("", selection: .init(
                            get: { cfg.tempColorIdx },
                            set: { cfg.tempColorIdx = $0; notify() }
                        )) {
                            Text("Green").tag(0)
                            Text("Blue").tag(1)
                            Text("Orange").tag(2)
                            Text("Red").tag(3)
                            Text("Purple").tag(4)
                            Text("Pink").tag(5)
                            Text("Teal").tag(6)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 150)
                    }
                    .padding(.vertical, 8).padding(.horizontal, 14)
                    .background(Color.tahoeCard)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.tahoeCardBorder))
                    .cornerRadius(8)
                    
                    HStack {
                        Text("Límite de Temp de Alerta").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                        Spacer()
                        TempThresholdField(value: .init(
                            get: { cfg.tempThreshold },
                            set: { cfg.tempThreshold = $0; notify() }
                        ))
                    }
                    .padding(.vertical, 8).padding(.horizontal, 14)
                    .background(Color.tahoeCard)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.tahoeCardBorder))
                    .cornerRadius(8)

                    HStack {
                        Text("Opciones en Menú Bar").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                        Spacer()
                        TextField("Ej: 30, 40, 50...", text: .init(
                            get: { cfg.tempPresetList },
                            set: { cfg.tempPresetList = $0; notify() }
                        ))
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.tahoeAccentCyan)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 250)
                        .padding(.vertical, 4).padding(.horizontal, 8)
                        .background(Color.tahoeBackground.opacity(0.4))
                        .cornerRadius(6)
                    }
                    .padding(.vertical, 8).padding(.horizontal, 14)
                    .background(Color.tahoeCard)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.tahoeCardBorder))
                    .cornerRadius(8)
                }



                if needsRestart {
                    TahoeCard(accent: Color.tahoeAccentOrange.opacity(0.3)) {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.circle").foregroundColor(.tahoeAccentOrange)
                            Text("Restart the app to fully apply width changes.").font(.system(size: 12)).foregroundColor(.tahoeText)
                        }
                    }
                }

                Divider().background(Color.tahoeCardBorder)
                SectionTitle("Preview")
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Menu Bar Preview:")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.tahoeSubtext)
                    
                    MenuBarPreview(cfg: cfg, model: model)
                        .id(refreshToggle)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.tahoeBackground.opacity(0.6))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.tahoeCardBorder))
                        )
                    
                    Text("Estimated Width: \(Int(cfg.totalWidth))pt")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.tahoeSubtext)
                }
                .padding(.top, 4)
            }
            .padding(18)
        }
    }

    private func notify(widthChanged: Bool = true) {
        cfg = MenuBarConfig()
        refreshToggle.toggle()
        NotificationCenter.default.post(name: .init("MenuBarConfigChanged"), object: nil)
        if widthChanged {
            needsRestart = true
        }
    }
}

// MARK: - System Info Tab
struct PhysicalCoreCPPC: Identifiable {
    let id: Int
    let score: UInt8
    let isEstimated: Bool
    var rank: Int = 0
    
    var rankText: String {
        return "\(rank)."
    }
    
    var scoreText: String {
        return (isEstimated ? "~" : "") + String(score)
    }
}

// Dedicated row view for CPPC grid to avoid Swift WMO type-checker timeouts inside generic TahoeCard closures
private struct CPPCCoreGridRow: View {
    let item: RankedPhysicalCore
    
    @ViewBuilder private var rankIcon: some View {
        if item.rank == 1 {
            Image(systemName: "crown.fill").foregroundColor(Color.tahoeAccentOrange)
        } else if item.rank == 2 {
            Image(systemName: "star.fill").foregroundColor(Color.tahoeAccentCyan)
        } else if item.rank == 3 {
            Image(systemName: "star.fill").foregroundColor(Color.white.opacity(0.5))
        } else {
            Image(systemName: "cpu").foregroundColor(Color.white.opacity(0.2))
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Text(item.rankText)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color.white.opacity(0.4))
                .frame(width: 22, alignment: .trailing)
            rankIcon
            Text("Core \(item.id)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color.white)
            Spacer()
            Text(item.scoreText)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(item.score > 200 ? Color.tahoeAccentGreen : (item.score > 150 ? Color.tahoeAccentOrange : Color.tahoeSubtext))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.white.opacity(0.04))
                .cornerRadius(4)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.02))
        .cornerRadius(6)
    }
}

private struct CPPCCoreGrid: View {
    let items: [RankedPhysicalCore]
    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(items, id: \.id) { item in
                    CPPCCoreGridRow(item: item)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.tahoeCard)
                .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
        )
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.tahoeCardBorder, lineWidth: 1))
        .cornerRadius(14)
    }
}

struct ThemeSelectorGrid: View {
    @AppStorage("app_theme_preset") private var selectedThemeRaw: String = AppTheme.tahoe.rawValue
    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(AppTheme.allCases) { theme in
                let isSelected = selectedThemeRaw == theme.rawValue
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedThemeRaw = theme.rawValue
                    }
                }) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(theme.rawValue)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(isSelected ? .white : .tahoeText)
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(theme.accentCyan)
                            }
                        }
                        
                        // Mini Live Palette Preview Card
                        HStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 4).fill(theme.accentCyan).frame(height: 12)
                            RoundedRectangle(cornerRadius: 4).fill(theme.accentOrange).frame(height: 12)
                            RoundedRectangle(cornerRadius: 4).fill(theme.accentGreen).frame(height: 12)
                            RoundedRectangle(cornerRadius: 4).fill(theme.accentPurple).frame(height: 12)
                        }
                        .padding(6)
                        .background(theme.card)
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }
                    .padding(14)
                    .background(theme.card.opacity(isSelected ? 1.0 : 0.6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? theme.accentCyan : Color.white.opacity(0.08), lineWidth: isSelected ? 2 : 1)
                    )
                    .shadow(color: isSelected ? theme.accentCyan.opacity(0.3) : Color.clear, radius: 8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

enum AppChartStyle: String, CaseIterable, Identifiable {
    case line = "Línea Suave (Spline)"
    case filledArea = "Área Rellena (Gradient)"
    case bar = "Histograma de Barras"
    case steppedLine = "Línea Escalonada (Step)"
    
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .line: return "waveform.path.ecg"
        case .filledArea: return "chart.area.fill"
        case .bar: return "chart.bar.fill"
        case .steppedLine: return "chart.line.uptrend.xyaxis"
        }
    }
}

struct ChartStyleSelectorGrid: View {
    @AppStorage("app_chart_style") private var selectedStyleRaw: String = AppChartStyle.line.rawValue
    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(AppChartStyle.allCases) { style in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedStyleRaw = style.rawValue
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: style.icon)
                            .foregroundColor(selectedStyleRaw == style.rawValue ? Color.tahoeAccentCyan : .tahoeSubtext)
                        Text(style.rawValue)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(selectedStyleRaw == style.rawValue ? .white : .tahoeSubtext)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(selectedStyleRaw == style.rawValue ? Color.white.opacity(0.1) : Color.white.opacity(0.03))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(selectedStyleRaw == style.rawValue ? Color.tahoeAccentCyan : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.tahoeCard)
                .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
        )
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.tahoeCardBorder, lineWidth: 1))
        .cornerRadius(14)
    }
}

extension Color {
    init?(hexString: String) {
        var clean = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.hasPrefix("#") {
            clean.removeFirst()
        }
        guard clean.count == 3 || clean.count == 6 || clean.count == 8 else { return nil }
        guard clean.allSatisfy({ $0.isHexDigit }) else { return nil }
        
        var int: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch clean.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: return nil
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }

    var toHexString: String {
        guard let nsColor = NSColor(self).usingColorSpace(.sRGB) else { return "#000000" }
        let r = Int(nsColor.redComponent * 255)
        let g = Int(nsColor.greenComponent * 255)
        let b = Int(nsColor.blueComponent * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

struct ThemePresetPack: Codable {
    var name: String
    var cardHex: String
    var cyanHex: String
    var orangeHex: String
    var greenHex: String
    var purpleHex: String
}

struct ColorTokenEditorSlot: View {
    let title: String
    let colorHex: String
    @Binding var selection: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.tahoeSubtext)
            HStack(spacing: 8) {
                ColorPicker("", selection: $selection)
                    .labelsHidden()
                Text(colorHex)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.04))
            .cornerRadius(8)
        }
    }
}

struct CustomThemeStudio: View {
    @AppStorage("custom_hex_card") private var cardHex: String = "#16213E"
    @AppStorage("custom_hex_cyan") private var cyanHex: String = "#4CC9F0"
    @AppStorage("custom_hex_orange") private var orangeHex: String = "#FF8C00"
    @AppStorage("custom_hex_green") private var greenHex: String = "#00FF7F"
    @AppStorage("custom_hex_purple") private var purpleHex: String = "#A020F0"
    @AppStorage("app_theme_preset") private var selectedThemeRaw: String = AppTheme.tahoe.rawValue

    private var cardColorBinding: Binding<Color> {
        Binding(get: { Color(hexString: cardHex) ?? .blue }, set: { cardHex = $0.toHexString; selectedThemeRaw = AppTheme.custom.rawValue })
    }
    private var cyanColorBinding: Binding<Color> {
        Binding(get: { Color(hexString: cyanHex) ?? .cyan }, set: { cyanHex = $0.toHexString; selectedThemeRaw = AppTheme.custom.rawValue })
    }
    private var orangeColorBinding: Binding<Color> {
        Binding(get: { Color(hexString: orangeHex) ?? .orange }, set: { orangeHex = $0.toHexString; selectedThemeRaw = AppTheme.custom.rawValue })
    }
    private var greenColorBinding: Binding<Color> {
        Binding(get: { Color(hexString: greenHex) ?? .green }, set: { greenHex = $0.toHexString; selectedThemeRaw = AppTheme.custom.rawValue })
    }
    private var purpleColorBinding: Binding<Color> {
        Binding(get: { Color(hexString: purpleHex) ?? .purple }, set: { purpleHex = $0.toHexString; selectedThemeRaw = AppTheme.custom.rawValue })
    }

    private func copyCurrentThemeToCustom() {
        let curr = AppTheme.current
        cardHex = curr.card.toHexString
        cyanHex = curr.accentCyan.toHexString
        orangeHex = curr.accentOrange.toHexString
        greenHex = curr.accentGreen.toHexString
        purpleHex = curr.accentPurple.toHexString
        selectedThemeRaw = AppTheme.custom.rawValue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Editor de Tema Personalizado")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    Text("Mostrando los colores actuales del tema activo. Ajustá cualquier color para personalizar.")
                        .font(.system(size: 10))
                        .foregroundColor(.tahoeSubtext)
                }
                Spacer()
                TahoeButton(label: "Editar Tema Activo", icon: "doc.on.doc", accent: .tahoeAccentOrange) {
                    copyCurrentThemeToCustom()
                }
            }

            // Grid of Color Token Editors showing active colors & HEX
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 10)], spacing: 10) {
                ColorTokenEditorSlot(title: "Fondo Tarjeta", colorHex: AppTheme.current.card.toHexString, selection: cardColorBinding)
                ColorTokenEditorSlot(title: "Acento Cian", colorHex: AppTheme.current.accentCyan.toHexString, selection: cyanColorBinding)
                ColorTokenEditorSlot(title: "Acento Naranja", colorHex: AppTheme.current.accentOrange.toHexString, selection: orangeColorBinding)
                ColorTokenEditorSlot(title: "Acento Verde", colorHex: AppTheme.current.accentGreen.toHexString, selection: greenColorBinding)
                ColorTokenEditorSlot(title: "Acento Púrpura", colorHex: AppTheme.current.accentPurple.toHexString, selection: purpleColorBinding)
            }

            Divider().background(Color.tahoeCardBorder)

            HStack(spacing: 12) {
                TahoeButton(label: "Exportar Tema (JSON)", icon: "square.and.arrow.up", accent: .tahoeAccentCyan) {
                    exportTheme()
                }
                TahoeButton(label: "Importar Tema (JSON)", icon: "square.and.arrow.down", accent: .tahoeAccentGreen) {
                    importTheme()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.tahoeCard)
                .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
        )
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.tahoeCardBorder, lineWidth: 1))
        .cornerRadius(14)
    }

    private func exportTheme() {
        let pack = ThemePresetPack(name: "Mi Tema Custom", cardHex: cardHex, cyanHex: cyanHex, orangeHex: orangeHex, greenHex: greenHex, purpleHex: purpleHex)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(pack) {
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.json]
            panel.nameFieldStringValue = "MiTemaCustom.json"
            panel.begin { resp in
                if resp == .OK, let url = panel.url {
                    try? data.write(to: url)
                }
            }
        }
    }

    private func importTheme() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.begin { resp in
            if resp == .OK, let url = panel.url, let data = try? Data(contentsOf: url) {
                if let pack = try? JSONDecoder().decode(ThemePresetPack.self, from: data) {
                    cardHex = pack.cardHex
                    cyanHex = pack.cyanHex
                    orangeHex = pack.orangeHex
                    greenHex = pack.greenHex
                    purpleHex = pack.purpleHex
                    selectedThemeRaw = AppTheme.custom.rawValue
                }
            }
        }
    }
}

struct ThemesContentView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SectionTitle("Seleccionar Tema Visual (Cambio Instantáneo)")
                ThemeSelectorGrid()

                SectionTitle("Creador e Intercambio de Temas Custom (JSON)")
                CustomThemeStudio()

                SectionTitle("Estilo de Renderizado de Gráficas")
                ChartStyleSelectorGrid()
            }
            .padding(20)
        }
    }
}

struct SystemInfoContentView: View {
    @ObservedObject var model: TelemetryModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionTitle("Processor")
                TahoeCard {
                    InfoRow(label: "CPU Model",      value: model.sysInfo.cpuBrand)
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "Family",          value: model.sysInfo.cpuFamily)
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "Model ID",        value: model.sysInfo.cpuModel)
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "Physical Cores",  value: "\(model.sysInfo.physicalCores)")
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "Logical Cores",   value: "\(model.sysInfo.logicalCores)")
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "L1 Cache (Total)",value: "\(model.sysInfo.l1KB) KB")
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "L2 Cache (Total)",value: "\(model.sysInfo.l2MB) MB")
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "L3 Cache (Shared)",value: "\(model.sysInfo.l3MB) MB")
                }

                if !model.rankedPhysicalCores.isEmpty {
                    Divider().background(Color.tahoeCardBorder)
                    SectionTitle(model.rankedPhysicalCores.first?.isEstimated == true ? "Core Rankings (Estimated by Freq)" : "CPPC Preferred Cores (Silicon Quality)")
                    CPPCCoreGrid(items: model.rankedPhysicalCores)
                }

                Divider().background(Color.tahoeCardBorder)
                SectionTitle("Platform")
                TahoeCard {
                    if !model.sysInfo.boardName.isEmpty {
                        InfoRow(label: "Motherboard", value: model.sysInfo.boardName)
                        Divider().background(Color.tahoeCardBorder)
                        InfoRow(label: "Manufacturer", value: model.sysInfo.boardVendor)
                        Divider().background(Color.tahoeCardBorder)
                    }
                    InfoRow(label: "Graphics", value: model.sysInfo.gpuModel.isEmpty ? "Unknown" : model.sysInfo.gpuModel)
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "Memory",   value: "\(model.sysInfo.ramGB) GB")
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "Storage",  value: "\(model.sysInfo.storageGB) GB")
                }
                if model.sysInfo.boardName.isEmpty {
                    TahoeCard(accent: Color.tahoeAccentOrange.opacity(0.3)) {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle").foregroundColor(.tahoeAccentOrange)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Motherboard info not available").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                                Text("Enable in OC: Misc → Security → ExposeSensitiveData = 0x08").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                            }
                        }
                    }
                }

                Divider().background(Color.tahoeCardBorder)
                SectionTitle("Software")
                TahoeCard {
                    InfoRow(label: "macOS Version",   value: model.sysInfo.macOSVersion)
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "Kext Version",    value: model.sysInfo.kextVersion)
                    Divider().background(Color.tahoeCardBorder)
                    InfoRow(label: "CPU Supported",   value: model.sysInfo.kextSupported ? "Yes" : "Not yet")
                }

                Divider().background(Color.tahoeCardBorder)
                SectionTitle("Links & Support")
                HStack(spacing: 10) {
                    TahoeButton(label: "GitHub Repository", icon: "link", accent: .tahoeAccentCyan) {
                        NSWorkspace.shared.open(URL(string: "https://github.com/DrogaBox/SMCAMDProcessor-personal")!)
                    }
                    TahoeButton(label: "Donate (PayPal)", icon: "heart.fill", accent: .tahoeAccentOrange) {
                        DispatchQueue.global(qos: .userInitiated).async {
                            if let url = Bundle.main.url(forResource: "bravo", withExtension: "mp3") {
                                if let sound = NSSound(contentsOf: url, byReference: true) {
                                    sound.play()
                                }
                            }
                        }
                        NSWorkspace.shared.open(URL(string: "https://www.paypal.com/donate/?business=mrleisures@gmail.com")!)
                    }
                }
            }
            .padding(18)
        }
    }
}


// MARK: - Menu Bar Popover View
struct MenuBarPopoverView: View {
    @ObservedObject var model: TelemetryModel = TelemetryModel.shared
    
    private var cfg: MenuBarConfig { MenuBarConfig.shared }

    private func formatSpeed(_ mbps: Double) -> String {
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

    var body: some View {
        VStack(spacing: 12) {
            // Header Section
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "cpu")
                        .foregroundColor(Color(red: 0.93, green: 0.11, blue: 0.14))
                        .font(.system(size: 13, weight: .bold))
                    Text("AMD Power Gadget")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
                Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "3.13.3")")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)

            // Dynamic Ordered Resource Widgets
            let rings = cfg.popoverRingOrder.split(separator: ",").map(String.init)
            
            // 1. Render Rings Row (Horizontal HStack) if any are style == 0
            let showRingsRow = rings.contains(where: { ring in
                if ring == "cpu" && cfg.popoverShowCPU && cfg.popoverCPUStyle == 0 { return true }
                if ring == "ram" && cfg.popoverShowRAM && cfg.popoverRAMStyle == 0 { return true }
                if ring == "disk" && cfg.popoverShowDisk && cfg.popoverDiskStyle == 0 { return true }
                if ring == "gpu" && cfg.popoverShowGPURing && cfg.popoverGPUStyle == 0 { return true }
                if ring == "vram" && cfg.popoverShowVRAM && cfg.popoverGPUStyle == 0 { return true }
                return false
            })
            
            if showRingsRow {
                Divider().background(Color.white.opacity(0.1))
                
                HStack(spacing: 14) {
                    ForEach(rings, id: \.self) { ring in
                        if ring == "cpu" && cfg.popoverShowCPU && cfg.popoverCPUStyle == 0 {
                            // CPU Ring
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.white.opacity(0.06), lineWidth: 4.5)
                                        .frame(width: 46, height: 46)
                                    Circle()
                                        .trim(from: 0, to: CGFloat(min(1.0, max(0.0, model.cpuLoadAvg / 100.0))))
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color(red: 0.93, green: 0.11, blue: 0.14), Color(red: 1.0, green: 0.4, blue: 0.4)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            style: StrokeStyle(lineWidth: 4.5, lineCap: .round)
                                        )
                                        .rotationEffect(Angle(degrees: -90))
                                        .frame(width: 46, height: 46)
                                    
                                    VStack(spacing: 0) {
                                        Text(String(format: "%.0f%%", model.cpuLoadAvg))
                                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                            .foregroundColor(.white)
                                        if cfg.popoverRingShowTemp {
                                            Text(String(format: "%.0f°", model.cpuTempC))
                                                .font(.system(size: 7.5, weight: .semibold))
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                    }
                                }
                                if cfg.popoverRingShowLabels {
                                    Text("CPU")
                                        .font(.system(size: 8.5, weight: .bold))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        } else if ring == "ram" && cfg.popoverShowRAM && cfg.popoverRAMStyle == 0 {
                            // RAM Ring
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.white.opacity(0.06), lineWidth: 4.5)
                                        .frame(width: 46, height: 46)
                                    Circle()
                                        .trim(from: 0, to: CGFloat(min(1.0, max(0.0, model.ramUsagePct / 100.0))))
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.orange, Color.yellow]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            style: StrokeStyle(lineWidth: 4.5, lineCap: .round)
                                        )
                                        .rotationEffect(Angle(degrees: -90))
                                        .frame(width: 46, height: 46)
                                    
                                    VStack(spacing: 0) {
                                        Text(String(format: "%.0f%%", model.ramUsagePct))
                                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                            .foregroundColor(.white)
                                        if cfg.popoverRingShowTemp {
                                            let usedGB = (model.ramUsagePct / 100.0) * (Double(ProcessInfo.processInfo.physicalMemory) / (1024.0 * 1024.0 * 1024.0))
                                            Text(String(format: "%.0fG", usedGB))
                                                .font(.system(size: 7.5, weight: .semibold))
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                    }
                                }
                                if cfg.popoverRingShowLabels {
                                    Text("RAM")
                                        .font(.system(size: 8.5, weight: .bold))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        } else if ring == "disk" && cfg.popoverShowDisk && cfg.popoverDiskStyle == 0 {
                            // Disk Ring
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.white.opacity(0.06), lineWidth: 4.5)
                                        .frame(width: 46, height: 46)
                                    Circle()
                                        .trim(from: 0, to: CGFloat(min(1.0, max(0.0, model.diskUsagePct / 100.0))))
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.blue, Color.cyan]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            style: StrokeStyle(lineWidth: 4.5, lineCap: .round)
                                        )
                                        .rotationEffect(Angle(degrees: -90))
                                        .frame(width: 46, height: 46)
                                    
                                    VStack(spacing: 0) {
                                        Text(String(format: "%.0f%%", model.diskUsagePct))
                                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                            .foregroundColor(.white)
                                        if cfg.popoverRingShowTemp {
                                            Text("SSD")
                                                .font(.system(size: 7.5, weight: .semibold))
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                    }
                                }
                                if cfg.popoverRingShowLabels {
                                    Text("DISK")
                                        .font(.system(size: 8.5, weight: .bold))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        } else if ring == "gpu" && cfg.popoverShowGPURing && cfg.popoverGPUStyle == 0 {
                            // GPU Ring
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.white.opacity(0.06), lineWidth: 4.5)
                                        .frame(width: 46, height: 46)
                                    Circle()
                                        .trim(from: 0, to: CGFloat(min(1.0, max(0.0, model.gpuLoadPct / 100.0))))
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.purple, Color(red: 0.5, green: 0.3, blue: 0.9)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            style: StrokeStyle(lineWidth: 4.5, lineCap: .round)
                                        )
                                        .rotationEffect(Angle(degrees: -90))
                                        .frame(width: 46, height: 46)
                                    
                                    VStack(spacing: 0) {
                                        Text(String(format: "%.0f%%", model.gpuLoadPct))
                                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                            .foregroundColor(.white)
                                        if cfg.popoverRingShowTemp {
                                            Text(String(format: "%.0f°", model.gpuTempC))
                                                .font(.system(size: 7.5, weight: .semibold))
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                    }
                                }
                                if cfg.popoverRingShowLabels {
                                    Text("GPU")
                                        .font(.system(size: 8.5, weight: .bold))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        } else if ring == "vram" && cfg.popoverShowVRAM && cfg.popoverGPUStyle == 0 {
                            // VRAM Ring
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.white.opacity(0.06), lineWidth: 4.5)
                                        .frame(width: 46, height: 46)
                                    let vramGB = model.gpuVramUsedBytes / (1024.0 * 1024.0 * 1024.0)
                                    let recommendedSize = MTLCreateSystemDefaultDevice()?.recommendedMaxWorkingSetSize
                                    let totalVramBytes = Double(recommendedSize ?? 17179869184)
                                    let totalVramGB = totalVramBytes / 1073741824.0
                                    let vramPct = (vramGB / totalVramGB) * 100.0
                                    Circle()
                                        .trim(from: 0, to: CGFloat(min(1.0, max(0.0, vramPct / 100.0))))
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.pink.opacity(0.8)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            style: StrokeStyle(lineWidth: 4.5, lineCap: .round)
                                        )
                                        .rotationEffect(Angle(degrees: -90))
                                        .frame(width: 46, height: 46)
                                    
                                    VStack(spacing: 0) {
                                        Text(String(format: "%.0f%%", vramPct))
                                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                            .foregroundColor(.white)
                                        if cfg.popoverRingShowTemp {
                                            Text(String(format: "%.0fG", vramGB))
                                                .font(.system(size: 7.5, weight: .semibold))
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                    }
                                }
                                if cfg.popoverRingShowLabels {
                                    Text("VRAM")
                                        .font(.system(size: 8.5, weight: .bold))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            
            // 2. Render Vertical List for Bars and Sparklines (style > 0)
            // 2. Render Vertical List for Bars and Sparklines (style > 0 or sparkline enabled)
            let showLinearOrGraphs = rings.contains(where: { ring in
                if ring == "cpu" && cfg.popoverShowCPU && (cfg.popoverCPUStyle == 1 || cfg.popoverShowCPUSparkline || cfg.popoverShowCores) { return true }
                if ring == "ram" && cfg.popoverShowRAM && cfg.popoverRAMStyle == 1 { return true }
                if ring == "disk" && cfg.popoverShowDisk && cfg.popoverDiskStyle == 1 { return true }
                if ring == "gpu" && cfg.popoverShowGPURing && (cfg.popoverGPUStyle == 1 || cfg.popoverShowGPUSparkline) { return true }
                if ring == "vram" && cfg.popoverShowVRAM && cfg.popoverGPUStyle == 1 { return true }
                return false
            })
            
            if showLinearOrGraphs {
                Divider().background(Color.white.opacity(0.1))
                
                VStack(spacing: 10) {
                    ForEach(rings, id: \.self) { ring in
                        if ring == "cpu" && cfg.popoverShowCPU {
                            if cfg.popoverCPUStyle == 1 {
                                let cpuTempStr = cfg.popoverRingShowTemp ? String(format: " • %.0f°C", model.cpuTempC) : ""
                                LinearProgressBar(
                                    label: "CPU",
                                    pct: model.cpuLoadAvg,
                                    detailText: String(format: "%.0f%%%@", model.cpuLoadAvg, cpuTempStr),
                                    color: Color(red: 0.93, green: 0.11, blue: 0.14)
                                )
                            }
                            if cfg.popoverShowCPUSparkline {
                                let cpuTempStr = cfg.popoverRingShowTemp ? String(format: " • %.0f°C", model.cpuTempC) : ""
                                MiniSparkline(
                                    label: "CPU Temp",
                                    currentVal: String(format: "%.0f°C", model.cpuTempC),
                                    color: Color(red: 0.93, green: 0.11, blue: 0.14),
                                    data: model.history,
                                    value: { $0.cpuTempC },
                                    filterZeros: true
                                )
                            }
                            if cfg.popoverShowCores {
                                PopoverCoreGridView(model: model)
                                    .padding(.top, 2)
                            }
                        } else if ring == "ram" && cfg.popoverShowRAM {
                            if cfg.popoverRAMStyle == 1 {
                                let usedGB = (model.ramUsagePct / 100.0) * (Double(ProcessInfo.processInfo.physicalMemory) / (1024.0 * 1024.0 * 1024.0))
                                let ramStr = cfg.popoverRingShowTemp ? String(format: " • %.1fG", usedGB) : ""
                                LinearProgressBar(
                                    label: "RAM",
                                    pct: model.ramUsagePct,
                                    detailText: String(format: "%.0f%%%@", model.ramUsagePct, ramStr),
                                    color: .orange
                                )
                            }
                        } else if ring == "disk" && cfg.popoverShowDisk {
                            if cfg.popoverDiskStyle == 1 {
                                let diskStr = cfg.popoverRingShowTemp ? " • SSD" : ""
                                LinearProgressBar(
                                    label: "DISK",
                                    pct: model.diskUsagePct,
                                    detailText: String(format: "%.0f%%%@", model.diskUsagePct, diskStr),
                                    color: .blue
                                )
                            }
                        } else if ring == "gpu" && cfg.popoverShowGPURing {
                            if cfg.popoverGPUStyle == 1 {
                                let gpuTempStr = cfg.popoverRingShowTemp ? String(format: " • %.0f°C", model.gpuTempC) : ""
                                LinearProgressBar(
                                    label: "GPU",
                                    pct: model.gpuLoadPct,
                                    detailText: String(format: "%.0f%%%@", model.gpuLoadPct, gpuTempStr),
                                    color: .purple
                                )
                            }
                            if cfg.popoverShowGPUSparkline {
                                MiniSparkline(
                                    label: "GPU Temp",
                                    currentVal: String(format: "%.0f°C", model.gpuTempC),
                                    color: .purple,
                                    data: model.history,
                                    value: { $0.gpuTempC },
                                    filterZeros: true
                                )
                                .padding(.top, 2)
                            }
                        } else if ring == "vram" && cfg.popoverShowVRAM {
                            if cfg.popoverGPUStyle == 1 {
                                let vramGB = model.gpuVramUsedBytes / (1024.0 * 1024.0 * 1024.0)
                                let recommendedSize = MTLCreateSystemDefaultDevice()?.recommendedMaxWorkingSetSize
                                let totalVramBytes = Double(recommendedSize ?? 17179869184)
                                let totalVramGB = totalVramBytes / 1073741824.0
                                let vramPct = (vramGB / totalVramGB) * 100.0
                                let vramStr = cfg.popoverRingShowTemp ? String(format: " • %.2fG", vramGB) : ""
                                LinearProgressBar(
                                    label: "VRAM",
                                    pct: vramPct,
                                    detailText: String(format: "%.0f%%%@", vramPct, vramStr),
                                    color: .purple.opacity(0.8)
                                )
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            // GPU & Network Stats
            if cfg.popoverShowGPU || cfg.popoverShowNetwork {
                Divider().background(Color.white.opacity(0.1))
                
                VStack(alignment: .leading, spacing: 6) {
                    if cfg.popoverShowGPU {
                        // GPU Row
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 10))
                                    .foregroundColor(.purple)
                                    .frame(width: 14)
                                Text(model.sysInfo.gpuModel.isEmpty || model.sysInfo.gpuModel == "Unknown" ? "Radeon GPU" : model.sysInfo.gpuModel)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                Spacer()
                                if model.gpuTempC > 0 {
                                    Text(String(format: "%.0f°C • %.0fW", model.gpuTempC, model.gpuPowerW))
                                        .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.85))
                                } else {
                                    Text("Inactive")
                                        .font(.system(size: 9.5, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.4))
                                }
                            }
                            if model.gpuTempC > 0 {
                                HStack {
                                    Spacer()
                                    let vramGB = model.gpuVramUsedBytes / (1024.0 * 1024.0 * 1024.0)
                                    let fanRPMStr = model.gpuFanRPM > 0 ? String(format: " • %.0f RPM", model.gpuFanRPM) : ""
                                    Text(String(format: "VRAM: %.2fG%@", vramGB, fanRPMStr))
                                        .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                    }

                    if cfg.popoverShowNetwork {
                        // Network Row
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 9))
                                .foregroundColor(.green)
                                .frame(width: 14)
                            Text("Network")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                            Spacer()
                            Text("↓ \(formatSpeed(model.netDownloadMBps))  ↑ \(formatSpeed(model.netUploadMBps))")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        if cfg.popoverShowNetSparkline {
                            MiniSparkline(
                                label: "Net Speed",
                                currentVal: formatSpeed(model.netDownloadMBps + model.netUploadMBps),
                                color: .green,
                                data: model.history,
                                value: { $0.netDownloadMBps + $0.netUploadMBps }
                            )
                            .padding(.top, 2)
                        }
                    }
                }
                .padding(.horizontal, 12)
            }

            // Top Processes List
            if cfg.popoverShowProcesses {
                Divider().background(Color.white.opacity(0.1))
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Top Processes")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                        Spacer()
                        Image(systemName: "list.bullet")
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(.bottom, 2)

                    if model.topProcesses.isEmpty {
                        HStack {
                            Spacer()
                            Text("Loading...")
                                .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.4))
                                .padding(.vertical, 4)
                            Spacer()
                        }
                    } else {
                        ForEach(model.topProcesses) { proc in
                            HStack {
                                Text(proc.name)
                                    .font(.system(size: 9.5, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.85))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                Spacer()
                                Text(String(format: "%.1f%%", proc.cpuUsage))
                                    .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                                    .foregroundColor(proc.cpuUsage > 50 ? Color(red: 0.93, green: 0.11, blue: 0.14) : .white.opacity(0.7))
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .frame(height: 95)
            }

            Divider().background(Color.white.opacity(0.1))

            // Action Buttons
            HStack(spacing: 8) {
                Button(action: {
                    NSApp.activate(ignoringOtherApps: true)
                    ViewController.launch(forceFocus: true)
                    NotificationCenter.default.post(name: .init("CloseMenuBarPopover"), object: nil)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.system(size: 9.5))
                        Text("Open Dashboard")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(5)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                    exit(0)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "power")
                            .font(.system(size: 9.5))
                        Text("Quit")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(Color(red: 0.93, green: 0.11, blue: 0.14))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(Color(red: 0.93, green: 0.11, blue: 0.14).opacity(0.08))
                    .cornerRadius(5)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(minWidth: 240, maxWidth: 340)
        .background(Color.clear)
    }
}

// MARK: - Popover Config Tab
struct PopoverConfigView: View {
    @ObservedObject var model: TelemetryModel
    @State private var cfg = MenuBarConfig.shared
    @State private var items: [RingOrderItem] = []

    struct RingOrderItem: Identifiable, Equatable {
        let id: String
        let name: String
        let color: Color
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle("Popover General Settings")
                Text("Customize the behavior and visibility of the menu bar popover.")
                    .font(.system(size: 12)).foregroundColor(.tahoeSubtext)

                ToggleRow(label: "Enable Popover Menu", detail: "Left-click shows interactive popover instead of classic menu", isOn: .init(
                    get: { cfg.enablePopover }, set: { cfg.enablePopover = $0; notify(widthChanged: false) }
                ), accent: .tahoeAccentCyan) { _ in }

                if cfg.enablePopover {
                    Divider().background(Color.tahoeCardBorder)
                    
                    SectionTitle("Widget Reordering")
                    Text("Arrange the order in which resource widgets appear. Click arrows to swap position.")
                        .font(.system(size: 12)).foregroundColor(.tahoeSubtext)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(items) { item in
                            let index = items.firstIndex(where: { $0.id == item.id }) ?? 0
                            HStack {
                                Circle().fill(item.color).frame(width: 8, height: 8)
                                Text(item.name)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.tahoeText)
                                Spacer()
                                Button(action: { moveUp(index: index) }) {
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .disabled(index == 0)
                                .buttonStyle(PlainButtonStyle())
                                .foregroundColor(index == 0 ? .gray.opacity(0.3) : .tahoeAccentCyan)
                                .frame(width: 24, height: 24)
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(4)
                                
                                Button(action: { moveDown(index: index) }) {
                                    Image(systemName: "arrow.down")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .disabled(index == items.count - 1)
                                .buttonStyle(PlainButtonStyle())
                                .foregroundColor(index == items.count - 1 ? .gray.opacity(0.3) : .tahoeAccentCyan)
                                .frame(width: 24, height: 24)
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(4)
                            }
                            .padding(.vertical, 6).padding(.horizontal, 12)
                            .background(Color.tahoeCard)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.tahoeCardBorder))
                            .cornerRadius(8)
                        }
                    }

                    Divider().background(Color.tahoeCardBorder)

                    SectionTitle("Widget Selection & Display Style")
                    Text("Select which metrics are shown and choose their visualization style.")
                        .font(.system(size: 12)).foregroundColor(.tahoeSubtext)

                    VStack(spacing: 12) {
                        // CPU style selection
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Toggle("", isOn: .init(
                                    get: { cfg.popoverShowCPU },
                                    set: { cfg.popoverShowCPU = $0; notify(widthChanged: false) }
                                ))
                                .labelsHidden()
                                Text("CPU Tracker")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.tahoeText)
                                Spacer()
                                if cfg.popoverShowCPU {
                                    Picker("Style", selection: .init(
                                        get: { cfg.popoverCPUStyle },
                                        set: { cfg.popoverCPUStyle = $0; notify(widthChanged: false) }
                                    )) {
                                        Text("Circular Ring").tag(0)
                                        Text("Progress Bar").tag(1)
                                    }
                                    .pickerStyle(.menu)
                                    .frame(width: 140)
                                }
                            }
                            Text("Tracks CPU utilization average and core temperature.")
                                .font(.system(size: 11))
                                .foregroundColor(.tahoeSubtext)
                            if cfg.popoverShowCPU {
                                Divider().background(Color.white.opacity(0.1)).padding(.vertical, 2)
                                VStack(alignment: .leading, spacing: 6) {
                                    Toggle(isOn: .init(
                                        get: { cfg.popoverShowCPUSparkline },
                                        set: { cfg.popoverShowCPUSparkline = $0; notify(widthChanged: false) }
                                    )) {
                                        Text("Show Temperature Sparkline Graph below")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.tahoeText)
                                    }
                                    .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentCyan))
                                    
                                    Toggle(isOn: .init(
                                        get: { cfg.popoverShowCores },
                                        set: { cfg.popoverShowCores = $0; notify(widthChanged: false) }
                                    )) {
                                        Text("Show Per-Core Utilization Grid below")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.tahoeText)
                                    }
                                    .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentCyan))
                                }
                            }
                        }
                        .padding(12)
                        .background(Color.tahoeCard)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.tahoeCardBorder))

                        // RAM style selection
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Toggle("", isOn: .init(
                                    get: { cfg.popoverShowRAM },
                                    set: { cfg.popoverShowRAM = $0; notify(widthChanged: false) }
                                ))
                                .labelsHidden()
                                Text("RAM Tracker")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.tahoeText)
                                Spacer()
                                if cfg.popoverShowRAM {
                                    Picker("Style", selection: .init(
                                        get: { cfg.popoverRAMStyle },
                                        set: { cfg.popoverRAMStyle = $0; notify(widthChanged: false) }
                                    )) {
                                        Text("Circular Ring").tag(0)
                                        Text("Progress Bar").tag(1)
                                    }
                                    .pickerStyle(.menu)
                                    .frame(width: 140)
                                }
                            }
                            Text("Tracks active memory usage and pressure.")
                                .font(.system(size: 11))
                                .foregroundColor(.tahoeSubtext)
                        }
                        .padding(12)
                        .background(Color.tahoeCard)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.tahoeCardBorder))

                        // Disk style selection
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Toggle("", isOn: .init(
                                    get: { cfg.popoverShowDisk },
                                    set: { cfg.popoverShowDisk = $0; notify(widthChanged: false) }
                                ))
                                .labelsHidden()
                                Text("Disk Tracker")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.tahoeText)
                                Spacer()
                                if cfg.popoverShowDisk {
                                    Picker("Style", selection: .init(
                                        get: { cfg.popoverDiskStyle },
                                        set: { cfg.popoverDiskStyle = $0; notify(widthChanged: false) }
                                    )) {
                                        Text("Circular Ring").tag(0)
                                        Text("Progress Bar").tag(1)
                                    }
                                    .pickerStyle(.menu)
                                    .frame(width: 140)
                                }
                            }
                            Text("Tracks primary storage capacity usage.")
                                .font(.system(size: 11))
                                .foregroundColor(.tahoeSubtext)
                        }
                        .padding(12)
                        .background(Color.tahoeCard)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.tahoeCardBorder))

                        // GPU style selection
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Toggle("", isOn: .init(
                                    get: { cfg.popoverShowGPURing },
                                    set: { cfg.popoverShowGPURing = $0; notify(widthChanged: false) }
                                ))
                                .labelsHidden()
                                Text("GPU Tracker")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.tahoeText)
                                Spacer()
                                if cfg.popoverShowGPURing {
                                    Picker("Style", selection: .init(
                                        get: { cfg.popoverGPUStyle },
                                        set: { cfg.popoverGPUStyle = $0; notify(widthChanged: false) }
                                    )) {
                                        Text("Circular Ring").tag(0)
                                        Text("Progress Bar").tag(1)
                                    }
                                    .pickerStyle(.menu)
                                    .frame(width: 140)
                                }
                            }
                            Text("Tracks graphics utilization and temperature.")
                                .font(.system(size: 11))
                                .foregroundColor(.tahoeSubtext)
                            if cfg.popoverShowGPURing {
                                Divider().background(Color.white.opacity(0.1)).padding(.vertical, 2)
                                Toggle(isOn: .init(
                                    get: { cfg.popoverShowGPUSparkline },
                                    set: { cfg.popoverShowGPUSparkline = $0; notify(widthChanged: false) }
                                )) {
                                    Text("Show Temperature Sparkline Graph below")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.tahoeText)
                                }
                                .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentPurple))
                            }
                        }
                        .padding(12)
                        .background(Color.tahoeCard)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.tahoeCardBorder))

                        // VRAM style selection
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Toggle("", isOn: .init(
                                    get: { cfg.popoverShowVRAM },
                                    set: { cfg.popoverShowVRAM = $0; notify(widthChanged: false) }
                                ))
                                .labelsHidden()
                                Text("VRAM Tracker")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.tahoeText)
                                Spacer()
                                if cfg.popoverShowVRAM {
                                    Picker("Style", selection: .init(
                                        get: { cfg.popoverGPUStyle },
                                        set: { cfg.popoverGPUStyle = $0; notify(widthChanged: false) }
                                    )) {
                                        Text("Circular Ring").tag(0)
                                        Text("Progress Bar").tag(1)
                                    }
                                    .pickerStyle(.menu)
                                    .frame(width: 140)
                                }
                            }
                            Text("Tracks graphics memory (VRAM) utilization.")
                                .font(.system(size: 11))
                                .foregroundColor(.tahoeSubtext)
                        }
                        .padding(12)
                        .background(Color.tahoeCard)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.tahoeCardBorder))
                    }

                    Divider().background(Color.tahoeCardBorder)

                    SectionTitle("Style Options")
                    Text("Configure labels and layout details for widgets inside the popover.")
                        .font(.system(size: 12)).foregroundColor(.tahoeSubtext)

                    ToggleRow(label: "Show Ring Labels", detail: "Display text labels below rings (CPU, RAM, etc.)", isOn: .init(
                        get: { cfg.popoverRingShowLabels }, set: { cfg.popoverRingShowLabels = $0; notify(widthChanged: false) }
                    ), accent: .tahoeAccentCyan) { _ in }

                    ToggleRow(label: "Show Ring Details", detail: "Display temperatures/GB usage inside rings", isOn: .init(
                        get: { cfg.popoverRingShowTemp }, set: { cfg.popoverRingShowTemp = $0; notify(widthChanged: false) }
                    ), accent: .tahoeAccentOrange) { _ in }

                    Divider().background(Color.tahoeCardBorder)

                    SectionTitle("Other Popover Widgets")
                    Text("Enable additional stats columns inside the popover.")
                        .font(.system(size: 12)).foregroundColor(.tahoeSubtext)

                    ToggleRow(label: "Show GPU Row", detail: "Display detailed text row with GPU model, temp, and power", isOn: .init(
                        get: { cfg.popoverShowGPU }, set: { cfg.popoverShowGPU = $0; notify(widthChanged: false) }
                    ), accent: .tahoeAccentPurple) { _ in }

                    ToggleRow(label: "Show Network Row", detail: "Display live upload/download speed stats", isOn: .init(
                        get: { cfg.popoverShowNetwork }, set: { cfg.popoverShowNetwork = $0; notify(widthChanged: false) }
                    ), accent: .tahoeAccentGreen) { _ in }

                    if cfg.popoverShowNetwork {
                        Toggle(isOn: .init(
                            get: { cfg.popoverShowNetSparkline },
                            set: { cfg.popoverShowNetSparkline = $0; notify(widthChanged: false) }
                        )) {
                            Text("Show Network Speed Sparkline Graph below")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.tahoeText)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentGreen))
                        .padding(.leading, 12).padding(.bottom, 6)
                    }

                    ToggleRow(label: "Show Top Processes", detail: "Display top 5 CPU-intensive processes list", isOn: .init(
                        get: { cfg.popoverShowProcesses }, set: { cfg.popoverShowProcesses = $0; notify(widthChanged: false) }
                    ), accent: .tahoeAccentRed) { _ in }
                }
            }
            .padding(18)
        }
        .onAppear {
            loadOrder()
        }
    }

    private func loadOrder() {
        let orderStr = cfg.popoverRingOrder
        let keys = orderStr.split(separator: ",").map(String.init)
        
        var loadedItems: [RingOrderItem] = []
        for key in keys {
            if key == "cpu" { loadedItems.append(RingOrderItem(id: "cpu", name: "CPU Tracker", color: .tahoeAccentCyan)) }
            if key == "ram" { loadedItems.append(RingOrderItem(id: "ram", name: "RAM Tracker", color: .tahoeAccentOrange)) }
            if key == "disk" { loadedItems.append(RingOrderItem(id: "disk", name: "Disk Tracker", color: .tahoeAccentBlue)) }
            if key == "gpu" { loadedItems.append(RingOrderItem(id: "gpu", name: "GPU Tracker", color: .tahoeAccentPurple)) }
            if key == "vram" { loadedItems.append(RingOrderItem(id: "vram", name: "VRAM Tracker", color: .tahoeAccentPurple.opacity(0.8))) }
        }
        
        let allKeys = ["cpu", "ram", "gpu", "vram", "disk"]
        for key in allKeys {
            if !loadedItems.contains(where: { $0.id == key }) {
                if key == "cpu" { loadedItems.append(RingOrderItem(id: "cpu", name: "CPU Tracker", color: .tahoeAccentCyan)) }
                if key == "ram" { loadedItems.append(RingOrderItem(id: "ram", name: "RAM Tracker", color: .tahoeAccentOrange)) }
                if key == "gpu" { loadedItems.append(RingOrderItem(id: "gpu", name: "GPU Tracker", color: .tahoeAccentPurple)) }
                if key == "vram" { loadedItems.append(RingOrderItem(id: "vram", name: "VRAM Tracker", color: .tahoeAccentPurple.opacity(0.8))) }
                if key == "disk" { loadedItems.append(RingOrderItem(id: "disk", name: "Disk Tracker", color: .tahoeAccentBlue)) }
            }
        }
        self.items = loadedItems
    }

    private func saveOrder() {
        let orderStr = items.map { $0.id }.joined(separator: ",")
        cfg.popoverRingOrder = orderStr
        notify(widthChanged: false)
    }

    private func moveUp(index: Int) {
        guard index > 0 else { return }
        items.swapAt(index, index - 1)
        saveOrder()
    }

    private func moveDown(index: Int) {
        guard index < items.count - 1 else { return }
        items.swapAt(index, index + 1)
        saveOrder()
    }

    private func notify(widthChanged: Bool = true) {
        cfg = MenuBarConfig()
        NotificationCenter.default.post(name: .init("MenuBarConfigChanged"), object: nil)
    }
}

// MARK: - Popover CPU Per-Core Thread Load Grid Widget
struct PopoverCoreGridView: View {
    @ObservedObject var model: TelemetryModel
    
    private var columns: [GridItem] {
        let count = model.cores.count
        let colCount = count > 16 ? 8 : (count > 8 ? 6 : 4)
        return Array(repeating: GridItem(.flexible(), spacing: 4), count: colCount)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CPU Per-Core Thread Load")
                .font(.system(size: 9.5, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(model.cores) { core in
                    GeometryReader { geo in
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 3.5)
                                .fill(Color.black.opacity(0.25))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3.5)
                                        .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                                )
                            
                            // Fill
                            RoundedRectangle(cornerRadius: 3.5)
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color.cyan.opacity(0.8), Color.purple.opacity(0.9)]),
                                    startPoint: .bottom,
                                    endPoint: .top
                                ))
                                .frame(height: geo.size.height * CGFloat(core.loadPct / 100.0))
                            
                            // Labels
                            VStack(spacing: 0) {
                                HStack {
                                    Text("\(core.id)")
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundColor(.white.opacity(0.35))
                                        .padding(.leading, 3)
                                        .padding(.top, 1)
                                    Spacer()
                                }
                                Spacer()
                                Text(String(format: "%.0f%%", core.loadPct))
                                    .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(.bottom, 1.5)
                            }
                        }
                    }
                    .frame(height: 24)
                }
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.03))
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.06), lineWidth: 0.5))
    }
}

// MARK: - Popover Linear Progress Bar Widget
struct LinearProgressBar: View {
    let label: String
    let pct: Double
    let detailText: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                Text(detailText)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(min(1.0, max(0.0, pct / 100.0))), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 12)
    }
}

// MARK: - Popover Mini Sparkline Widget
struct SparklineShape: Shape {
    let values: [Double]
    let minVal: Double
    let maxVal: Double
    var isFilled: Bool = false
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard values.count > 1 else { return path }
        
        let range = max(0.001, maxVal - minVal)
        let stepX = rect.width / CGFloat(values.count - 1)
        
        let points = values.enumerated().map { i, val in
            let normY = CGFloat((val - minVal) / range)
            let clampedY = max(0.0, min(1.0, normY))
            let y = rect.height * (1.0 - clampedY)
            let x = CGFloat(i) * stepX
            return CGPoint(x: x, y: y)
        }
        
        path.move(to: points[0])
        for pt in points.dropFirst() {
            path.addLine(to: pt)
        }
        
        if isFilled, let last = points.last {
            path.addLine(to: CGPoint(x: last.x, y: rect.height))
            path.addLine(to: CGPoint(x: points[0].x, y: rect.height))
            path.closeSubpath()
        }
        
        return path
    }
}

struct MiniSparkline: View {
    let label: String
    let currentVal: String
    let color: Color
    let data: [TelemetryPoint]
    let value: (TelemetryPoint) -> Double
    var filterZeros: Bool = false
    
    var body: some View {
        let rawVals = data.map(value)
        let vals = filterZeros ? rawVals.filter { $0 > 0 } : rawVals
        
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                Text(currentVal)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .frame(width: 75, alignment: .leading)
            
            if vals.count > 1 {
                let mn = vals.min() ?? 0
                let mx = vals.max() ?? 100
                let diff = mx - mn
                let span = max(10.0, diff)
                let center = (mx + mn) / 2.0
                let yMin = center - span * 0.6
                let yMax = center + span * 0.6
                
                ZStack {
                    SparklineShape(values: vals, minVal: yMin, maxVal: yMax, isFilled: true)
                        .fill(LinearGradient(colors: [color.opacity(0.22), color.opacity(0.0)], startPoint: .top, endPoint: .bottom))
                    
                    SparklineShape(values: vals, minVal: yMin, maxVal: yMax, isFilled: false)
                        .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                }
                .frame(height: 24)
                .clipped()
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.03))
                    .frame(height: 24)
                    .overlay(Text("Loading...").font(.system(size: 8)).foregroundColor(.white.opacity(0.3)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}

// MARK: - Analysis e Historial

import Combine
import Charts

struct HistoryDataPoint: Codable, Identifiable {
    var id: UUID = UUID()
    let timestamp: Date
    let cpuLoad: Double
    let cpuTemp: Double
    let ramUsage: Double
    let gpuTemp: Double
    let gpuLoad: Double
    var cpuWatts: Double? = nil
    var cpuFreqAvg: Double? = nil
    
    var safeCpuWatts: Double { cpuWatts ?? 0.0 }
    var safeCpuFreqAvg: Double { cpuFreqAvg ?? 0.0 }
}

class HistoryManager: ObservableObject {
    static let shared = HistoryManager()
    
    @Published var historyData: [HistoryDataPoint] = []
    
    private let saveURL: URL
    private var timer: Timer?
    
    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("AMD Power Gadget")
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        saveURL = appDir.appendingPathComponent("telemetry_history.json")
        
        loadData()
        startSampling()
    }
    
    private func loadData() {
        guard let data = try? Data(contentsOf: saveURL) else { return }
        do {
            let decoder = JSONDecoder()
            historyData = try decoder.decode([HistoryDataPoint].self, from: data)
            pruneOldData()
        } catch {
            print("Failed to decode history: \(error)")
        }
    }
    
    func saveData() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(historyData)
            try data.write(to: saveURL, options: .atomic)
        } catch {
            print("Failed to encode history: \(error)")
        }
    }
    
    private func pruneOldData() {
        // Keep data for 30 days
        let cutoff = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        historyData.removeAll(where: { $0.timestamp < cutoff })
    }
    
    private func startSampling() {
        // Sample every 60 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.sampleCurrentTelemetry()
        }
    }
    
    func sampleCurrentTelemetry() {
        DispatchQueue.main.async {
            let model = TelemetryModel.shared
            let point = HistoryDataPoint(
                timestamp: Date(),
                cpuLoad: model.cpuLoadAvg,
                cpuTemp: model.cpuTempC,
                ramUsage: model.ramUsagePct,
                gpuTemp: model.gpuTempC,
                gpuLoad: model.gpuLoadPct,
                cpuWatts: model.cpuWatts,
                cpuFreqAvg: model.cpuFreqAvgGHz
            )
            
            self.historyData.append(point)
            self.pruneOldData()
            self.saveData()
        }
    }
    
    nonisolated static func performDownsample(data: [HistoryDataPoint], hours: Int) -> [HistoryDataPoint] {
        let cutoff = Date().addingTimeInterval(Double(-hours * 60 * 60))
        let filtered = data.filter { $0.timestamp >= cutoff }
        
        if hours <= 24 || filtered.isEmpty {
            return filtered
        }
        
        var downsampled: [HistoryDataPoint] = []
        var bucketStart = filtered[0].timestamp
        var sumLoad: Double = 0
        var sumTemp: Double = 0
        var sumRam: Double = 0
        var sumGpuTemp: Double = 0
        var sumGpuLoad: Double = 0
        var sumWatts: Double = 0
        var sumFreq: Double = 0
        var wattsCount: Int = 0
        var freqCount: Int = 0
        var count: Int = 0
        
        for point in filtered {
            if point.timestamp.timeIntervalSince(bucketStart) >= 3600 {
                if count > 0 {
                    downsampled.append(HistoryDataPoint(
                        timestamp: bucketStart.addingTimeInterval(1800),
                        cpuLoad: sumLoad / Double(count),
                        cpuTemp: sumTemp / Double(count),
                        ramUsage: sumRam / Double(count),
                        gpuTemp: sumGpuTemp / Double(count),
                        gpuLoad: sumGpuLoad / Double(count),
                        cpuWatts: wattsCount > 0 ? sumWatts / Double(wattsCount) : nil,
                        cpuFreqAvg: freqCount > 0 ? sumFreq / Double(freqCount) : nil
                    ))
                }
                bucketStart = point.timestamp
                sumLoad = 0; sumTemp = 0; sumRam = 0; sumGpuTemp = 0; sumGpuLoad = 0; sumWatts = 0; sumFreq = 0
                count = 0; wattsCount = 0; freqCount = 0
            }
            
            sumLoad += point.cpuLoad
            sumTemp += point.cpuTemp
            sumRam += point.ramUsage
            sumGpuTemp += point.gpuTemp
            sumGpuLoad += point.gpuLoad
            if let w = point.cpuWatts { sumWatts += w; wattsCount += 1 }
            if let f = point.cpuFreqAvg { sumFreq += f; freqCount += 1 }
            count += 1
        }
        
        if count > 0 {
            downsampled.append(HistoryDataPoint(
                timestamp: bucketStart.addingTimeInterval(1800),
                cpuLoad: sumLoad / Double(count),
                cpuTemp: sumTemp / Double(count),
                ramUsage: sumRam / Double(count),
                gpuTemp: sumGpuTemp / Double(count),
                gpuLoad: sumGpuLoad / Double(count),
                cpuWatts: wattsCount > 0 ? sumWatts / Double(wattsCount) : nil,
                cpuFreqAvg: freqCount > 0 ? sumFreq / Double(freqCount) : nil
            ))
        }
        
        return downsampled
    }
    
    func downsampledData(for hours: Int) -> [HistoryDataPoint] {
        return Self.performDownsample(data: historyData, hours: hours)
    }
}

struct AnalysisContentView: View {
    @ObservedObject var historyManager = HistoryManager.shared
    @State private var selectedTimeframe: Int = 1 // Hours
    @State private var displayData: [HistoryDataPoint] = []
    @State private var isLoadingData: Bool = false
    @AppStorage("analysis_show_cpuload") private var showCpuLoad: Bool = true
    @AppStorage("analysis_show_thermals") private var showThermals: Bool = true
    @AppStorage("analysis_show_ram") private var showRam: Bool = true
    @AppStorage("analysis_show_gpuload") private var showGpuLoad: Bool = true
    @AppStorage("analysis_show_cpuwatts") private var showCpuWatts: Bool = true
    @AppStorage("analysis_show_cpufreq") private var showCpuFreq: Bool = true

    private func loadChartData() {
        isLoadingData = true
        let tf = selectedTimeframe
        let rawData = historyManager.historyData
        Task.detached(priority: .userInitiated) {
            let pts = HistoryManager.performDownsample(data: rawData, hours: tf)
            await MainActor.run {
                self.displayData = pts
                self.isLoadingData = false
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header & Filters
            HStack {
                SectionTitle("Histórico y Tendencias")
                Spacer()
                Picker("Timeframe", selection: $selectedTimeframe) {
                    Text("1h").tag(1)
                    Text("24h").tag(24)
                    Text("7d").tag(24 * 7)
                    Text("30d").tag(24 * 30)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 250)
                .onChange(of: selectedTimeframe) { _ in
                    loadChartData()
                }
            }
            .padding(.horizontal)

            // Dynamic Chart Selectors / Toggles
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    Text("Gráficas visibles:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.tahoeSubtext)
                    
                    Button(action: { showCpuLoad.toggle() }) {
                        HStack(spacing: 6) {
                            Image(systemName: showCpuLoad ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(showCpuLoad ? Color.tahoeAccentCyan : .tahoeSubtext)
                            Text("Carga CPU")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(showCpuLoad ? .white : .tahoeSubtext)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(showCpuLoad ? Color.tahoeAccentCyan.opacity(0.15) : Color.white.opacity(0.03))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(showCpuLoad ? Color.tahoeAccentCyan.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { showThermals.toggle() }) {
                        HStack(spacing: 6) {
                            Image(systemName: showThermals ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(showThermals ? Color.tahoeAccentRed : .tahoeSubtext)
                            Text("Temperaturas")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(showThermals ? .white : .tahoeSubtext)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(showThermals ? Color.tahoeAccentRed.opacity(0.15) : Color.white.opacity(0.03))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(showThermals ? Color.tahoeAccentRed.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { showRam.toggle() }) {
                        HStack(spacing: 6) {
                            Image(systemName: showRam ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(showRam ? Color.tahoeAccentGreen : .tahoeSubtext)
                            Text("Uso RAM")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(showRam ? .white : .tahoeSubtext)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(showRam ? Color.tahoeAccentGreen.opacity(0.15) : Color.white.opacity(0.03))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(showRam ? Color.tahoeAccentGreen.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { showGpuLoad.toggle() }) {
                        HStack(spacing: 6) {
                            Image(systemName: showGpuLoad ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(showGpuLoad ? Color.tahoeAccentPurple : .tahoeSubtext)
                            Text("Carga GPU")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(showGpuLoad ? .white : .tahoeSubtext)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(showGpuLoad ? Color.tahoeAccentPurple.opacity(0.15) : Color.white.opacity(0.03))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(showGpuLoad ? Color.tahoeAccentPurple.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { showCpuWatts.toggle() }) {
                        HStack(spacing: 6) {
                            Image(systemName: showCpuWatts ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(showCpuWatts ? Color.tahoeAccentOrange : .tahoeSubtext)
                            Text("Potencia CPU")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(showCpuWatts ? .white : .tahoeSubtext)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(showCpuWatts ? Color.tahoeAccentOrange.opacity(0.15) : Color.white.opacity(0.03))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(showCpuWatts ? Color.tahoeAccentOrange.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { showCpuFreq.toggle() }) {
                        HStack(spacing: 6) {
                            Image(systemName: showCpuFreq ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(showCpuFreq ? Color.tahoeAccentCyan : .tahoeSubtext)
                            Text("Frecuencia CPU")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(showCpuFreq ? .white : .tahoeSubtext)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(showCpuFreq ? Color.tahoeAccentCyan.opacity(0.15) : Color.white.opacity(0.03))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(showCpuFreq ? Color.tahoeAccentCyan.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal)
            }
            
            ScrollView {
                VStack(spacing: 20) {
                    let data = displayData
                    
                    if isLoadingData {
                        VStack {
                            Spacer(minLength: 80)
                            ProgressView()
                                .scaleEffect(0.9)
                            Text("Cargando tendencias de telemetría...")
                                .font(.system(size: 11))
                                .foregroundColor(Color.tahoeSubtext)
                                .padding(.top, 6)
                            Spacer()
                        }
                    } else if data.isEmpty {
                        VStack {
                            Spacer(minLength: 100)
                            Text("No hay suficientes datos recolectados aún.")
                               .foregroundColor(Color.tahoeSubtext)
                            Text("AMD Power Gadget recolecta datos automáticamente cada minuto.")
                                .font(.system(size: 11))
                                .foregroundColor(Color.tahoeSubtext.opacity(0.7))
                            Spacer()
                        }
                    } else if !showCpuLoad && !showThermals && !showRam && !showGpuLoad && !showCpuWatts && !showCpuFreq {
                        VStack {
                            Spacer(minLength: 80)
                            Text("Todas las gráficas están ocultas.")
                                .foregroundColor(Color.tahoeSubtext)
                            Text("Seleccioná una gráfica en el panel superior para visualizar su histórico.")
                                .font(.system(size: 11))
                                .foregroundColor(Color.tahoeSubtext.opacity(0.7))
                            Spacer()
                        }
                    } else {
                        // CPU Load Chart
                        if showCpuLoad {
                            HistoryCard(title: "CPU Load", subtitle: "Average utilization over time", accent: Color.tahoeAccentCyan) {
                                if #available(macOS 13.0, *) {
                                    Chart(data) { point in
                                        LineMark(
                                            x: .value("Time", point.timestamp),
                                            y: .value("Load %", point.cpuLoad)
                                        )
                                        .foregroundStyle(Color.tahoeAccentCyan)
                                        
                                        AreaMark(
                                            x: .value("Time", point.timestamp),
                                            y: .value("Load %", point.cpuLoad)
                                        )
                                        .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color.tahoeAccentCyan.opacity(0.3), Color.clear]), startPoint: .top, endPoint: .bottom))
                                    }
                                    .chartYScale(domain: 0...100)
                                    .frame(height: 150)
                                } else {
                                    Text("Charts require macOS 13.0+")
                                }
                            }
                        }
                        
                        // Temperatures Chart (CPU & GPU)
                        if showThermals {
                            HistoryCard(title: "Thermal History", subtitle: "CPU and GPU temperatures", accent: Color.tahoeAccentRed) {
                                if #available(macOS 13.0, *) {
                                    Chart(data) { point in
                                        LineMark(
                                            x: .value("Time", point.timestamp),
                                            y: .value("Temperature", point.cpuTemp)
                                        )
                                        .interpolationMethod(.catmullRom)
                                        .foregroundStyle(by: .value("Series", "CPU Temp"))
                                        
                                        LineMark(
                                            x: .value("Time", point.timestamp),
                                            y: .value("Temperature", point.gpuTemp)
                                        )
                                        .interpolationMethod(.catmullRom)
                                        .foregroundStyle(by: .value("Series", "GPU Temp"))
                                    }
                                    .chartForegroundStyleScale([
                                        "CPU Temp": Color.tahoeAccentOrange,
                                        "GPU Temp": Color.tahoeAccentPurple
                                    ])
                                    .chartYScale(domain: 20...110)
                                    .frame(height: 150)
                                } else {
                                    Text("Charts require macOS 13.0+")
                                }
                            }
                        }
                        
                        // RAM Usage Chart
                        if showRam {
                            HistoryCard(title: "Memory Usage", subtitle: "RAM utilization percentage", accent: Color.tahoeAccentGreen) {
                                if #available(macOS 13.0, *) {
                                    Chart(data) { point in
                                        LineMark(
                                            x: .value("Time", point.timestamp),
                                            y: .value("RAM %", point.ramUsage)
                                        )
                                        .foregroundStyle(Color.tahoeAccentGreen)
                                        
                                        AreaMark(
                                            x: .value("Time", point.timestamp),
                                            y: .value("RAM %", point.ramUsage)
                                        )
                                        .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color.tahoeAccentGreen.opacity(0.3), Color.clear]), startPoint: .top, endPoint: .bottom))
                                    }
                                    .chartYScale(domain: 0...100)
                                    .frame(height: 150)
                                } else {
                                    Text("Charts require macOS 13.0+")
                                }
                            }
                        }

                        // GPU Load Chart
                        if showGpuLoad {
                            HistoryCard(title: "GPU Load", subtitle: "Radeon Graphics utilization percentage", accent: Color.tahoeAccentPurple) {
                                if #available(macOS 13.0, *) {
                                    Chart(data) { point in
                                        LineMark(
                                            x: .value("Time", point.timestamp),
                                            y: .value("GPU %", point.gpuLoad)
                                        )
                                        .foregroundStyle(Color.tahoeAccentPurple)
                                        
                                        AreaMark(
                                            x: .value("Time", point.timestamp),
                                            y: .value("GPU %", point.gpuLoad)
                                        )
                                        .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color.tahoeAccentPurple.opacity(0.3), Color.clear]), startPoint: .top, endPoint: .bottom))
                                    }
                                    .chartYScale(domain: 0...100)
                                    .frame(height: 150)
                                } else {
                                    Text("Charts require macOS 13.0+")
                                }
                            }
                        }

                        // CPU Power Chart (Watts)
                        if showCpuWatts {
                            HistoryCard(title: "CPU Package Power", subtitle: "Real-time energy consumption in Watts", accent: Color.tahoeAccentOrange) {
                                if #available(macOS 13.0, *) {
                                    Chart(data) { point in
                                        LineMark(
                                            x: .value("Time", point.timestamp),
                                            y: .value("Watts", point.safeCpuWatts)
                                        )
                                        .foregroundStyle(Color.tahoeAccentOrange)
                                        
                                        AreaMark(
                                            x: .value("Time", point.timestamp),
                                            y: .value("Watts", point.safeCpuWatts)
                                        )
                                        .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color.tahoeAccentOrange.opacity(0.3), Color.clear]), startPoint: .top, endPoint: .bottom))
                                    }
                                    .frame(height: 150)
                                } else {
                                    Text("Charts require macOS 13.0+")
                                }
                            }
                        }

                        // CPU Average Frequency Chart (GHz)
                        if showCpuFreq {
                            HistoryCard(title: "CPU Average Frequency", subtitle: "Average core frequency in GHz", accent: Color.tahoeAccentCyan) {
                                if #available(macOS 13.0, *) {
                                    Chart(data) { point in
                                        LineMark(
                                            x: .value("Time", point.timestamp),
                                            y: .value("GHz", point.safeCpuFreqAvg)
                                        )
                                        .foregroundStyle(Color.tahoeAccentCyan)
                                        
                                        AreaMark(
                                            x: .value("Time", point.timestamp),
                                            y: .value("GHz", point.safeCpuFreqAvg)
                                        )
                                        .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color.tahoeAccentCyan.opacity(0.3), Color.clear]), startPoint: .top, endPoint: .bottom))
                                    }
                                    .frame(height: 150)
                                } else {
                                    Text("Charts require macOS 13.0+")
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            historyManager.sampleCurrentTelemetry()
            loadChartData()
        }
    }
}

struct HistoryCard<Content: View>: View {
    let title: String
    let subtitle: String
    let accent: Color
    let content: Content
    
    init(title: String, subtitle: String, accent: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.accent = accent
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.tahoeText)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(Color.tahoeSubtext)
                }
                Spacer()
            }
            
            content
        }
        .padding(20)
        .background(Color.tahoeCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.tahoeCardBorder, lineWidth: 1)
        )
    }
}

struct DesktopWidgetsConfigView: View {
    @ObservedObject var model: TelemetryModel
    @ObservedObject var manager = DesktopWidgetManager.shared
    
    @AppStorage("widget_enabled_CPU") private var widgetCpuEnabled = false
    @AppStorage("widget_enabled_GPU") private var widgetGpuEnabled = false
    @AppStorage("widget_enabled_RAM") private var widgetRamEnabled = false
    @AppStorage("widget_enabled_Disk") private var widgetDiskEnabled = false
    @AppStorage("widget_enabled_Net") private var widgetNetEnabled = false
    @AppStorage("widget_enabled_Fan") private var widgetFanEnabled = false
    @AppStorage("widget_enabled_Clock") private var widgetClockEnabled = false
    @AppStorage("widget_enabled_United") private var widgetUnitedEnabled = false
    
    @AppStorage("widget_united_show_cpu") private var unitedShowCpu = true
    @AppStorage("widget_united_show_gpu") private var unitedShowGpu = true
    @AppStorage("widget_united_show_ram") private var unitedShowRam = true
    @AppStorage("widget_united_show_disk") private var unitedShowDisk = true
    @AppStorage("widget_united_show_net") private var unitedShowNet = false
    @AppStorage("widget_united_show_fan") private var unitedShowFan = false
    
    @AppStorage("widget_auto_align") private var widgetAutoAlign = false
    @AppStorage("widget_align_corner") private var widgetAlignCorner = "topRight"
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionTitle("Desktop Widgets")
                Text("Show a floating, non-interactive widget on your desktop for live telemetry.")
                    .font(.system(size: 11)).foregroundColor(.tahoeSubtext)
                
                TahoeCard(accent: Color.tahoeAccentBlue.opacity(0.15)) {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Edit Widget Layout").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                                Text("Unlock widgets to drag them around the screen").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                            }
                            Spacer()
                            Button(action: {
                                widgetCpuEnabled = false
                                widgetGpuEnabled = false
                                widgetRamEnabled = false
                                widgetDiskEnabled = false
                                widgetNetEnabled = false
                                widgetFanEnabled = false
                                widgetClockEnabled = false
                                widgetUnitedEnabled = false
                                DesktopWidgetManager.shared.refreshWidgets()
                                NotificationCenter.default.post(name: .init("WidgetSettingsChanged"), object: nil)
                            }) {
                                Text(NSLocalizedString("Disable All Widgets", comment: ""))
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.8))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {
                                manager.isEditingWidgets.toggle()
                            }) {
                                Text(manager.isEditingWidgets ? "Done" : "Edit Layout")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(manager.isEditingWidgets ? .black : .white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(manager.isEditingWidgets ? Color.white : Color.tahoeAccentBlue)
                                    .cornerRadius(6)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        HStack {
                            Text("Show CPU Widget").font(.system(size: 11)).foregroundColor(.tahoeText)
                            Spacer()
                            Toggle("", isOn: $widgetCpuEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentBlue)).labelsHidden()
                        }
                        
                        HStack {
                            Text("Show GPU Widget").font(.system(size: 11)).foregroundColor(.tahoeText)
                            Spacer()
                            Toggle("", isOn: $widgetGpuEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentBlue)).labelsHidden()
                        }
                        
                        HStack {
                            Text("Show RAM Widget").font(.system(size: 11)).foregroundColor(.tahoeText)
                            Spacer()
                            Toggle("", isOn: $widgetRamEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentBlue)).labelsHidden()
                        }
                        
                        HStack {
                            Text("Show Disk Widget").font(.system(size: 11)).foregroundColor(.tahoeText)
                            Spacer()
                            Toggle("", isOn: $widgetDiskEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentBlue)).labelsHidden()
                        }
                        
                        HStack {
                            Text("Show Network Widget").font(.system(size: 11)).foregroundColor(.tahoeText)
                            Spacer()
                            Toggle("", isOn: $widgetNetEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentBlue)).labelsHidden()
                        }
                        
                        HStack {
                            Text("Show Fan Widget").font(.system(size: 11)).foregroundColor(.tahoeText)
                            Spacer()
                            Toggle("", isOn: $widgetFanEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentBlue)).labelsHidden()
                        }
                        
                        HStack {
                            Text("Show Clock Widget").font(.system(size: 11)).foregroundColor(.tahoeText)
                            Spacer()
                            Toggle("", isOn: $widgetClockEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentBlue)).labelsHidden()
                        }
                        
                        HStack {
                            Text("Show United Widget").font(.system(size: 11)).foregroundColor(.tahoeText)
                            Spacer()
                            Toggle("", isOn: $widgetUnitedEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentBlue)).labelsHidden()
                        }
                        
                        if widgetUnitedEnabled {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Configure Combined Metrics").font(.system(size: 10, weight: .semibold)).foregroundColor(.tahoeSubtext)
                                    .padding(.top, 4)
                                
                                HStack {
                                    Text("Include CPU").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                                    Spacer()
                                    Toggle("", isOn: $unitedShowCpu)
                                        .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentBlue)).labelsHidden()
                                        .scaleEffect(0.8)
                                }
                                HStack {
                                    Text("Include GPU").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                                    Spacer()
                                    Toggle("", isOn: $unitedShowGpu)
                                        .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentBlue)).labelsHidden()
                                        .scaleEffect(0.8)
                                }
                                HStack {
                                    Text("Include RAM").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                                    Spacer()
                                    Toggle("", isOn: $unitedShowRam)
                                        .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentBlue)).labelsHidden()
                                        .scaleEffect(0.8)
                                }
                                HStack {
                                    Text("Include Disk").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                                    Spacer()
                                    Toggle("", isOn: $unitedShowDisk)
                                        .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentBlue)).labelsHidden()
                                        .scaleEffect(0.8)
                                }
                                HStack {
                                    Text("Include Network").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                                    Spacer()
                                    Toggle("", isOn: $unitedShowNet)
                                        .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentBlue)).labelsHidden()
                                        .scaleEffect(0.8)
                                }
                                HStack {
                                    Text("Include Fan").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                                    Spacer()
                                    Toggle("", isOn: $unitedShowFan)
                                        .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentBlue)).labelsHidden()
                                        .scaleEffect(0.8)
                                }
                            }
                            .padding(.leading, 12)
                            .padding(.bottom, 4)
                        }
                    }
                }
                
                Divider().background(Color.tahoeCardBorder)
                
                SectionTitle("Widget Options")
                Text("Customize the appearance and behavior of your desktop widgets.")
                    .font(.system(size: 11)).foregroundColor(.tahoeSubtext)
                
                TahoeCard(accent: Color.tahoeAccentCyan.opacity(0.15)) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Right-click any widget directly on your desktop to change its style dynamically (Classic Glass, Pro Monitor, or Core Matrix).").font(.system(size: 11)).foregroundColor(.tahoeSubtext)
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Auto-Align Active Widgets").font(.system(size: 11, weight: .semibold)).foregroundColor(.tahoeText)
                                Text("Automatically stack active widgets at a corner").font(.system(size: 9)).foregroundColor(.tahoeSubtext)
                            }
                            Spacer()
                            Toggle("", isOn: $widgetAutoAlign)
                                .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentCyan)).labelsHidden()
                        }
                        
                        if widgetAutoAlign {
                            HStack {
                                Text("Alignment Corner").font(.system(size: 11, weight: .semibold)).foregroundColor(.tahoeText)
                                Spacer()
                                Picker("", selection: $widgetAlignCorner) {
                                    Text("Top Right").tag("topRight")
                                    Text("Top Left").tag("topLeft")
                                    Text("Bottom Right").tag("bottomRight")
                                    Text("Bottom Left").tag("bottomLeft")
                                }
                                .pickerStyle(.menu)
                                .frame(width: 140)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24).padding(.vertical, 20)
        }
        .onChange(of: widgetCpuEnabled) { _ in
            manager.refreshWidgets()
            NotificationCenter.default.post(name: .init("WidgetSettingsChanged"), object: nil)
        }
        .onChange(of: widgetGpuEnabled) { _ in
            manager.refreshWidgets()
            NotificationCenter.default.post(name: .init("WidgetSettingsChanged"), object: nil)
        }
        .onChange(of: widgetRamEnabled) { _ in
            manager.refreshWidgets()
            NotificationCenter.default.post(name: .init("WidgetSettingsChanged"), object: nil)
        }
        .onChange(of: widgetDiskEnabled) { _ in
            manager.refreshWidgets()
            NotificationCenter.default.post(name: .init("WidgetSettingsChanged"), object: nil)
        }
        .onChange(of: widgetNetEnabled) { _ in
            manager.refreshWidgets()
            NotificationCenter.default.post(name: .init("WidgetSettingsChanged"), object: nil)
        }
        .onChange(of: widgetFanEnabled) { _ in
            manager.refreshWidgets()
            NotificationCenter.default.post(name: .init("WidgetSettingsChanged"), object: nil)
        }
        .onChange(of: widgetClockEnabled) { _ in
            manager.refreshWidgets()
            NotificationCenter.default.post(name: .init("WidgetSettingsChanged"), object: nil)
        }
        .onChange(of: widgetUnitedEnabled) { _ in
            manager.refreshWidgets()
            NotificationCenter.default.post(name: .init("WidgetSettingsChanged"), object: nil)
        }
        .onChange(of: widgetAutoAlign) { _ in
            manager.refreshWidgets()
            NotificationCenter.default.post(name: .init("WidgetSettingsChanged"), object: nil)
        }
        .onChange(of: widgetAlignCorner) { _ in
            manager.refreshWidgets()
            NotificationCenter.default.post(name: .init("WidgetSettingsChanged"), object: nil)
        }
    }
}