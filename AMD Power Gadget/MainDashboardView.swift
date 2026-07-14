//
//  MainDashboardView.swift
//  AMD Power Gadget
//
//  Created by Droga (2026) — SwiftUI Tahoe Redesign
//  Refactored: 2026-07-13 — Extracted themes, visual effects, and tabs to separate modules
//  Optimized: 2026-07-14 — Lazy loading, performance improvements, code cleanup
//

import SwiftUI
import Charts
import Metal

struct MainDashboardView: View {
    @ObservedObject var model: TelemetryModel
    @AppStorage("disclaimer_accepted") private var disclaimerAccepted = false
    @State private var tempCheckboxChecked = false

    // Observe theme keys so Color.tahoe* (static UserDefaults reads) refresh app-wide when custom hex/opacity changes.
    @AppStorage("app_theme_preset") private var themePreset: String = AppTheme.tahoe.rawValue
    @AppStorage("custom_hex_card") private var themeCardHex: String = "#16213E"
    @AppStorage("custom_hex_cyan") private var themeCyanHex: String = "#4CC9F0"
    @AppStorage("custom_hex_orange") private var themeOrangeHex: String = "#FF8C00"
    @AppStorage("custom_hex_green") private var themeGreenHex: String = "#00FF7F"
    @AppStorage("custom_hex_purple") private var themePurpleHex: String = "#A020F0"

