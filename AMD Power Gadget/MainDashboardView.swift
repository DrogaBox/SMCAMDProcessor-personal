//
//  MainDashboardView.swift
//  AMD Power Gadget
//
//  Created by Droga (2026) — SwiftUI Tahoe Redesign
//

import SwiftUI
import Charts

// MARK: - Visual Effect Blur Background (macOS)
struct VisualEffectBackground: NSViewRepresentable {
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

// MARK: - Design Tokens
private extension Color {
    static let tahoeBackground   = Color(red: 0.06, green: 0.07, blue: 0.10).opacity(0.72)
    static let tahoeSidebar      = Color(red: 0.08, green: 0.09, blue: 0.13).opacity(0.25)
    static let tahoeCard         = Color(red: 0.10, green: 0.12, blue: 0.17).opacity(0.82)
    static let tahoeCardBorder   = Color(white: 1.0, opacity: 0.07)
    static let tahoeAccentCyan   = Color(red: 0.0,  green: 0.85, blue: 0.95)
    static let tahoeAccentOrange = Color(red: 1.0,  green: 0.55, blue: 0.10)
    static let tahoeAccentGreen  = Color(red: 0.1,  green: 0.95, blue: 0.45)
    static let tahoeAccentPurple = Color(red: 0.65, green: 0.40, blue: 1.0)
    static let tahoeAccentRed    = Color(red: 1.0,  green: 0.30, blue: 0.30)
    static let tahoeAccentBlue   = Color(red: 0.35, green: 0.55, blue: 1.0)
    static let tahoeText         = Color(white: 0.90)
    static let tahoeSubtext      = Color(white: 0.50)
    static let tahoeSidebarActive = Color(red: 0.12, green: 0.15, blue: 0.24)
}

private enum DashboardTab: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case dashboard  = "Dashboard"
    case telemetry  = "Telemetry"
    case fanControl = "Fan Control"
    case profiles   = "Profiles"
    case advanced   = "Advanced"
    case menuBar    = "Menu Bar"
    case popover    = "Popover Menu"
    case systemInfo = "System Info"

    var icon: String {
        switch self {
        case .dashboard:  return "gauge.medium"
        case .telemetry:  return "waveform.path.ecg"
        case .fanControl: return "fan"
        case .profiles:   return "slider.horizontal.3"
        case .advanced:   return "gearshape.2"
        case .menuBar:    return "menubar.rectangle"
        case .popover:    return "macwindow.badge.plus"
        case .systemInfo: return "info.circle"
        }
    }
}

struct MainDashboardView: View {
    @ObservedObject var model: TelemetryModel
    @State private var selectedTab: DashboardTab = .dashboard

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(selectedTab: $selectedTab, model: model)
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
        switch selectedTab {
        case .dashboard:  DashboardContentView(model: model)
        case .telemetry:  TelemetryContentView(model: model)
        case .fanControl: FanControlContentView(model: model)
        case .profiles:   ProfilesContentView(model: model)
        case .advanced:   AdvancedContentView(model: model)
        case .menuBar:    MenuBarConfigView(model: model)
        case .popover:    PopoverConfigView(model: model)
        case .systemInfo: SystemInfoContentView(model: model)
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
    init(accent: Color = .tahoeCardBorder, @ViewBuilder content: () -> Content) {
        self.accent = accent; self.content = content()
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
                            .fill(.ultraThinMaterial)
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
                    LineMark(
                        x: .value("Index", Double(index)),
                        y: .value(line1Label, line1(pt))
                    )
                    .foregroundStyle(accent)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Index", Double(index)),
                        y: .value(line1Label, line1(pt))
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accent.opacity(0.15), accent.opacity(0.0)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle("CPU Frequency & Demand")
                ResizableChart(chartId: "tele_bar", small: 100, medium: 140, large: 200) { height in
                    PowerToolBarChart(model: model, height: height)
                }

                SectionTitle("Live Telemetry History")
                ResizableChart(chartId: "tele_cputemp", small: 50, medium: 80, large: 120) { height in
                    TahoeCard {
                        SimpleLineChart(title: "CPU Temperature", unit: "°C", color: .tahoeAccentOrange, data: model.history, value: { $0.cpuTempC }, height: height)
                    }
                }
                ResizableChart(chartId: "tele_gputemp", small: 50, medium: 80, large: 120) { height in
                    TahoeCard {
                        SimpleLineChart(title: "GPU Temperature", unit: "°C", color: Color(red: 0.8, green: 0.5, blue: 1.0), data: model.history, value: { $0.gpuTempC }, height: height)
                    }
                }
                ResizableChart(chartId: "tele_cpupwr", small: 50, medium: 80, large: 120) { height in
                    TahoeCard {
                        SimpleLineChart(title: "CPU Package Power", unit: "W", color: .tahoeAccentGreen, data: model.history, value: { $0.cpuWatts }, height: height)
                    }
                }
                ResizableChart(chartId: "tele_gpupwr", small: 50, medium: 80, large: 120) { height in
                    TahoeCard {
                        SimpleLineChart(title: "GPU Power", unit: "W", color: .tahoeAccentPurple, data: model.history, value: { $0.gpuWatts }, height: height)
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
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(chartStyle == styleIdx ? Color.tahoeSidebarActive : Color.clear)
                                .cornerRadius(5)
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
                    
                    Spacer()
                        .frame(width: 8)
                    
                    if let last = model.history.last {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.tahoeAccentPurple)
                            Text(formatSpeed(last.netUploadMBps))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.tahoeAccentPurple)
                        }
                    }
                }

