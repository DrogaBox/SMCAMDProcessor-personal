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
    case systemInfo = "System Info"

    var icon: String {
        switch self {
        case .dashboard:  return "gauge.medium"
        case .telemetry:  return "waveform.path.ecg"
        case .fanControl: return "fan"
        case .profiles:   return "slider.horizontal.3"
        case .advanced:   return "gearshape.2"
        case .menuBar:    return "menubar.rectangle"
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
                Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.0.0") · macOS Tahoe").font(.system(size: 9, weight: .regular)).foregroundColor(Color(white: 0.35)).padding(.horizontal, 18).padding(.bottom, 14)
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
        .padding(.vertical, 8).padding(.horizontal, 14)
        .background(Color.tahoeCard)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.tahoeCardBorder))
        .cornerRadius(8)
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
                .onChange(of: isOn) { _, newValue in onChange(newValue) }
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
                InfoRow(label: "CPU Model",       value: model.sysInfo.cpuBrand)
                InfoRow(label: "Avg Frequency",   value: String(format: "%.3f GHz", model.cpuFreqAvgGHz))
                InfoRow(label: "Max Frequency",   value: String(format: "%.3f GHz", model.cpuFreqMaxGHz))
                InfoRow(label: "CPU Temperature", value: String(format: "%.2f °C",  model.cpuTempC))
                InfoRow(label: "Package Power",   value: String(format: "%.2f W",   model.cpuWatts))
                InfoRow(label: "GPU Temperature", value: String(format: "%.2f °C",  model.gpuTempC))
                InfoRow(label: "GPU Power",       value: String(format: "%.2f W",   model.gpuPowerW))
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
            SectionTitle("Current Utilization — \(model.sysInfo.logicalCores) Threads (\(model.sysInfo.physicalCores) Cores)")
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
        core.isLogical ? "T\(core.id + 1)" : "C\(core.id + 1)"
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
                if !model.smcDriverLoaded { SMCNotAvailableView() }
                else if model.fans.isEmpty { Text("No fans detected.").foregroundColor(.tahoeSubtext).frame(maxWidth: .infinity).padding(32) }
                else {
                    SectionTitle("SMC Fan Control")
                    ForEach(model.fans) { fan in FanControlCard(fan: fan, model: model) }
                    HStack(spacing: 10) {
                        TahoeButton(label: "All Auto", icon: "arrow.circlepath", accent: .tahoeAccentCyan) { model.setAllFansAuto() }
                        TahoeButton(label: "Max Speed", icon: "wind", accent: .tahoeAccentOrange) { model.setAllFansTakeOff() }
                    }
                }
            }
            .padding(18)
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
        .onChange(of: fan.throttle) { _, newVal in sliderValue = Double(newVal) }
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
                if stepLabels.indices.contains(model.selectedSpeedStep) {
                    InfoRow(label: "Profile", value: stepLabels[model.selectedSpeedStep].replacingOccurrences(of: "\n", with: " — "))
                }
                InfoRow(label: "Avg Frequency", value: String(format: "%.3f GHz", model.cpuFreqAvgGHz))
                InfoRow(label: "Max Frequency", value: String(format: "%.3f GHz", model.cpuFreqMaxGHz))
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
        .onChange(of: value) { _, newVal in editText = String(format: "%X", newVal) }
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
            .onChange(of: value) { _, newValue in
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
                        Text("F\(cfg.fanIndex + 1)")
                            .font(.system(size: 7.2, weight: .regular, design: .monospaced))
                            .lineSpacing(-3)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.8))
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("2100").font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                            Text("RPM").font(.system(size: 9, weight: .semibold)).foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .frame(width: 56, alignment: .leading)
                }
                
                // Memory Column
                if cfg.showMemory {
                    HStack(spacing: 2) {
                        Text("MEM")
                            .font(.system(size: 7.2, weight: .regular, design: .monospaced))
                            .lineSpacing(-3)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.8))
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("11,5G").font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                            Text("32G").font(.system(size: 9, weight: .semibold)).foregroundColor(.white.opacity(0.7))
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
                        Text("Color de Flechas").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                        Spacer()
                        Picker("", selection: .init(
                            get: { cfg.netColorIdx },
                            set: { cfg.netColorIdx = $0; notify() }
                        )) {
                            Text("Verde").tag(0)
                            Text("Azul").tag(1)
                            Text("Naranja").tag(2)
                            Text("Rojo").tag(3)
                            Text("Morado").tag(4)
                            Text("Rosa").tag(5)
                            Text("Turquesa").tag(6)
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
                Text("GPU data is shown inside Temp and Power columns when enabled.")
                    .font(.system(size: 12)).foregroundColor(.tahoeSubtext)

                ToggleRow(label: "Show GPU Temp", detail: "G:XX°C in Temp column", isOn: .init(
                    get: { cfg.showGPUtemp }, set: { cfg.showGPUtemp = $0; notify() }
                ), accent: .tahoeAccentPurple) { _ in }

                ToggleRow(label: "Show GPU Power", detail: "G:XXW in Power column", isOn: .init(
                    get: { cfg.showGPUpwr }, set: { cfg.showGPUpwr = $0; notify() }
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
                        Text("Color de Alerta de Temp").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                        Spacer()
                        Picker("", selection: .init(
                            get: { cfg.tempColorIdx },
                            set: { cfg.tempColorIdx = $0; notify() }
                        )) {
                            Text("Verde").tag(0)
                            Text("Azul").tag(1)
                            Text("Naranja").tag(2)
                            Text("Rojo").tag(3)
                            Text("Morado").tag(4)
                            Text("Rosa").tag(5)
                            Text("Turquesa").tag(6)
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
                    Text("Vista previa de la Barra de Menús:")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.tahoeSubtext)
                    
                    MenuBarPreview(cfg: cfg)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.tahoeBackground.opacity(0.6))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.tahoeCardBorder))
                        )
                    
                    Text("Ancho estimado: \(Int(cfg.totalWidth))pt")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.tahoeSubtext)
                }
                .padding(.top, 4)
            }
            .padding(18)
        }
    }

    private func notify() {
        cfg = MenuBarConfig()
        NotificationCenter.default.post(name: .init("MenuBarConfigChanged"), object: nil)
        needsRestart = true
    }
}