    /// Changes whenever any theme token changes → forces sidebar/content re-render with new colors.
    private var themeRevision: String {
        "\(themePreset)|\(themeCardHex)|\(themeCyanHex)|\(themeOrangeHex)|\(themeGreenHex)|\(themePurpleHex)"
    }

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                SidebarView(selectedTab: $model.selectedTab, model: model)
                    .frame(width: 188)
                    .id(themeRevision)
                Divider().background(Color.tahoeCardBorder)
                ZStack {
                    VisualEffectBackground(
                        material: .sidebar,
                        blendingMode: .behindWindow,
                        state: .active,
                        cornerRadius: 0
                    )
                    .ignoresSafeArea()
                    
                    if model.selectedTab == .themes {
                        contentForTab
                            .transition(.opacity)
                    } else {
                        contentForTab
                            .transition(.opacity)
                            .id(themeRevision)
                    }
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
            .safeAreaInset(edge: .top, spacing: 0) {
                if let msg = model.privilegeErrorMessage {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.shield.fill")
                            .foregroundColor(.orange)
                        Text(msg)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.tahoeText)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 8)
                        Button {
                            model.clearPrivilegeError()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.tahoeSubtext)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.orange.opacity(0.18))
                    .overlay(Rectangle().frame(height: 1).foregroundColor(Color.orange.opacity(0.35)), alignment: .bottom)
                }
            }
            
            // Safety Disclaimer Gatekeeper Modal Sheet Overlay
            if !disclaimerAccepted {
                ZStack {
                    // Dark blurred background locking the UI
                    VisualEffectBackground(
                        material: .hudWindow,
                        blendingMode: .behindWindow,
                        state: .active,
                        cornerRadius: 0
                    )
                    .ignoresSafeArea()
                    
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.shield.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.tahoeAccentOrange)
                            
                            Text(NSLocalizedString("SAFETY DISCLAIMER & LIABILITY AGREEMENT", comment: ""))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.tahoeText)
                        }
                        
                        ScrollView {
                            Text(NSLocalizedString("This software interacts directly with low-level CPU hardware registers, Model-Specific Registers (MSRs), and the System Management Unit (SMU) to control CPU voltages, frequencies, and power limits.\n\nIncorrect settings, unstable undervolting, or wrong configurations can cause system instability, data loss, kernel panics, or permanent hardware damage.\n\nBy continuing, you agree that absolute responsibility for any system instability, hardware damage, or alien invasion lies entirely with the user. The authors and contributors assume no liability whatsoever for any damage, loss, or side effects to your hardware, software, or personal property. Use at your own risk.", comment: ""))
                                .font(.system(size: 11))
                                .foregroundColor(.tahoeSubtext)
                                .lineSpacing(4)
                                .padding(12)
                        }
                        .frame(height: 160)
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.tahoeCardBorder))
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(isOn: $tempCheckboxChecked) {
                                Text(NSLocalizedString("I accept that absolute responsibility lies entirely with the user.", comment: ""))
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.tahoeText)
                            }
                            .toggleStyle(.checkbox)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                NSApplication.shared.terminate(nil)
                            }) {
                                Text(NSLocalizedString("Quit", comment: ""))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.tahoeText)
                                    .frame(width: 80, height: 26)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation {
                                    disclaimerAccepted = true
                                }
                            }) {
                                Text(NSLocalizedString("Accept & Continue", comment: ""))
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(tempCheckboxChecked ? .black : .tahoeSubtext)
                                    .frame(width: 140, height: 26)
                                    .background(tempCheckboxChecked ? Color.tahoeAccentOrange : Color.white.opacity(0.05))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                            .disabled(!tempCheckboxChecked)
                        }
                    }
                    .padding(24)
                    .frame(width: 460)
                    .background(Color.tahoeCard)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.tahoeCardBorder, lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.5), radius: 20)
                }
                .transition(.opacity)
            }
        }
    }

    @ViewBuilder
    private var contentForTab: some View {
        switch model.selectedTab {
        case .dashboard:  DashboardContentView(model: model)
        case .telemetry:  TelemetryContentView(model: model)
        case .fanControl: FanControlContentView(model: model)
        case .themes:     ThemesContentView()
        case .chartStyles: ChartStylesContentView()
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

                // Compact buttons stack
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Button(action: {
                            if let url = URL(string: "https://github.com/DrogaBox/SMCAMDProcessor-personal") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: "safari")
                                    .font(.system(size: 8))
                                Text("GitHub")
                            }
                        }
                        .buttonStyle(SidebarMiniButtonStyle(accent: .tahoeAccentCyan))

                        Button(action: {
                            Task { @MainActor in
                                if let url = Bundle.main.url(forResource: "bravo", withExtension: "mp3") {
                                    if let sound = NSSound(contentsOf: url, byReference: true) {
                                        sound.play()
                                    }
                                }
                            }
                            if let url = URL(string: "https://www.paypal.com/donate/?business=mrleisures@gmail.com") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 8))
                                Text("Donate")
                            }
                        }
                        .buttonStyle(SidebarMiniButtonStyle(accent: .tahoeAccentOrange))
                    }

                    if model.isCheckingForUpdates {
                        HStack(spacing: 4) {
                            ProgressView().scaleEffect(0.5).frame(width: 10, height: 10)
                            Text("Checking for updates...").font(.system(size: 8.5)).foregroundColor(.tahoeSubtext)
                        }
                        .padding(.horizontal, 6)
                    } else {
                        Button(action: {
                            if model.updateAvailable {
                                if let u = URL(string: model.releaseURLString) { NSWorkspace.shared.open(u) }
                            } else {
                                model.checkForUpdates(manual: true)
                            }
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: model.updateAvailable ? "arrow.down.circle" : "arrow.triangle.2.circlepath")
                                    .font(.system(size: 8))
                                Text(model.updateAvailable ? LocalizedStringKey("Download Update") : LocalizedStringKey("Check for Updates"))
                            }
                        }
                        .buttonStyle(SidebarMiniButtonStyle(accent: model.updateAvailable ? .tahoeAccentGreen : .tahoeAccentCyan))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 10)

                Link(destination: URL(string: "https://github.com/DrogaBox/SMCAMDProcessor-personal") ?? URL(fileURLWithPath: "/")) {
                    let appVer = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "3.13.3"
                    let kextVer = model.sysInfo.kextVersion.isEmpty ? "N/A" : model.sysInfo.kextVersion
                    Text("App: v\(appVer) • Kext: v\(kextVer) · macOS Tahoe")
                        .font(.system(size: 8.5, weight: .regular, design: .monospaced))
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
struct InfoRow: View {
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

// MARK: - Resizable Chart Wrapper with Right-Click Menu
// MARK: - Dashboard Tab (3 charts separados, tamaño configurable)

struct DashboardContentView: View {
    @ObservedObject var model: TelemetryModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var cfg = MenuBarConfig.shared
    
    // Visibility AppStorage
    @AppStorage("dash_showFreq") var showFrequency = true
    @AppStorage("dash_showTemp") var showTemperature = true
    @AppStorage("dash_showPwr") var showPower = true
    @AppStorage("dash_showCores") var showCores = true
    @AppStorage("mb_showNet") var showNetwork = false
    @AppStorage("mb_showMem") var showMemory = true
    
    // Order AppStorage
    @AppStorage("dash_chart_order") var chartOrder = "freq,temp,pwr"
    @AppStorage("dash_vertical_order") var verticalOrder = "charts,memory,network,cores"
    
    // Performance: Track visibility for lazy loading
    @State private var isChartsVisible = false
    @State private var isMemoryVisible = false
    @State private var isNetworkVisible = false
    @State private var isCoresVisible = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                StatCardsHeaderRow(model: model, colorScheme: colorScheme)

                let verticalItems = verticalOrder.split(separator: ",").map(String.init)
                ForEach(verticalItems, id: \.self) { itemId in
                    if itemId == "charts" {
                        if showFrequency || showTemperature || showPower {
                            HorizontalChartsContainer(model: model)
                                .trackVisibility { isChartsVisible = $0 }
                        }
                    } else if itemId == "memory" && showMemory {
                        ResizableChart(chartId: "dash_mem_size", small: 130, medium: 160, large: 220) { height in
                            MemoryCard(model: model)
                                .frame(height: height)
                                .trackVisibility { isMemoryVisible = $0 }
                        }
                    } else if itemId == "network" && showNetwork {
                        ResizableChart(chartId: "dash_net", small: 70, medium: 100, large: 150) { height in
                            NetworkLineChartCard(
                                title: "Network Throughput",
                                model: model,
                                height: height
                            )
                            .trackVisibility { isNetworkVisible = $0 }
                        }
                    } else if itemId == "cores" && showCores {
                        ResizableChart(chartId: "dash_cores_size", small: 300, medium: 400, large: 500) { height in
                            ScrollView {
                                CoreGridCard(model: model)
                            }
                            .frame(height: height)
                            .trackVisibility { isCoresVisible = $0 }
                        }
                    }
                }
            }
            .padding(18)
        }
    }
}