                // Chart in the middle (changes based on style selection)
                if model.history.count > 1 {
                    let indexedData = Array(model.history.enumerated())
                    let maxIndex = Double(max(1, indexedData.count - 1))

                    if chartStyle == 0 {
                        // Style 0: Bidirectional Bars (Categorical X-axis for dense layout)
                        Chart {
                            ForEach(indexedData, id: \.offset) { index, pt in
                                BarMark(
                                    x: .value("Index", "\(index)"),
                                    y: .value("Upload", pt.netUploadMBps),
                                    width: .ratio(0.9)
                                )
                                .foregroundStyle(Color.tahoeAccentPurple)
                            }

                            ForEach(indexedData, id: \.offset) { index, pt in
                                BarMark(
                                    x: .value("Index", "\(index)"),
                                    y: .value("Download", -pt.netDownloadMBps),
                                    width: .ratio(0.9)
                                )
                                .foregroundStyle(Color.tahoeAccentBlue)
                            }
                        }
                        .chartYScale(domain: yDomainMin...yDomainMax)
                        .chartXScale(domain: indexedData.map { "\($0.offset)" })
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
                                    y: .value("Download", pt.netDownloadMBps)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.tahoeAccentBlue.opacity(0.25), Color.tahoeAccentBlue.opacity(0.0)],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                )
                                .interpolationMethod(.catmullRom)

                                LineMark(
                                    x: .value("Index", Double(index)),
                                    y: .value("Download", pt.netDownloadMBps)
                                )
                                .foregroundStyle(Color.tahoeAccentBlue)
                                .lineStyle(StrokeStyle(lineWidth: 2))
                                .interpolationMethod(.catmullRom)
                            }

                            ForEach(indexedData, id: \.offset) { index, pt in
                                AreaMark(
                                    x: .value("Index", Double(index)),
                                    y: .value("Upload", pt.netUploadMBps)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.tahoeAccentPurple.opacity(0.20), Color.tahoeAccentPurple.opacity(0.0)],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                )
                                .interpolationMethod(.catmullRom)

                                LineMark(
                                    x: .value("Index", Double(index)),
                                    y: .value("Upload", pt.netUploadMBps)
                                )
                                .foregroundStyle(Color.tahoeAccentPurple)
                                .lineStyle(StrokeStyle(lineWidth: 1.5))
                                .interpolationMethod(.catmullRom)
                            }
                        }
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
                        // Style 2: Total & Average (Glowing area with dotted rule indicator)
                        let maxTotal = model.history.map { $0.netUploadMBps + $0.netDownloadMBps }.max() ?? 0.05
                        let yLimitMax = maxTotal * 1.15
                        let yAxisVals = [0.0, maxTotal / 2.0, maxTotal]
                        let averageTotal = model.history.map { $0.netUploadMBps + $0.netDownloadMBps }.reduce(0, +) / Double(max(1, model.history.count))

                        Chart {
                            ForEach(indexedData, id: \.offset) { index, pt in
                                let total = pt.netUploadMBps + pt.netDownloadMBps
                                AreaMark(
                                    x: .value("Index", Double(index)),
                                    y: .value("Total", total)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.tahoeAccentOrange.opacity(0.28), Color.tahoeAccentOrange.opacity(0.0)],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                )
                                .interpolationMethod(.catmullRom)

                                LineMark(
                                    x: .value("Index", Double(index)),
                                    y: .value("Total", total)
                                )
                                .foregroundStyle(Color.tahoeAccentOrange)
                                .lineStyle(StrokeStyle(lineWidth: 2.5))
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
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 8)

    var body: some View {
        TahoeCard {
            HStack(alignment: .center) {
                SectionTitle("Current Utilization — \(model.sysInfo.logicalCores) Threads (\(model.sysInfo.physicalCores) Cores)")
                if model.cppcSupported {
                    Spacer()
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
            .padding(.bottom, 4)

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(model.cores) { CoreCell(core: $0) }
            }
        }
    }
}