// MARK: - System Info Tab
struct SystemInfoContentView: View {
    @ObservedObject var model: TelemetryModel
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionTitle("Processor")
                InfoRow(label: "CPU Model",      value: model.sysInfo.cpuBrand)
                InfoRow(label: "Family",          value: model.sysInfo.cpuFamily)
                InfoRow(label: "Model ID",        value: model.sysInfo.cpuModel)
                InfoRow(label: "Physical Cores",  value: "\(model.sysInfo.physicalCores)")
                InfoRow(label: "Logical Cores",   value: "\(model.sysInfo.logicalCores)")
                InfoRow(label: "L1 Cache (Total)",value: "\(model.sysInfo.l1KB) KB")
                InfoRow(label: "L2 Cache (Total)",value: "\(model.sysInfo.l2MB) MB")
                InfoRow(label: "L3 Cache (Shared)",value: "\(model.sysInfo.l3MB) MB")

                Divider().background(Color.tahoeCardBorder)
                SectionTitle("Platform")
                if !model.sysInfo.boardName.isEmpty {
                    InfoRow(label: "Motherboard", value: model.sysInfo.boardName)
                    InfoRow(label: "Manufacturer", value: model.sysInfo.boardVendor)
                } else {
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
                InfoRow(label: "Graphics", value: model.sysInfo.gpuModel.isEmpty ? "Unknown" : model.sysInfo.gpuModel)
                InfoRow(label: "Memory",   value: "\(model.sysInfo.ramGB) GB")
                InfoRow(label: "Storage",  value: "\(model.sysInfo.storageGB) GB")

                Divider().background(Color.tahoeCardBorder)
                SectionTitle("Software")
                InfoRow(label: "macOS Version",   value: model.sysInfo.macOSVersion)
                InfoRow(label: "Kext Version",    value: model.sysInfo.kextVersion)
                InfoRow(label: "CPU Supported",   value: model.sysInfo.kextSupported ? "Yes ✅" : "Not yet")

                Divider().background(Color.tahoeCardBorder)
                SectionTitle("Links")
                HStack(spacing: 10) {
                    TahoeButton(label: "GitHub Repository", icon: "link", accent: .tahoeAccentCyan) {
                        NSWorkspace.shared.open(URL(string: "https://github.com/trulyspinach/SMCAMDProcessor")!)
                    }
                }
            }
            .padding(18)
        }
    }
// MARK: - Refresh Rate Config
class RefreshRateConfig: ObservableObject {
    static let shared = RefreshRateConfig()
    private let ud = UserDefaults.standard

    @Published var interval: Double = 1.0 {
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

}