// MARK: - Dashboard Sub-views & Helper Extensions
struct StatCardsHeaderRow: View {
    @ObservedObject var model: TelemetryModel
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            StatCard(label: "CPU Temp",  value: String(format: "%.1f°C",   model.cpuTempC),     accent: PanelMetricColor.cyan(for: colorScheme),   icon: "thermometer.medium", history: model.cpuTempHistory)
            StatCard(label: "CPU Power", value: String(format: "%.1fW",    model.cpuWatts),     accent: PanelMetricColor.orange(for: colorScheme), icon: "bolt.fill", history: model.cpuPowerHistory)
            StatCard(label: "GPU Temp",  value: String(format: "%.1f°C",   model.gpuTempC),     accent: PanelMetricColor.green(for: colorScheme),  icon: "cpu.fill", history: model.gpuTempHistory)
            StatCard(label: "GPU Power", value: String(format: "%.1fW",    model.gpuPowerW),    accent: PanelMetricColor.pink(for: colorScheme),   icon: "bolt.square.fill", history: model.gpuPowerHistory)
        }
    }
}

struct HorizontalChartsContainer: View {
    @ObservedObject var model: TelemetryModel
    
    @AppStorage("dash_showFreq") var showFrequency = true
    @AppStorage("dash_showTemp") var showTemperature = true
    @AppStorage("dash_showPwr") var showPower = true
    @AppStorage("dash_showCores") var showCores = true
    @AppStorage("mb_showNet") var showNetwork = false
    @AppStorage("mb_showMem") var showMemory = true
    
    @AppStorage("dash_chart_order") var chartOrder = "freq,temp,pwr"
    