private struct CoreCell: View {
    let core: CoreSnapshot
    private var loadColor: Color {
        if core.loadPct > 80 { return Color(red: 1.0, green: 0.35, blue: 0.3) }
        if core.loadPct > 50 { return Color(red: 1.0, green: 0.75, blue: 0.1) }
        return Color.tahoeAccentGreen
    }
    private var labelText: String {
        let base = core.isLogical ? "T\(core.id + 1)" : "C\(core.id + 1)"
        if let score = core.cppcScore, score > 0 {
            let prefix = core.cppcScoreEstimated ? "~" : ""
            return "\(base) [\(prefix)\(score)]"
        }
        return base
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(labelText).font(.system(size: 8, weight: .medium))
                    .foregroundColor(core.isLogical ? Color.tahoeSubtext.opacity(0.7) : .tahoeSubtext)
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
                SectionTitle("CPU Speed Profiles")
                Text("Select a profile to adjust the CPU operating range. Changes take effect immediately.")
                    .font(.system(size: 12)).foregroundColor(.tahoeSubtext)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(Array(stepLabels.enumerated()), id: \.offset) { i, label in
                        SpeedStepCard(label: label, isActive: model.selectedSpeedStep == i) { model.setSpeedStep(i) }
                    }
                }
                SectionTitle("Active Profile")
                TahoeCard {
                    if stepLabels.indices.contains(model.selectedSpeedStep) {
                        InfoRow(label: "Profile", value: stepLabels[model.selectedSpeedStep].replacingOccurrences(of: "\n", with: " — "))
                        Divider().background(Color.tahoeCardBorder)
                    }
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
            }
            .padding(18)
        }
    }
}

private struct PStateEditorView: View {
    @ObservedObject var model: TelemetryModel
    @State private var showApplyConfirm = false
    @State private var applyOK: Bool? = nil
    @State private var isUnlocked = false
    private let columns = ["#", "En", "IddDiv", "IddValue", "CpuVid", "DfsId", "FID", "MHz"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Dangerous protection checkbox
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
            
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 0) {
                    ForEach(columns, id: \.self) { col in
                        Text(col).font(.system(size: 10, weight: .bold)).foregroundColor(.tahoeSubtext).frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 6).background(Color.tahoeBackground.opacity(0.5)).cornerRadius(8)
                
                ForEach($model.pStateRows) { $row in PStateRowView(row: $row, isDirty: $model.pStateEditorDirty) }
                
                HStack(spacing: 8) {
                    TahoeButton(label: "Apply", icon: "checkmark.circle", accent: .tahoeAccentCyan) { showApplyConfirm = true }
                    TahoeButton(label: "Revert", icon: "arrow.counterclockwise", accent: .tahoeAccentOrange) { model.loadPStateRows() }
                    TahoeButton(label: "Import", icon: "square.and.arrow.down", accent: .tahoeAccentGreen) {
                        let op = NSOpenPanel(); if op.runModal() == .OK, let url = op.url { model.importPStates(from: url) }
                    }
                    TahoeButton(label: "Export", icon: "square.and.arrow.up", accent: .tahoeAccentPurple) {
                        let op = NSSavePanel(); op.isExtensionHidden = false
                        op.allowedContentTypes = [.init(filenameExtension: "pstate") ?? .data]
                        if op.runModal() == .OK, let url = op.url { model.exportPStates(to: url) }
                    }
                }
                
                if let ok = applyOK {
                    Text(ok ? "✅ P-States applied successfully." : "❌ Failed — check kext privileges (-amdpnopchk).")
                        .font(.system(size: 11)).foregroundColor(ok ? .tahoeAccentGreen : .tahoeAccentRed)
                }
            }
            .opacity(isUnlocked ? 1.0 : 0.4)
            .disabled(!isUnlocked)
            .animation(.easeInOut(duration: 0.25), value: isUnlocked)
        }
        .padding(14).background(Color.tahoeCard.opacity(0.85))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(model.pStateEditorDirty ? Color.tahoeAccentOrange.opacity(0.5) : Color.tahoeCardBorder))
        .cornerRadius(14)
        .confirmationDialog("Apply P-States?", isPresented: $showApplyConfirm, titleVisibility: .visible) {
            Button("Apply", role: .destructive) { applyOK = model.applyPStates() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This will write the raw P-State definitions directly to the CPU. Proceed?") }
    }
}

