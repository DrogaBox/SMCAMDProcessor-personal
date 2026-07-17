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

// MARK: - Reusable Components
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
        ZStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    StatCardsHeaderRow(model: model, colorScheme: colorScheme)
                    
                    // CPU Profile Badge
                    CPUProfileBadgeView(model: model)

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
            
            if !model.isSystemInfoLoaded {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading system info...")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.tahoeSubtext)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.tahoeBackground.opacity(0.7))
            }
        }
    }
}
}