    var body: some View {
        let charts = chartOrder.split(separator: ",").map(String.init)
        HStack(alignment: .top, spacing: 12) {
            ForEach(charts, id: \.self) { chartId in
                if chartId == "freq" && showFrequency {
                    ResizableChart(chartId: "dash_freq", small: 70, medium: 100, large: 150) { height in
                        OriginalLineChartCard(
                            title: "Frequency",
                            accent: .tahoeAccentCyan,
                            unit: "GHz",
                            data: model.history,
                            line1: { $0.cpuFreqGHz },
                            line2: { $0.cpuFreqMaxGHz },
                            line1Label: "Avg",
                            line2Label: "Max",
                            height: height
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .layoutPriority(1)
                }
                if chartId == "temp" && showTemperature {
                    ResizableChart(chartId: "dash_temp", small: 70, medium: 100, large: 150) { height in
                        OriginalLineChartCard(
                            title: "Temperature",
                            accent: .tahoeAccentOrange,
                            unit: "°C",
                            data: model.history,
                            line1: { $0.cpuTempC },
                            line2: nil,
                            line1Label: "CPU",
                            line2Label: nil,
                            height: height
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .layoutPriority(1)
                }
                if chartId == "pwr" && showPower {
                    ResizableChart(chartId: "dash_pwr", small: 70, medium: 100, large: 150) { height in
                        OriginalLineChartCard(
                            title: "Power",
                            accent: .tahoeAccentGreen,
                            unit: "W",
                            data: model.history,
                            line1: { $0.cpuWatts },
                            line2: nil,
                            line1Label: "Package",
                            line2Label: nil,
                            height: height
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .layoutPriority(1)
                }
            }
        }
    }
}

private struct StatCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let label: LocalizedStringKey; let value: String; let accent: Color; let icon: String
    var history: MetricHistory? = nil
    
    var body: some View {
        TahoeCard(accent: accent.opacity(0.18)) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: icon).font(.system(size: 12)).foregroundColor(accent)
                    Text(label).font(.system(size: 11, weight: .medium)).foregroundColor(.tahoeSubtext)
                }
                Text(value).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(.tahoeText)
                
                if let h = history {
                    Sparkline(history: h, accent: accent)
                        .frame(height: 24)
                        .padding(.top, 4)
                }
            }
        }
    }
}

// MARK: - Original-style Line Chart Card
// MARK: - Telemetry Tab
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
struct CPPCCoreGridRow: View {
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

struct CPPCCoreGrid: View {
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


enum PopoverTab: Int, CaseIterable {
    case telemetry = 0
    case profiles = 1
    case settings = 2
}


// MARK: - Popover Config Tab
struct PopoverCoreGridView: View {
    @ObservedObject var model: TelemetryModel
    
    private var colCount: Int {
        let count = model.cores.count
        if count > 64 { return 12 }
        if count > 32 { return 10 }
        if count > 16 { return 8 }
        if count > 8  { return 6 }
        return 4
    }
    
    private var columns: [GridItem] {
        return Array(repeating: GridItem(.flexible(), spacing: 3), count: colCount)
    }
    
    private var cellHeight: CGFloat {
        let count = model.cores.count
        if count > 64 { return 14 }
        if count > 32 { return 18 }
        return 24
    }
    
    private var showTextLabels: Bool {
        return model.cores.count <= 32
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CPU Per-Core Thread Load")
                .font(.system(size: 9.5, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: columns, spacing: 3) {
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
                                    gradient: Gradient(colors: [Color.tahoeAccentCyan.opacity(0.85), Color.tahoeAccentPurple.opacity(0.9)]),
                                    startPoint: .bottom,
                                    endPoint: .top
                                ))
                                .frame(height: geo.size.height * CGFloat(core.loadPct / 100.0))
                            
                            // Labels (adaptive visibility for dense core layouts)
                            if showTextLabels {
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
                    }
                    .frame(height: cellHeight)
                    .help(String(format: "Thread %d: %.1f%%", core.id, core.loadPct))
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
    private var saveCounter = 0
    
    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        let appDir = appSupport.appendingPathComponent("AMD Power Gadget")
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        saveURL = appDir.appendingPathComponent("telemetry_history.json")
        
        loadData()
        startSampling()
    }
    
    private func loadData() {
        guard let data = try? Data(contentsOf: saveURL) else { return }
        let decoder = JSONDecoder()
        
        // Try decoding as JSON array first for backward compatibility
        if let array = try? decoder.decode([HistoryDataPoint].self, from: data) {
            historyData = array
            pruneOldData()
            rewriteFile() // Convert to JSON Lines format immediately
            return
        }
        
        // Otherwise, decode as JSON Lines
        var loadedPoints: [HistoryDataPoint] = []
        if let content = String(data: data, encoding: .utf8) {
            let lines = content.components(separatedBy: .newlines)
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }
                if let lineData = trimmed.data(using: .utf8),
                   let point = try? decoder.decode(HistoryDataPoint.self, from: lineData) {
                    loadedPoints.append(point)
                }
            }
        }
        historyData = loadedPoints
        pruneOldData()
    }
    