private struct PStateRowView: View {
    @Binding var row: PStateRow; @Binding var isDirty: Bool
    var body: some View {
        HStack(spacing: 0) {
            Text("\(row.id)").font(.system(size: 10, design: .monospaced)).foregroundColor(.tahoeSubtext).frame(maxWidth: .infinity)
            Button(action: { row.enabled = row.enabled == 1 ? 0 : 1; isDirty = true }) {
                Image(systemName: row.enabled == 1 ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(row.enabled == 1 ? .tahoeAccentCyan : .tahoeSubtext).font(.system(size: 12))
            }
            .buttonStyle(.plain).frame(maxWidth: .infinity)
            HexCell(value: $row.iddDiv, dirty: $isDirty)
            HexCell(value: $row.iddValue, dirty: $isDirty)
            HexCell(value: $row.cpuVid, dirty: $isDirty)
            HexCell(value: $row.cpuDfsId, dirty: $isDirty)
            HexCell(value: $row.cpuFid, dirty: $isDirty)
            Text(row.cpuDfsId > 0 ? String(format: "%.0f", row.computedSpeedMHz) : "—")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(row.enabled == 1 ? .tahoeAccentCyan : .tahoeSubtext).frame(maxWidth: .infinity)
        }
        .padding(.vertical, 6).padding(.horizontal, 12)
        .background(row.enabled == 1 ? Color.tahoeAccentCyan.opacity(0.05) : Color.tahoeBackground.opacity(0.4))
        .cornerRadius(6)
    }
}

private struct HexCell: View {
    @Binding var value: UInt32; @Binding var dirty: Bool
    @State private var editText = ""; @State private var isEditing = false
    var body: some View {
        TextField("", text: $editText, onEditingChanged: { editing in
            isEditing = editing
            if !editing {
                if let v = UInt32(editText, radix: 16) { value = v; dirty = true }
                else { editText = String(format: "%X", value) }
            }
        })
        .font(.system(size: 10, design: .monospaced))
        .foregroundColor(isEditing ? .tahoeAccentCyan : .tahoeText)
        .multilineTextAlignment(.center).frame(maxWidth: .infinity)
        .onAppear { editText = String(format: "%X", value) }
        .onChange(of: value) { newVal in editText = String(format: "%X", newVal) }
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

struct MenuBarPreview: View {
    let cfg: MenuBarConfig
    
    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                // CPU Column
                if cfg.showCPU {
                    HStack(spacing: 2) {
                        Text("C\nP\nU")
                            .font(.system(size: 7.2, weight: .regular, design: .monospaced))
                            .lineSpacing(-3)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.8))
                        
                        if cfg.showMaxFreqOnly {
                            Text("4.9G")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("4.9Ghz").font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                                Text("3.6Ghz").font(.system(size: 9, weight: .semibold)).foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    .frame(width: cfg.showMaxFreqOnly ? 48 : 56, alignment: .leading)
                }
                
                // Temp Column
                if cfg.showTemp {
                    let tempVal = 82
                    let isAlert = cfg.enableColorAlerts && tempVal >= cfg.tempThreshold
                    let tempColor = isAlert ? getSwiftUIColor(index: cfg.tempColorIdx) : Color.white
                    
                    HStack(spacing: 2) {
                        Text("T\nM\nP")
                            .font(.system(size: 7.2, weight: .regular, design: .monospaced))
                            .lineSpacing(-3)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.8))
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("C:\(tempVal)\(cfg.useFahrenheit ? "F" : "º")")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(tempColor)
                            
                            if cfg.showGPU && cfg.showGPUtemp {
                                let gpuIsAlert = cfg.enableColorAlerts && 45 >= cfg.tempThreshold
                                let gpuColor = gpuIsAlert ? getSwiftUIColor(index: cfg.tempColorIdx) : Color.white
                                Text("G:45\(cfg.useFahrenheit ? "F" : "º")")
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
                    HStack(spacing: 2) {
                        Text("P\nW\nR")
                            .font(.system(size: 7.2, weight: .regular, design: .monospaced))
                            .lineSpacing(-3)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.8))
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("C:85W").font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                            if cfg.showGPU && cfg.showGPUpwr {
                                Text("G:25W").font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                            } else {
                                Text("—").font(.system(size: 9, weight: .semibold)).foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    .frame(width: 56, alignment: .leading)
                }
                
                // Fan Column
                if cfg.showFanRPM {
                    HStack(spacing: 2) {
                        Text("F\nA\nN")
                            .font(.system(size: 7.2, weight: .regular, design: .monospaced))
                            .lineSpacing(-3)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.8))
                        
                        VStack(alignment: .leading, spacing: 0) {
                            if cfg.showGPU && cfg.showGPUfan {
                                Text("C:2100").font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                                Text("G:1200").font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                            } else {
                                Text("2100").font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                                Text("RPM").font(.system(size: 9, weight: .semibold)).foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    .frame(width: 56, alignment: .leading)
                }
                
                // Memory Column
                if cfg.showMemory {
                    HStack(spacing: 2) {
                        Text("M\nE\nM")
                            .font(.system(size: 7.2, weight: .regular, design: .monospaced))
                            .lineSpacing(-3)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.8))
                        
                        VStack(alignment: .leading, spacing: 0) {
                            if cfg.showGPU && cfg.showGPUvram {
                                Text("S:11,5G").font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                                Text("G:2,4G").font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                            } else {
                                Text("11,5G").font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                                Text("32G").font(.system(size: 9, weight: .semibold)).foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    .frame(width: 56, alignment: .leading)
                }
                
                // Network Column
                if cfg.showNetwork {
                    let arrowColor = getSwiftUIColor(index: cfg.netColorIdx)
                    HStack(spacing: 2) {
                        Text("N\nE\nT")
                            .font(.system(size: 7.2, weight: .regular, design: .monospaced))
                            .lineSpacing(-3)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.8))
                        
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 1) {
                                Text("↑").font(.system(size: 9, weight: .bold)).foregroundColor(arrowColor)
                                Text("0,0 KB/s").font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                            }
                            HStack(spacing: 1) {
                                Text("↓").font(.system(size: 9, weight: .bold)).foregroundColor(arrowColor)
                                Text("1,4 KB/s").font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
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
                    
                    MenuBarPreview(cfg: cfg)
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
                    InfoRow(label: "CPU Supported",   value: model.sysInfo.kextSupported ? "Yes ✅" : "Not yet")
                }

                Divider().background(Color.tahoeCardBorder)
                SectionTitle("Links")
                HStack(spacing: 10) {
                    TahoeButton(label: "GitHub Repository", icon: "link", accent: .tahoeAccentCyan) {
                        NSWorkspace.shared.open(URL(string: "https://github.com/DrogaBox/SMCAMDProcessor-personal")!)
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
                Text("v\(model.sysInfo.kextVersion)")
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
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            
            // 2. Render Vertical List for Bars and Sparklines (style > 0)
            // 2. Render Vertical List for Bars and Sparklines (style > 0 or sparkline enabled)
            let showLinearOrGraphs = rings.contains(where: { ring in
                if ring == "cpu" && cfg.popoverShowCPU && (cfg.popoverCPUStyle == 1 || cfg.popoverShowCPUSparkline) { return true }
                if ring == "ram" && cfg.popoverShowRAM && cfg.popoverRAMStyle == 1 { return true }
                if ring == "disk" && cfg.popoverShowDisk && cfg.popoverDiskStyle == 1 { return true }
                if ring == "gpu" && cfg.popoverShowGPURing && (cfg.popoverGPUStyle == 1 || cfg.popoverShowGPUSparkline) { return true }
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
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10))
                                .foregroundColor(.purple)
                                .frame(width: 14)
                            Text(model.sysInfo.gpuModel.isEmpty || model.sysInfo.gpuModel == "Unknown" ? "Radeon GPU" : model.sysInfo.gpuModel)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                                .fixedSize(horizontal: true, vertical: false)
                            Spacer()
                            if model.gpuTempC > 0 {
                                let vramGB = model.gpuVramUsedBytes / (1024.0 * 1024.0 * 1024.0)
                                let fanRPMStr = model.gpuFanRPM > 0 ? String(format: " • %.0f RPM", model.gpuFanRPM) : ""
                                Text(String(format: "%.0f°C • %.0fW • %.2fG%@", model.gpuTempC, model.gpuPowerW, vramGB, fanRPMStr))
                                    .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.8))
                            } else {
                                Text("Inactive")
                                    .font(.system(size: 9.5, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.4))
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
                                Toggle(isOn: .init(
                                    get: { cfg.popoverShowCPUSparkline },
                                    set: { cfg.popoverShowCPUSparkline = $0; notify(widthChanged: false) }
                                )) {
                                    Text("Show Temperature Sparkline Graph below")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.tahoeText)
                                }
                                .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentCyan))
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
        }
        