    private func rewriteFile() {
        do {
            let encoder = JSONEncoder()
            var fileData = Data()
            for pt in historyData {
                if let data = try? encoder.encode(pt) {
                    fileData.append(data)
                    if let nl = "\n".data(using: .utf8) {
                        fileData.append(nl)
                    }
                }
            }
            try fileData.write(to: saveURL, options: .atomic)
        } catch {
            NSLog("Failed to rewrite history: %@", error.localizedDescription)
        }
    }
    
    private func appendData(point: HistoryDataPoint) {
        do {
            if !FileManager.default.fileExists(atPath: saveURL.path) {
                rewriteFile()
                return
            }
            let encoder = JSONEncoder()
            let data = try encoder.encode(point)
            let fileHandle = try FileHandle(forWritingTo: saveURL)
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
            if let newline = "\n".data(using: .utf8) {
                fileHandle.write(newline)
            }
            fileHandle.closeFile()
        } catch {
            rewriteFile()
        }
    }
    
    func saveData() {
        pruneOldData()
        saveCounter += 1
        if saveCounter >= 60 {
            rewriteFile()
            saveCounter = 0
        } else {
            if let last = historyData.last {
                appendData(point: last)
            }
        }
    }

    /// Force a full rewrite (language relaunch / app quit paths).
    func flushToDisk() {
        pruneOldData()
        rewriteFile()
        saveCounter = 0
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
        Task { @MainActor in
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

struct InteractiveFanCurveEditor: View {
    @ObservedObject var model: TelemetryModel
    @State private var selectedCurveIndex: Int = 0
    @State private var hoveredPointIndex: Int? = nil
    
    var body: some View {
        guard selectedCurveIndex < model.customCurves.count else {
            return AnyView(Text("No curves configured."))
        }
        
        let curve = model.customCurves[selectedCurveIndex]
        
        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                // Curve Selector and Controls
                HStack(spacing: 8) {
                    Text("Curve").font(.system(size: 11, weight: .semibold)).foregroundColor(.tahoeSubtext)
                    Picker("", selection: $selectedCurveIndex) {
                        ForEach(0..<model.customCurves.count, id: \.self) { idx in
                            Text(model.customCurves[idx].name).tag(idx)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 160)
                    
                    TextField("Name", text: Binding(
                        get: { curve.name },
                        set: { newVal in
                            var updated = model.customCurves
                            updated[selectedCurveIndex].name = newVal
                            model.customCurves = updated
                        }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 120)
                    
                    Spacer()
                }
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Temp Source").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                        Picker("", selection: Binding(
                            get: { curve.sourceSensor },
                            set: { newVal in
                                var updated = model.customCurves
                                updated[selectedCurveIndex].sourceSensor = newVal
                                model.customCurves = updated
                            }
                        )) {
                            Text("CPU Temp").tag(0)
                            Text("GPU Temp").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 150)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Hysteresis").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                            Spacer()
                            Text("\(Int(curve.hysteresis))°C").font(.system(size: 10, weight: .bold)).foregroundColor(.tahoeAccentOrange)
                        }
                        Slider(value: Binding(
                            get: { curve.hysteresis },
                            set: { newVal in
                                var updated = model.customCurves
                                updated[selectedCurveIndex].hysteresis = newVal
                                model.customCurves = updated
                            }
                        ), in: 1...5, step: 1)
                        .accentColor(.tahoeAccentOrange)
                        .frame(width: 120)
                    }
                    .frame(width: 120)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Ramp Rate").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                            Spacer()
                            Text("\(Int(curve.rampRate))%/s").font(.system(size: 10, weight: .bold)).foregroundColor(.tahoeAccentOrange)
                        }
                        Slider(value: Binding(
                            get: { curve.rampRate },
                            set: { newVal in
                                var updated = model.customCurves
                                updated[selectedCurveIndex].rampRate = newVal
                                model.customCurves = updated
                            }
                        ), in: 1...20, step: 1)
                        .accentColor(.tahoeAccentOrange)
                        .frame(width: 120)
                    }
                    .frame(width: 120)
                }
                
                // 2D Graph Area
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height
                    
                    ZStack {
                        // Background Grid
                        Canvas { context, size in
                            let gridColor = Color.tahoeCardBorder.opacity(0.6)
                            
                            // Horizontal lines (PWM)
                            for i in 0...5 {
                                let y = CGFloat(i) * size.height / 5
                                var path = Path()
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: size.width, y: y))
                                context.stroke(path, with: .color(gridColor), style: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                                
                                // PWM Labels
                                let pwmPct = 100 - i * 20
                                if pwmPct > 0 {
                                    context.draw(Text("\(pwmPct)%").font(.system(size: 8)).foregroundColor(.tahoeSubtext), at: CGPoint(x: 12, y: y - 6), anchor: .leading)
                                }
                            }
                            
                            // Vertical lines (Temp)
                            for i in 0...5 {
                                let x = CGFloat(i) * size.width / 5
                                var path = Path()
                                path.move(to: CGPoint(x: x, y: 0))
                                path.addLine(to: CGPoint(x: x, y: size.height))
                                context.stroke(path, with: .color(gridColor), style: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                                
                                // Temp Labels
                                let tempC = i * 20
                                if tempC > 0 {
                                    context.draw(Text("\(tempC)°C").font(.system(size: 8)).foregroundColor(.tahoeSubtext), at: CGPoint(x: x + 2, y: size.height - 10), anchor: .leading)
                                }
                            }
                        }
                        
                        // Line Path connecting points
                        Path { path in
                            let sorted = curve.points.sorted { $0.temp < $1.temp }
                            guard let firstPt = sorted.first else { return }
                            
                            path.move(to: CGPoint(x: CGFloat(firstPt.temp / 100.0) * w, y: h - CGFloat(firstPt.pwm / 100.0) * h))
                            
                            for pt in sorted.dropFirst() {
                                path.addLine(to: CGPoint(x: CGFloat(pt.temp / 100.0) * w, y: h - CGFloat(pt.pwm / 100.0) * h))
                            }
                        }
                        .stroke(Color.tahoeAccentOrange, lineWidth: 2)
                        
                        // Interactive points
                        ForEach(curve.points.indices, id: \.self) { ptIdx in
                            let pt = curve.points[ptIdx]
                            let ptX = CGFloat(pt.temp / 100.0) * w
                            let ptY = h - CGFloat(pt.pwm / 100.0) * h
                            
                            Circle()
                                .fill(hoveredPointIndex == ptIdx ? Color.tahoeAccentCyan : Color.tahoeAccentOrange)
                                .frame(width: 10, height: 10)
                                .position(x: ptX, y: ptY)
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { val in
                                            let newX = max(0, min(w, val.location.x))
                                            let newY = max(0, min(h, val.location.y))
                                            
                                            var updated = model.customCurves
                                            updated[selectedCurveIndex].points[ptIdx].temp = Double(newX / w) * 100.0
                                            updated[selectedCurveIndex].points[ptIdx].pwm = Double((h - newY) / h) * 100.0
                                            model.customCurves = updated
                                        }
                                )
                                .onTapGesture(count: 2) {
                                    if curve.points.count > 2 {
                                        var updated = model.customCurves
                                        updated[selectedCurveIndex].points.remove(at: ptIdx)
                                        model.customCurves = updated
                                    }
                                }
                                .onHover { hovering in
                                    hoveredPointIndex = hovering ? ptIdx : nil
                                }
                                .contextMenu {
                                    Button("Delete Point") {
                                        if curve.points.count > 2 {
                                            var updated = model.customCurves
                                            updated[selectedCurveIndex].points.remove(at: ptIdx)
                                            model.customCurves = updated
                                        }
                                    }
                                }
                        }
                    }
                    .background(BlockWindowDragView())
                    .background(Color.tahoeCardBorder.opacity(0.1))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.tahoeCardBorder, lineWidth: 1)
                    )
                    .gesture(
                        SpatialTapGesture()
                            .onEnded { val in
                                let tapX = val.location.x
                                let tapY = val.location.y
                                
                                let tooClose = curve.points.contains { pt in
                                    let ptX = CGFloat(pt.temp / 100.0) * w
                                    let ptY = h - CGFloat(pt.pwm / 100.0) * h
                                    let dist = sqrt(pow(tapX - ptX, 2) + pow(tapY - ptY, 2))
                                    return dist < 12
                                }
                                
                                if !tooClose && curve.points.count < 8 {
                                    let newTemp = Double(tapX / w) * 100.0
                                    let newPWM = Double((h - tapY) / h) * 100.0
                                    var updated = model.customCurves
                                    updated[selectedCurveIndex].points.append(FanCurvePoint(temp: newTemp, pwm: newPWM))
                                    updated[selectedCurveIndex].points.sort { $0.temp < $1.temp }
                                    model.customCurves = updated
                                }
                            }
                    )
                }
                .frame(height: 180)
                
                Text("Drag control points to edit curve. Double-click empty space to add (max 8). Double-click a point or right-click to delete.")
                    .font(.system(size: 9)).foregroundColor(.tahoeSubtext)
            }
        )
    }
}