        let allKeys = ["cpu", "ram", "disk", "gpu"]
        for key in allKeys {
            if !loadedItems.contains(where: { $0.id == key }) {
                if key == "cpu" { loadedItems.append(RingOrderItem(id: "cpu", name: "CPU Tracker", color: .tahoeAccentCyan)) }
                if key == "ram" { loadedItems.append(RingOrderItem(id: "ram", name: "RAM Tracker", color: .tahoeAccentOrange)) }
                if key == "disk" { loadedItems.append(RingOrderItem(id: "disk", name: "Disk Tracker", color: .tahoeAccentBlue)) }
                if key == "gpu" { loadedItems.append(RingOrderItem(id: "gpu", name: "GPU Tracker", color: .tahoeAccentPurple)) }
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
struct MiniSparkline: View {
    let label: String
    let currentVal: String
    let color: Color
    let data: [TelemetryPoint]
    let value: (TelemetryPoint) -> Double
    var filterZeros: Bool = false
    
    private var filteredData: [TelemetryPoint] {
        if filterZeros {
            return data.filter { value($0) > 0 }
        }
        return data
    }
    
    private var yMin: Double {
        let vals = filteredData.map(value)
        let mn = vals.min() ?? 0
        let mx = vals.max() ?? 100
        let diff = mx - mn
        let span = max(10.0, diff)
        let center = (mx + mn) / 2.0
        return center - span * 0.6
    }
    private var yMax: Double {
        let vals = filteredData.map(value)
        let mn = vals.min() ?? 0
        let mx = vals.max() ?? 100
        let diff = mx - mn
        let span = max(10.0, diff)
        let center = (mx + mn) / 2.0
        return center + span * 0.6
    }
    
    var body: some View {
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
            
            if filteredData.count > 1 {
                let indexedData = Array(filteredData.enumerated())
                Chart(indexedData, id: \.offset) { index, pt in
                    AreaMark(
                        x: .value("Index", Double(index)),
                        y: .value(label, value(pt))
                    )
                    .foregroundStyle(LinearGradient(colors: [color.opacity(0.18), color.opacity(0.0)], startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.catmullRom)
                    
                    LineMark(
                        x: .value("Index", Double(index)),
                        y: .value(label, value(pt))
                    )
                    .foregroundStyle(color)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                    .interpolationMethod(.catmullRom)
                }
                .chartYScale(domain: yMin...yMax)
                .chartXScale(domain: 0...Double(filteredData.count - 1))
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
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