struct BlockWindowDragView: NSViewRepresentable {
    class BlockDragNSView: NSView {
        override var mouseDownCanMoveWindow: Bool { false }
    }
    func makeNSView(context: Context) -> BlockDragNSView {
        BlockDragNSView()
    }
    func updateNSView(_ nsView: BlockDragNSView, context: Context) {}
}

/// A small history graph: a filled area under a smooth polyline. Hand-drawn with
/// `Path` so the app needs no charting framework.
///
/// `maxValue` fixes the vertical scale (CPU/memory use 1.0 for an absolute 0–100%
/// reading); when nil the graph auto-scales to its own peak (network, power).
struct Sparkline: View {
    var history: MetricHistory
    var color: Color
    var maxValue: Double? = nil
    var fillOpacity: Double = 0.16
    var lineWidth: CGFloat = 1.5
    var showsZeroBaseline = false

    init(history: MetricHistory, accent: Color, maxValue: Double? = nil) {
        self.history = history
        self.color = accent
        self.maxValue = maxValue
    }

    var body: some View {
        GeometryReader { geometry in
            let baselineY = max(0.5, geometry.size.height - 0.5)
            let points = points(in: geometry.size, baselineY: baselineY)
            if points.count >= 2 {
                ZStack {
                    Path { path in
                        path.move(to: CGPoint(x: points[0].x, y: baselineY))
                        points.forEach { path.addLine(to: $0) }
                        path.addLine(to: CGPoint(x: points[points.count - 1].x, y: baselineY))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(colors: [color.opacity(fillOpacity), color.opacity(0)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    if showsZeroBaseline {
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: baselineY))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: baselineY))
                        }
                        .stroke(Color.secondary.opacity(0.28), lineWidth: 1)
                    }
                    Path { path in
                        path.move(to: points[0])
                        points.dropFirst().forEach { path.addLine(to: $0) }
                    }
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                }
            }
        }
    }

    private func points(in size: CGSize, baselineY: CGFloat) -> [CGPoint] {
        let values = history.values
        guard values.count >= 2 else { return [] }
        let peak = max(maxValue ?? (values.max() ?? 1), 0.0001)
        let topY: CGFloat = 0.5
        let plotHeight = max(1, baselineY - topY)
        let lastIndex = values.count - 1
        return values.enumerated().map { index, value in
            let x = size.width * CGFloat(index) / CGFloat(lastIndex)
            let normalized = min(1, max(0, value / peak))
            let y = baselineY - plotHeight * CGFloat(normalized)
            return CGPoint(x: x, y: y)
        }
    }
}

// MARK: - Premium Liquid Glass & Theme
/// Translucent HUD material behind floating panels.
struct HUDBackdrop: View {
    var cornerRadius: CGFloat = 0
    @AppStorage("low_performance_mode") private var isLowPerformanceMode = false

    var body: some View {
        if isLowPerformanceMode {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(red: 0.10, green: 0.10, blue: 0.12)) // Solid fallback
        } else {
            HUDBackdropNSView(cornerRadius: cornerRadius)
        }
    }
}

struct HUDBackdropNSView: NSViewRepresentable {
    var cornerRadius: CGFloat = 0

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        apply(to: view)
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        apply(to: nsView)
    }

    private func apply(to view: NSVisualEffectView) {
        view.wantsLayer = true
        view.layer?.cornerRadius = cornerRadius
        view.layer?.cornerCurve = .continuous
        view.layer?.masksToBounds = true
    }
}

enum Theme {
    static let spaceGradient = LinearGradient(
        colors: [Color(white: 0.10), Color(white: 0.04), Color.black],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

enum PanelMetricColor {
    static func green(for scheme: ColorScheme) -> Color { scheme == .light ? Color(red: 0.00, green: 0.44, blue: 0.18) : .green }
    static func cyan(for scheme: ColorScheme) -> Color { scheme == .light ? Color(red: 0.00, green: 0.43, blue: 0.54) : .cyan }
    static func mint(for scheme: ColorScheme) -> Color { scheme == .light ? Color(red: 0.00, green: 0.44, blue: 0.40) : .mint }
    static func yellow(for scheme: ColorScheme) -> Color { scheme == .light ? Color(red: 0.56, green: 0.36, blue: 0.00) : .yellow }
    static func red(for scheme: ColorScheme) -> Color { scheme == .light ? Color(red: 0.68, green: 0.08, blue: 0.10) : .red }
    static func orange(for scheme: ColorScheme) -> Color { scheme == .light ? Color(red: 0.68, green: 0.30, blue: 0.00) : .orange }
    static func pink(for scheme: ColorScheme) -> Color { scheme == .light ? Color(red: 0.68, green: 0.06, blue: 0.34) : .pink }
}

enum PanelSurface {
    static func baseFill(for scheme: ColorScheme) -> Color { scheme == .light ? Color.white.opacity(0.68) : Color.black.opacity(0.42) }
    static func cardFill(for scheme: ColorScheme) -> Color { scheme == .light ? Color.white.opacity(0.38) : Color.white.opacity(0.075) }
    static func controlFill(for scheme: ColorScheme) -> Color { scheme == .light ? Color.black.opacity(0.055) : Color.white.opacity(0.085) }
    static func border(for scheme: ColorScheme) -> Color { scheme == .light ? Color.black.opacity(0.09) : Color.white.opacity(0.11) }
}

extension View {
    func panelCard(scheme: ColorScheme) -> some View {
        self.padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(PanelSurface.cardFill(for: scheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(PanelSurface.border(for: scheme), lineWidth: 0.7)
            )
    }

    func panelGlassSurface(cornerRadius: CGFloat = 18, scheme: ColorScheme) -> some View {
        self.background(
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.regularMaterial)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(PanelSurface.baseFill(for: scheme))
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(PanelSurface.border(for: scheme), lineWidth: 0.8)
            }
        )
    }
}

// MARK: - MemoryCard (Memory details, Uptime, Battery)
struct MemoryCard: View {
    @ObservedObject var model: TelemetryModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        TahoeCard(accent: Color.tahoeCardBorder) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Memory")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.tahoeText)
                
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.tahoeSubtext)
                        Text("Pressure")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.tahoeSubtext)
                        
                        // Green dot + Normal badge
                        HStack(spacing: 4) {
                            Circle()
                                .fill(model.memoryPressureColor)
                                .frame(width: 5, height: 5)
                            Text(model.memoryPressure)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(model.memoryPressureColor)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(model.memoryPressureColor.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    let usedGB = (model.ramUsagePct / 100.0) * (Double(ProcessInfo.processInfo.physicalMemory) / (1024.0 * 1024.0 * 1024.0))
                    let totalRAM = Double(ProcessInfo.processInfo.physicalMemory) / (1024.0 * 1024.0 * 1024.0)
                    Text(String(format: "%.2f GB / %.0f GB", usedGB, totalRAM))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.tahoeText)
                }
                
                Sparkline(history: model.ramHistory, accent: .orange, maxValue: Double(ProcessInfo.processInfo.physicalMemory) / (1024.0 * 1024.0 * 1024.0))
                    .frame(maxHeight: .infinity)
                    .frame(minHeight: 20)
                    .padding(.top, 4)
                
                Divider().background(Color.tahoeCardBorder)
                
                HStack(spacing: 12) {
                    // Uptime
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                            .foregroundColor(.tahoeSubtext)
                        Text("Up for \(model.systemUptimeFormatted)")
                            .font(.system(size: 10))
                            .foregroundColor(.tahoeSubtext)
                    }
                    
                    Spacer()
                    
                    // Battery (if present)
                    if model.hasBattery {
                        HStack(spacing: 4) {
                            Image(systemName: model.batteryIsCharging ? "battery.100.bolt" : "battery.100")
                                .font(.system(size: 10))
                                .foregroundColor(.tahoeSubtext)
                            Text("Battery: \(model.batteryPercentage)%")
                                .font(.system(size: 10))
                                .foregroundColor(.tahoeSubtext)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "powerplug")
                                .font(.system(size: 10))
                                .foregroundColor(.tahoeSubtext)
                            Text("AC Power")
                                .font(.system(size: 10))
                                .foregroundColor(.tahoeSubtext)
                        }
                    }
                }
                .padding(.top, 2)
            }
        }
    }
}