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
/// Presets aligned with RTL Wi-Fi Tahoe (`Theme.swift`) so both apps share the same look.
enum AppTheme: String, CaseIterable, Identifiable {
    case tahoe = "Tahoe Glass"           // = RTL "Power Gadget" palette
    case classic = "Classic Dark"        // RTL classic
    case midnight = "Midnight Blue"      // RTL midnight
    case ember = "Ember"                 // RTL ember
    case matrix = "Matrix"               // RTL matrix
    case rose = "Rose"                   // RTL rose
    case cyberpunk = "Cyberpunk Neon"
    case solarized = "Solarized Amber"
    case monochrome = "Monochrome Stealth"
    case nordic = "Nordic Frost"
    case custom = "Custom"
    
    var id: String { rawValue }

    /// Localized display name for UI (rawValue stays English for UserDefaults / Crowdin keys).
    var localizedName: String { NSLocalizedString(rawValue, comment: "App theme preset name") }

    static var current: AppTheme {
        if let raw = UserDefaults.standard.string(forKey: "app_theme_preset") {
            if raw == "Personalizado" || raw == "Mi Tema Custom" { return .custom }
            // Migrate old names
            if raw == "power" || raw == "Power Gadget" { return .tahoe }
            if let theme = AppTheme(rawValue: raw) {
                return theme
            }
        }
        return .tahoe
    }

    /// Notify menu-bar popover / widgets to rebuild hosting roots.
    static func postThemeChanged() {
        NotificationCenter.default.post(name: .init("AppThemeChanged"), object: nil)
    }

    var background: Color {
        switch self {
        case .tahoe: return Color(red: 0.08, green: 0.08, blue: 0.10)
        case .classic: return Color(red: 0.07, green: 0.08, blue: 0.11)
        case .midnight: return Color(red: 0.04, green: 0.06, blue: 0.14)
        case .ember: return Color(red: 0.10, green: 0.06, blue: 0.05)
        case .matrix: return Color(red: 0.02, green: 0.05, blue: 0.03)
        case .rose: return Color(red: 0.09, green: 0.05, blue: 0.10)
        case .cyberpunk: return Color(red: 0.06, green: 0.04, blue: 0.12)
        case .solarized: return Color(red: 0.08, green: 0.10, blue: 0.11)
        case .monochrome: return Color(red: 0.07, green: 0.07, blue: 0.07)
        case .nordic: return Color(red: 0.10, green: 0.13, blue: 0.16)
        case .custom:
            let hex = UserDefaults.standard.string(forKey: "custom_hex_card") ?? "#0A0A10"
            return (Color(hexString: hex) ?? Color(red: 0.08, green: 0.08, blue: 0.10)).opacity(1)
        }
    }

    var card: Color {
        switch self {
        // Match RTL ThemePalette.card (powerGadget / classic / …) with 0.15 opacity for premium glass translucency
        case .tahoe: return Color(red: 0.13, green: 0.13, blue: 0.16).opacity(0.15)
        case .classic: return Color(red: 0.12, green: 0.14, blue: 0.19).opacity(0.15)
        case .midnight: return Color(red: 0.08, green: 0.11, blue: 0.22).opacity(0.15)
        case .ember: return Color(red: 0.18, green: 0.11, blue: 0.09).opacity(0.15)
        case .matrix: return Color(red: 0.05, green: 0.10, blue: 0.07).opacity(0.15)
        case .rose: return Color(red: 0.16, green: 0.10, blue: 0.18).opacity(0.15)
        case .cyberpunk: return Color(red: 0.12, green: 0.08, blue: 0.22).opacity(0.15)
        case .solarized: return Color(red: 0.15, green: 0.18, blue: 0.20).opacity(0.15)
        case .monochrome: return Color(red: 0.12, green: 0.12, blue: 0.12).opacity(0.15)
        case .nordic: return Color(red: 0.18, green: 0.22, blue: 0.28).opacity(0.15)
        case .custom:
            let hex = UserDefaults.standard.string(forKey: "custom_hex_card") ?? "#16213E"
            return (Color(hexString: hex) ?? Color(red: 0.13, green: 0.13, blue: 0.16)).opacity(0.15)
        }
    }

    var cardBorder: Color {
        switch self {
        case .midnight: return Color(red: 0.35, green: 0.50, blue: 0.95).opacity(0.25)
        case .ember: return Color(red: 1.0, green: 0.45, blue: 0.20).opacity(0.22)
        case .matrix: return Color(red: 0.20, green: 0.90, blue: 0.40).opacity(0.22)
        case .rose: return Color(red: 1.0, green: 0.45, blue: 0.75).opacity(0.22)
        default: return Color.white.opacity(0.12)
        }
    }

    var accentCyan: Color {
        switch self {
        case .tahoe: return Color(red: 0.20, green: 0.88, blue: 0.98)   // RTL powerGadget
        case .classic: return Color(red: 0.0, green: 0.85, blue: 0.95)
        case .midnight: return Color(red: 0.35, green: 0.65, blue: 1.0)
        case .ember: return Color(red: 1.0, green: 0.72, blue: 0.35)
        case .matrix: return Color(red: 0.25, green: 1.0, blue: 0.55)
        case .rose: return Color(red: 1.0, green: 0.55, blue: 0.80)
        case .cyberpunk: return Color(red: 0.0, green: 0.96, blue: 1.0)
        case .solarized: return Color(red: 0.16, green: 0.63, blue: 0.60)
        case .monochrome: return Color(white: 0.90)
        case .nordic: return Color(red: 0.53, green: 0.75, blue: 0.82)
        case .custom:
            let hex = UserDefaults.standard.string(forKey: "custom_hex_cyan") ?? "#4CC9F0"
            return Color(hexString: hex) ?? Color(red: 0.20, green: 0.88, blue: 0.98)
        }
    }

    var accentOrange: Color {
        switch self {
        case .tahoe: return Color(red: 1.00, green: 0.42, blue: 0.38)
        case .classic: return Color(red: 1.0, green: 0.55, blue: 0.10)
        case .midnight: return Color(red: 1.0, green: 0.65, blue: 0.25)
        case .ember: return Color(red: 1.0, green: 0.48, blue: 0.12)
        case .matrix: return Color(red: 0.70, green: 0.95, blue: 0.30)
        case .rose: return Color(red: 1.0, green: 0.50, blue: 0.45)
        case .cyberpunk: return Color(red: 1.0, green: 0.16, blue: 0.43)
        case .solarized: return Color(red: 0.80, green: 0.29, blue: 0.09)
        case .monochrome: return Color(white: 0.70)
        case .nordic: return Color(red: 0.82, green: 0.53, blue: 0.44)
        case .custom:
            let hex = UserDefaults.standard.string(forKey: "custom_hex_orange") ?? "#FF8C00"
            return Color(hexString: hex) ?? Color(red: 1.0, green: 0.42, blue: 0.38)
        }
    }

    var accentGreen: Color {
        switch self {
        case .tahoe: return Color(red: 0.25, green: 0.92, blue: 0.48)
        case .classic: return Color(red: 0.10, green: 0.95, blue: 0.45)
        case .midnight: return Color(red: 0.30, green: 0.95, blue: 0.75)
        case .ember: return Color(red: 0.85, green: 0.90, blue: 0.35)
        case .matrix: return Color(red: 0.15, green: 0.98, blue: 0.40)
        case .rose: return Color(red: 0.55, green: 0.95, blue: 0.70)
        case .cyberpunk: return Color(red: 0.0, green: 1.0, blue: 0.5)
        case .solarized: return Color(red: 0.52, green: 0.60, blue: 0.0)
        case .monochrome: return Color(white: 0.80)
        case .nordic: return Color(red: 0.64, green: 0.75, blue: 0.55)
        case .custom:
            let hex = UserDefaults.standard.string(forKey: "custom_hex_green") ?? "#00FF7F"
            return Color(hexString: hex) ?? Color(red: 0.25, green: 0.92, blue: 0.48)
        }
    }

    var accentPurple: Color {
        switch self {
        case .tahoe: return Color(red: 0.72, green: 0.48, blue: 1.00)
        case .classic: return Color(red: 0.65, green: 0.40, blue: 1.0)
        case .midnight: return Color(red: 0.55, green: 0.45, blue: 1.0)
        case .ember: return Color(red: 1.0, green: 0.40, blue: 0.55)
        case .matrix: return Color(red: 0.40, green: 0.85, blue: 0.65)
        case .rose: return Color(red: 0.85, green: 0.40, blue: 1.0)
        case .cyberpunk: return Color(red: 0.75, green: 0.0, blue: 1.0)
        case .solarized: return Color(red: 0.82, green: 0.21, blue: 0.51)
        case .monochrome: return Color(white: 0.60)
        case .nordic: return Color(red: 0.71, green: 0.55, blue: 0.66)
        case .custom:
            let hex = UserDefaults.standard.string(forKey: "custom_hex_purple") ?? "#A020F0"
            return Color(hexString: hex) ?? Color(red: 0.72, green: 0.48, blue: 1.00)
        }
    }

    var accentRed: Color {
        switch self {
        case .ember: return Color(red: 1.0, green: 0.28, blue: 0.22)
        case .rose: return Color(red: 1.0, green: 0.30, blue: 0.45)
        case .midnight: return Color(red: 1.0, green: 0.40, blue: 0.50)
        default: return Color(red: 0.95, green: 0.28, blue: 0.32)
        }
    }

    var text: Color {
        switch self {
        case .matrix: return Color(red: 0.85, green: 1.0, blue: 0.90)
        case .ember: return Color(red: 1.0, green: 0.96, blue: 0.92)
        default: return Color.white.opacity(0.95)
        }
    }

    var subtext: Color {
        switch self {
        case .matrix: return Color(red: 0.45, green: 0.75, blue: 0.55)
        default: return Color.white.opacity(0.55)
        }
    }

    var glassOpacity: Double {
        switch self {
        case .tahoe: return 0.55
        case .classic: return 0.72
        case .midnight: return 0.65
        case .ember: return 0.50
        case .matrix: return 0.40
        case .rose: return 0.60
        default: return 0.55
        }
    }
}

private extension Color {
    static var tahoeBackground   : Color { AppTheme.current.background.opacity(0.88) }
    static var tahoeSidebar      : Color { AppTheme.current.background.opacity(0.35) }
    static var tahoeCard         : Color { AppTheme.current.card }
    static var tahoeCardBorder   : Color { AppTheme.current.cardBorder }
    static var tahoeAccentCyan   : Color { AppTheme.current.accentCyan }
    static var tahoeAccentOrange : Color { AppTheme.current.accentOrange }
    static var tahoeAccentGreen  : Color { AppTheme.current.accentGreen }
    static var tahoeAccentPurple : Color { AppTheme.current.accentPurple }
    static var tahoeAccentRed    : Color { AppTheme.current.accentRed }
    static var tahoeAccentBlue   : Color { Color(red: 0.35, green: 0.55, blue: 1.0) }
    static var tahoeAccentYellow : Color { Color(red: 1.0,  green: 0.80, blue: 0.20) }
    static var tahoeText         : Color { AppTheme.current.text }
    static var tahoeSubtext      : Color { AppTheme.current.subtext }
    static var tahoeSidebarActive : Color { AppTheme.current.card.opacity(0.9) }
}

enum DashboardTab: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    // rawValue is the English localization key (Crowdin source).
    case dashboard  = "Dashboard"
    case telemetry  = "Telemetry"
    case fanControl = "Fan Control"
    case themes     = "Themes & Appearance"
    case profiles   = "Profiles"
    case advanced   = "Advanced"
    case menuBar    = "Menu Bar"
    case popover    = "Popover Menu"
    case desktopWidgets = "Desktop Widgets"
    case systemInfo = "System Info"
    case analysis   = "Analysis"

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
            .id(themeRevision)
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
    // Keep cards in sync when custom theme opacity/hex is edited live
    @AppStorage("app_theme_preset") private var themePreset: String = AppTheme.tahoe.rawValue
    @AppStorage("custom_hex_card") private var cardHex: String = "#16213E"

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

    private var cardFill: Color {
        // Touch storage so SwiftUI invalidates this view when theme tokens change
        _ = themePreset
        _ = cardHex
        return Color.tahoeCard
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(cardFill)
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
    let label: LocalizedStringKey
    let detail: LocalizedStringKey
    @Binding var isOn: Bool
    let accent: Color
    var indented: Bool = false
    let onChange: (Bool) -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                // LocalizedStringKey looks up Localizable.strings — do not prefix labels with spaces.
                Text(label).font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                Text(detail).font(.system(size: 10)).foregroundColor(.tahoeSubtext)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: accent))
                .labelsHidden()
                .onChange(of: isOn) { newValue in onChange(newValue) }
        }
        .padding(.vertical, 8)
        .padding(.leading, indented ? 28 : 14)
        .padding(.trailing, 14)
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
            .onReceive(NotificationCenter.default.publisher(for: .init("DashboardLayoutChanged"))) { _ in
                let saved = UserDefaults.standard.double(forKey: "chart_h_\(chartId)")
                if saved > 0 {
                    currentHeight = CGFloat(saved)
                }
            }
    }

    private func setHeight(_ h: CGFloat) {
        currentHeight = h
        UserDefaults.standard.set(Double(h), forKey: "chart_h_\(chartId)")
    }
}

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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                StatCardsHeaderRow(model: model, colorScheme: colorScheme)

                let verticalItems = verticalOrder.split(separator: ",").map(String.init)
                ForEach(verticalItems, id: \.self) { itemId in
                    if itemId == "charts" {
                        if showFrequency || showTemperature || showPower {
                            HorizontalChartsContainer(model: model)
                        }
                    } else if itemId == "memory" && showMemory {
                        ResizableChart(chartId: "dash_mem_size", small: 100, medium: 140, large: 200) { height in
                            MemoryCard(model: model)
                                .frame(height: height)
                        }
                        .contextMenu { chartContextMenu(for: "memory") }
                    } else if itemId == "network" && showNetwork {
                        ResizableChart(chartId: "dash_net", small: 70, medium: 100, large: 150) { height in
                            NetworkLineChartCard(
                                title: "Network Throughput",
                                model: model,
                                height: height
                            )
                        }
                        .contextMenu { chartContextMenu(for: "network") }
                    } else if itemId == "cores" && showCores {
                        ResizableChart(chartId: "dash_cores_size", small: 120, medium: 200, large: 300) { height in
                            ScrollView {
                                CoreGridCard(model: model)
                            }
                            .frame(height: height)
                        }
                        .contextMenu { chartContextMenu(for: "cores") }
                    }
                }
            }
            .padding(18)
            .background(HUDBackdrop(cornerRadius: 18))
        }
    }
}

// MARK: - Dashboard Sub-views & Helper Extensions
extension DashboardContentView {
    @ViewBuilder
    func chartContextMenu(for chart: String) -> some View {
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

    func setChartHeight(for chart: String, heightType: String) {
        let key = "chart_h_dash_" + (chart == "memory" ? "mem_size" : chart == "cores" ? "cores_size" : chart)
        let actualHeight: CGFloat
        switch chart {
        case "memory":
            actualHeight = (heightType == "small") ? 100 : (heightType == "medium") ? 140 : 200
        case "cores":
            actualHeight = (heightType == "small") ? 120 : (heightType == "medium") ? 200 : 300
        default:
            actualHeight = (heightType == "small") ? 70 : (heightType == "medium") ? 100 : 150
        }
        UserDefaults.standard.set(Double(actualHeight), forKey: key)
        NotificationCenter.default.post(name: .init("DashboardLayoutChanged"), object: nil)
    }

    func setChartVisibility(for chart: String, visible: Bool) {
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

    func moveChart(_ chart: String, direction: Int) {
        var arr = verticalOrder.split(separator: ",").map(String.init)
        if let idx = arr.firstIndex(of: chart) {
            let newIdx = idx + direction
            if newIdx >= 0 && newIdx < arr.count {
                arr.swapAt(idx, newIdx)
                verticalOrder = arr.joined(separator: ",")
            }
        }
    }
}

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
                    }
                    .contextMenu { horizontalContextMenu(for: "freq") }
                    .frame(maxHeight: .infinity, alignment: .top)
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
                    }
                    .contextMenu { horizontalContextMenu(for: "temp") }
                    .frame(maxHeight: .infinity, alignment: .top)
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
                    }
                    .contextMenu { horizontalContextMenu(for: "pwr") }
                    .frame(maxHeight: .infinity, alignment: .top)
                }
            }
        }
    }

    @ViewBuilder
    private func horizontalContextMenu(for chart: String) -> some View {
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
            Button("Move Left") { moveChart(chart, direction: -1) }
            Button("Move Right") { moveChart(chart, direction: 1) }
        }
    }

    private func setChartHeight(for chart: String, heightType: String) {
        let key = "chart_h_dash_" + chart
        let actualHeight = (heightType == "small") ? 70 : (heightType == "medium") ? 100 : CGFloat(150)
        UserDefaults.standard.set(Double(actualHeight), forKey: key)
        NotificationCenter.default.post(name: .init("DashboardLayoutChanged"), object: nil)
    }

    private func setChartVisibility(for chart: String, visible: Bool) {
        switch chart {
        case "freq": showFrequency = visible
        case "temp": showTemperature = visible
        case "pwr": showPower = visible
        default: break
        }
    }

    private func moveChart(_ chart: String, direction: Int) {
        var arr = chartOrder.split(separator: ",").map(String.init)
        if let idx = arr.firstIndex(of: chart) {
            let newIdx = idx + direction
            if newIdx >= 0 && newIdx < arr.count {
                arr.swapAt(idx, newIdx)
                chartOrder = arr.joined(separator: ",")
            }
        }
    }
}

private struct StatCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let label: LocalizedStringKey; let value: String; let accent: Color; let icon: String
    var history: MetricHistory? = nil
    
    var body: some View {
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .panelCard(scheme: colorScheme)
    }
}

// MARK: - Original-style Line Chart Card
struct OriginalLineChartCard: View {
    let title: LocalizedStringKey
    let accent: Color
    let unit: String
    let data: [TelemetryPoint]
    let line1: (TelemetryPoint) -> Double
    let line2: ((TelemetryPoint) -> Double)?
    let line1Label: LocalizedStringKey
    let line2Label: LocalizedStringKey?
    let height: CGFloat

    @AppStorage(AppChartStyle.storageKey) private var selectedChartStyleRaw: String = AppChartStyle.line.rawValue
    private var selectedChartStyle: AppChartStyle { AppChartStyle.normalized(selectedChartStyleRaw) }

    private var averageVal: Double {
        let vals = data.map(line1)
        guard !vals.isEmpty else { return 0.0 }
        return vals.reduce(0, +) / Double(vals.count)
    }
    
    private var maxVal: Double {
        if let l2 = line2 {
            return data.map(l2).max() ?? 0.0
        }
        return data.map(line1).max() ?? 0.0
    }
    
    private var minVal: Double {
        return data.map(line1).min() ?? 0.0
    }
    
    private var averageString: String {
        let fmt = (unit == "GHz") ? "%.2f" : "%.1f"
        return String(format: "\(NSLocalizedString("Prom.", comment: "")): \(fmt) %@", averageVal, unit)
    }
    private var maxString: String {
        let fmt = (unit == "GHz") ? "%.2f" : "%.1f"
        return String(format: "\(NSLocalizedString("Máx.", comment: "")): \(fmt) %@", maxVal, unit)
    }
    private var minString: String {
        let fmt = (unit == "GHz") ? "%.2f" : "%.1f"
        return String(format: "\(NSLocalizedString("Mín.", comment: "")): \(fmt) %@", minVal, unit)
    }

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
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(averageString)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.tahoeSubtext)
                    Text(maxString)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.tahoeSubtext)
                    Text(minString)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.tahoeSubtext)
                }
            }

            if data.count > 1 {
                // Use indexed data so the chart always fills the width
                let indexedData = Array(data.enumerated())
                let maxIndex = Double(indexedData.count - 1)

                Chart(indexedData, id: \.offset) { index, pt in
                    if selectedChartStyle == .bar {
                        BarMark(
                            x: .value("Index", Double(index)),
                            y: .value(line1Label, line1(pt))
                        )
                        .foregroundStyle(accent)
                    } else if selectedChartStyle == .filledArea {
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
                    } else if selectedChartStyle == .steppedLine {
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
                    let strideValue = (unit == "GHz") ? max(0.1, (yMax - yMin) / 3.0) : max(1.0, (yMax - yMin) / 3.0)
                    AxisMarks(position: .leading, values: .stride(by: strideValue)) { val in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.08))
                        AxisValueLabel {
                            if let v = val.as(Double.self) {
                                let fmt = (unit == "GHz") ? "%.2f" : ((unit == "W") ? "%.1f" : "%.0f")
                                Text(String(format: fmt, v))
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
    @AppStorage("grid_show_load") private var gridShowLoad = true
    @AppStorage("grid_show_freq") private var gridShowFreq = true
    @AppStorage("grid_show_temp") private var gridShowTemp = true
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 8)

    /// Badge is about **hardware CPPC ranking**, not the Profiles “Active Mode (EPP)” toggle.
    private var cppcBadgeLabel: String {
        if model.cppcActiveMode {
            return NSLocalizedString("CPPC: EPP On", comment: "Core grid badge — Active Mode enabled")
        }
        if model.cppcScoresEstimated {
            return NSLocalizedString("CPPC: Estimated", comment: "Core grid badge — ranking estimated")
        }
        return NSLocalizedString("CPPC: HW OK", comment: "Core grid badge — hardware CPPC scores present, EPP mode may still be off")
    }

    private var cppcBadgeHelp: String {
        if model.cppcActiveMode {
            return NSLocalizedString(
                "Native CPPC Active Mode (EPP) is ON. Cores scale autonomously; rankings come from the processor.",
                comment: ""
            )
        }
        if model.cppcScoresEstimated {
            return NSLocalizedString(
                "CPPC hardware scores could not be read. Rankings are estimated from observed clocks. This is not the Profiles EPP toggle.",
                comment: ""
            )
        }
        return NSLocalizedString(
            "The CPU reports CPPC rankings (HW OK). That does not mean Active Mode is on — enable “Native CPPC Active Mode (EPP)” under Profiles (needs -amdpnopchk or root).",
            comment: ""
        )
    }

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

    /// Checkbox + single-line label that never compresses into per-character wrapping.
    @ViewBuilder
    private func gridHUDToggle(_ key: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(NSLocalizedString(key, comment: "Core grid HUD metric toggle"))
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.tahoeSubtext)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .toggleStyle(.checkbox)
        .fixedSize(horizontal: true, vertical: false)
    }

    var body: some View {
        TahoeCard {
            // Two-row header: title on top; controls on a single non-wrapping row.
            // (One cramped HStack was breaking ES labels into "Te mp ." / "Fr ec .")
            VStack(alignment: .leading, spacing: 8) {
                SectionTitle("Current Utilization — \(model.sysInfo.logicalCores) Threads (\(model.sysInfo.physicalCores) Cores)")

                HStack(alignment: .center, spacing: 12) {
                    HStack(spacing: 12) {
                        gridHUDToggle("Temp", isOn: $gridShowTemp)
                        gridHUDToggle("Freq", isOn: $gridShowFreq)
                        gridHUDToggle("Load", isOn: $gridShowLoad)
                    }

                    Spacer(minLength: 8)

                    Toggle(isOn: $sortCoresByRanking) {
                        Text(NSLocalizedString("Sort by Rank", comment: ""))
                            .font(.system(size: 10, weight: .semibold))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentBlue))
                    .fixedSize(horizontal: true, vertical: false)

                    if model.cppcSupported {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 9))
                                .foregroundColor(model.cppcActiveMode ? .tahoeAccentGreen : (model.cppcScoresEstimated ? .tahoeAccentOrange : .tahoeAccentCyan))
                            Text(cppcBadgeLabel)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(model.cppcActiveMode ? .tahoeAccentGreen : (model.cppcScoresEstimated ? .tahoeAccentOrange : .tahoeAccentCyan))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                            if model.cppcScoresEstimated {
                                Text("~")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.tahoeAccentOrange)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(4)
                        .help(cppcBadgeHelp)
                        .fixedSize(horizontal: true, vertical: false)
                    }
                }
            }
            .padding(.bottom, 4)

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(displayCores) { core in
                    CoreCell(
                        core: core,
                        ccdTemperatures: model.ccdTemperatures,
                        physicalCoresCount: model.sysInfo.physicalCores,
                        showRanking: sortCoresByRanking,
                        showLoad: gridShowLoad,
                        showFreq: gridShowFreq,
                        showTemp: gridShowTemp
                    )
                }
            }
        }
    }
}

private struct CoreCell: View {
    let core: CoreSnapshot
    let ccdTemperatures: [Float]
    let physicalCoresCount: Int
    let showRanking: Bool
    let showLoad: Bool
    let showFreq: Bool
    let showTemp: Bool

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
                if showLoad {
                    Spacer()
                    Text(String(format: "%.0f%%", core.loadPct))
                        .font(.system(size: 10, weight: .bold, design: .rounded)).foregroundColor(loadColor)
                }
            }

            if showLoad {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.06)).frame(height: 3)
                        Capsule().fill(loadColor)
                            .frame(width: geo.size.width * CGFloat(core.loadPct / 100.0), height: 3)
                            .shadow(color: loadColor.opacity(0.7), radius: 2)
                    }
                }
                .frame(height: 3)
            }

            if showFreq || showTemp {
                HStack {
                    if showFreq {
                        Text(String(format: "%.0f MHz", core.freqMHz))
                            .font(.system(size: 8, design: .monospaced)).foregroundColor(.tahoeSubtext)
                    }
                    
                    let limitPhys = physicalCoresCount > 0 ? physicalCoresCount : 16
                    let ccdIdx = (core.id % limitPhys) / 8
                    
                    if showFreq && showTemp && ccdTemperatures.count > ccdIdx {
                        Spacer()
                    }
                    
                    if showTemp {
                        if ccdTemperatures.count > ccdIdx {
                            Text(String(format: "%.0f°C", ccdTemperatures[ccdIdx]))
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.tahoeAccentRed)
                        }
                    }
                }
            }
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
                    HStack {
                        SectionTitle("SMC Fan Control")
                        Spacer()
                        if !model.hiddenFanIDs.isEmpty {
                            Button(action: {
                                model.hiddenFanIDs.removeAll()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "eye.fill")
                                    Text(String(format: NSLocalizedString("Show All (%d hidden)", comment: ""), model.hiddenFanIDs.count))
                                }
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.tahoeAccentCyan)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    ForEach(model.fans.filter { !model.hiddenFanIDs.contains($0.id) }) { fan in
                        FanControlCard(fan: fan, model: model)
                    }
                    HStack(spacing: 10) {
                        TahoeButton(label: "All Auto", icon: "arrow.circlepath", accent: .tahoeAccentCyan) { model.setAllFansAuto() }
                        TahoeButton(label: "Max Speed", icon: "wind", accent: .tahoeAccentOrange) { model.setAllFansTakeOff() }
                    }
                    
                    Divider().background(Color.tahoeCardBorder)
                    
                    SectionTitle("Closed-Loop Custom Fan Curves & Protection")
                    TahoeCard(accent: Color.tahoeAccentOrange.opacity(0.2)) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Dynamic Next-Gen Fan Curves").font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                                    Text("Evaluated in the kernel with 256-step LUT interpolation, hysteresis, and smooth ramping.").font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                                }
                                Spacer()
                                Toggle("", isOn: $model.autoFanCurveEnabled)
                                    .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentOrange)).labelsHidden()
                            }
                            if model.autoFanCurveEnabled {
                                Divider().background(Color.white.opacity(0.1))
                                InteractiveFanCurveEditor(model: model)
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
                    
                    Text("Standard Hackintosh Solution:")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.tahoeText)
                        .padding(.top, 4)
                    Text("The only way to modify this behavior (like forcing fans to spin at lower temperatures or disabling Zero RPM) is by exporting the vBIOS, creating a Soft PowerPlay Table (SPPT), and injecting it via OpenCore's config.plist under DeviceProperties.")
                        .font(.system(size: 11.5))
                        .foregroundColor(.tahoeSubtext)
                        .lineSpacing(4)
                    
                    HStack(spacing: 10) {
                        TahoeButton(label: "Open SPPT Guide", icon: "safari", accent: .tahoeAccentCyan) {
                            if let url = URL(string: "https://github.com/perez987/6600XT-on-macOS-with-softPowerPlayTable") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        TahoeButton(label: "MorePowerTool", icon: "arrow.down.circle", accent: .tahoeAccentOrange) {
                            if let url = URL(string: "https://www.igorslab.de/en/red-bios-editor-and-morepowertool-adjust-and-optimize-your-radeon-rx-5700-xt-and-radeon-vii-bios-instructions-and-downloads/") {
                                NSWorkspace.shared.open(url)
                            }
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
        let isMappedToCurve = (model.fanMappings[fan.id] ?? -1) != -1
        let mappedCurveIdx = model.fanMappings[fan.id] ?? -1
        let curveName = mappedCurveIdx >= 0 && mappedCurveIdx < model.customCurves.count ? model.customCurves[mappedCurveIdx].name : "Unknown"
        
        TahoeCard(accent: fan.isOverrided ? Color.tahoeAccentOrange.opacity(0.4) : Color.tahoeCardBorder) {
            HStack {
                Image(systemName: "fan").foregroundColor(.tahoeAccentCyan).font(.system(size: 14))
                TextField("", text: Binding(
                    get: { model.customFanNames[fan.id] ?? (fan.name.isEmpty ? "Fan \(fan.id + 1)" : fan.name) },
                    set: { newVal in
                        var updated = model.customFanNames
                        updated[fan.id] = newVal
                        model.customFanNames = updated
                    }
                ))
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.tahoeText)
                .frame(width: 150)
                Spacer()
                HStack(spacing: 6) {
                    Text("\(fan.rpm) RPM").font(.system(size: 11, design: .monospaced)).foregroundColor(.tahoeAccentCyan)
                    Text("·").foregroundColor(.tahoeSubtext)
                    Text(String(format: "%.0f%%", Double(fan.throttle) / 255.0 * 100.0))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(fan.isOverrided ? .tahoeAccentOrange : .tahoeSubtext)
                    Text("·").foregroundColor(.tahoeSubtext)
                    Button(action: {
                        model.hiddenFanIDs.insert(fan.id)
                    }) {
                        Image(systemName: "eye.slash")
                            .foregroundColor(.tahoeSubtext)
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    .help("Hide this fan")
                }
            }
            HStack {
                Text("Control Mode").font(.system(size: 11)).foregroundColor(.tahoeSubtext)
                Spacer()
                Picker("", selection: Binding(
                    get: { model.fanMappings[fan.id] ?? -1 },
                    set: { newVal in
                        var updated = model.fanMappings
                        updated[fan.id] = newVal
                        model.fanMappings = updated
                    }
                )) {
                    Text("BIOS / Auto").tag(-1)
                    ForEach(0..<model.customCurves.count, id: \.self) { idx in
                        Text(model.customCurves[idx].name).tag(idx)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
            
            if isMappedToCurve {
                HStack {
                    Spacer()
                    Text("Controlled by Curve: \(curveName)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.tahoeAccentOrange)
                }
            } else {
                HStack(spacing: 12) {
                    Text("Manual Override").font(.system(size: 11)).foregroundColor(.tahoeSubtext)
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
        }
        .onAppear { sliderValue = Double(fan.throttle) }
        .onChange(of: fan.throttle) { newVal in sliderValue = Double(newVal) }
    }
}

// MARK: - Profiles Tab
struct ProfilesContentView: View {
    @ObservedObject var model: TelemetryModel
    @State private var isCurveOptimizerUnlocked = false
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
                // Note: Dashboard badge "CPPC: HW OK" ≠ this toggle. Badge = hardware scores; toggle = EPP Active Mode.
                TahoeCard(accent: Color.tahoeAccentCyan.opacity(0.15)) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(NSLocalizedString("Native CPPC Active Mode (EPP)", comment: ""))
                                    .font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                                Text(NSLocalizedString("Enables autonomous hardware frequency scaling (recommended)", comment: ""))
                                    .font(.system(size: 10)).foregroundColor(.tahoeSubtext)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { model.cppcActiveMode },
                                set: { model.setCPPCActiveMode(active: $0) }
                            ))
                            .toggleStyle(SwitchToggleStyle(tint: .tahoeAccentCyan))
                            .labelsHidden()
                            // Keep toggle usable when kext is up (do not lock on false-negative support).
                            .disabled(!model.smcDriverLoaded)
                        }
                        if !model.smcDriverLoaded {
                            Text(NSLocalizedString("AMDRyzenCPUPowerManagement kext not connected.", comment: ""))
                                .font(.system(size: 10)).foregroundColor(.tahoeAccentOrange)
                        } else if !model.cppcSupported && !model.cppcActiveMode {
                            // Only if truly unsupported *and* Active is off (never when -amdcppcactive is live).
                            Text(NSLocalizedString("This CPU did not report CPPC support to the kext.", comment: ""))
                                .font(.system(size: 10)).foregroundColor(.tahoeAccentOrange)
                        } else if !model.cppcActiveMode {
                            Text(NSLocalizedString(
                                "If the switch snaps back to Off: enable writes with boot-arg -amdpnopchk (or run as root). With -amdcppcactive the kext enables Active Mode at boot after reboot.",
                                comment: "CPPC Active Mode help"
                            ))
                            .font(.system(size: 10))
                            .foregroundColor(.tahoeSubtext)
                            .fixedSize(horizontal: false, vertical: true)
                        }
                        if let err = model.privilegeErrorMessage {
                            Text(err)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.tahoeAccentOrange)
                                .fixedSize(horizontal: false, vertical: true)
                        }
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
                
                SectionTitle("AMD Curve Optimizer (CO)")
                Text("Inject positive or negative voltage offsets per core. Center is 0 (no override). Limit: -30 (undervolt) to +30 (overvolt) counts.")
                    .font(.system(size: 11)).foregroundColor(.tahoeSubtext)
                
                TahoeCard(accent: Color.tahoeAccentPurple.opacity(0.15)) {
                    if model.curveOptimizerOffsets.isEmpty {
                        Text("Curve Optimizer is only active when the AMDRyzenCPUPowerManagement kext supports Zen 3 SMU mailbox interface.")
                            .font(.system(size: 11, weight: .medium)).foregroundColor(.tahoeSubtext)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                    } else {
                        VStack(alignment: .leading, spacing: 14) {
                            // Safety unlock toggle
                            HStack(spacing: 10) {
                                Image(systemName: isCurveOptimizerUnlocked ? "lock.open.trianglebadge.exclamationmark.fill" : "lock.fill")
                                    .foregroundColor(isCurveOptimizerUnlocked ? .tahoeAccentPurple : .tahoeAccentOrange)
                                    .font(.system(size: 14))
                                
                                Toggle("Unlock Curve Optimizer (DANGEROUS: unstable undervolting can cause kernel panic or instant reboot)", isOn: $isCurveOptimizerUnlocked)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(isCurveOptimizerUnlocked ? .tahoeText : .tahoeAccentOrange)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(isCurveOptimizerUnlocked ? Color.tahoeAccentPurple.opacity(0.06) : Color.tahoeAccentOrange.opacity(0.08))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isCurveOptimizerUnlocked ? Color.tahoeAccentPurple.opacity(0.2) : Color.tahoeAccentOrange.opacity(0.2), lineWidth: 1)
                            )
                            
                            if isCurveOptimizerUnlocked {
                                let activeCoreCount = model.numPhysicalCores > 0 ? model.numPhysicalCores : (model.cores.isEmpty ? 16 : model.cores.count / 2)
                                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 12) {
                                    ForEach(0..<min(model.curveOptimizerOffsets.count, activeCoreCount), id: \.self) { idx in
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text("Core \(idx)").font(.system(size: 11, weight: .semibold)).foregroundColor(.tahoeText)
                                                Spacer()
                                                
                                                // Live feedback metrics
                                                if let core = model.cores.first(where: { $0.id == idx }) {
                                                    HStack(spacing: 6) {
                                                        let freqGHz = Double(core.freqMHz) / 1000.0
                                                        Text(String(format: "%.2f GHz", freqGHz))
                                                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                                            .foregroundColor(.tahoeAccentCyan)
                                                        
                                                        Text(String(format: "%.0f%%", core.loadPct))
                                                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                                            .foregroundColor(.tahoeAccentOrange)
                                                        
                                                        let ccdIdx = idx / 8
                                                        if model.ccdTemperatures.count > ccdIdx {
                                                            Text(String(format: "%.0f°C", model.ccdTemperatures[ccdIdx]))
                                                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                                                .foregroundColor(.tahoeAccentRed)
                                                        }
                                                    }
                                                    .padding(.trailing, 8)
                                                }
                                                
                                                let currentOffset = idx < model.curveOptimizerOffsets.count ? model.curveOptimizerOffsets[idx] : 0
                                                Text(currentOffset > 0 ? "+\(currentOffset)" : "\(currentOffset)")
                                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                                    .foregroundColor(currentOffset < 0 ? .tahoeAccentPurple : (currentOffset > 0 ? .tahoeAccentOrange : .tahoeSubtext))
                                            }
                                            
                                            let currentOffset = idx < model.curveOptimizerOffsets.count ? Double(model.curveOptimizerOffsets[idx]) : 0.0
                                            Slider(value: Binding(get: {
                                                return currentOffset
                                            }, set: { (val: Double) in
                                                let offsetInt = Int(round(val))
                                                let _ = model.setCurveOptimizerOffset(core: idx, offset: offsetInt)
                                            }), in: -30...30, step: 1)
                                            .accentColor(.tahoeAccentPurple)
                                        }
                                        .padding(8)
                                        .background(Color.white.opacity(0.02))
                                        .cornerRadius(6)
                                    }
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .animation(.easeInOut(duration: 0.25), value: isCurveOptimizerUnlocked)
                    }
                }
                
                Text("DISCLAIMER: This software interacts directly with low-level hardware control registers. By using it, you agree that absolute responsibility for any system instability, hardware damage, or alien invasion lies entirely with the user.")
                    .font(.system(size: 9))
                    .foregroundColor(.tahoeSubtext)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
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
                                Text(model.updateCheckMessage.isEmpty ? "Current installed version: v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?")" : model.updateCheckMessage)
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
                
                Text("DISCLAIMER: This software interacts directly with low-level hardware control registers. By using it, you agree that absolute responsibility for any system instability, hardware damage, or alien invasion lies entirely with the user.")
                    .font(.system(size: 9))
                    .foregroundColor(.tahoeSubtext)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
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
                    ToggleRow(label: "Show Max Freq Only", detail: "Single large value instead of max/avg stack", isOn: .init(
                        get: { cfg.showMaxFreqOnly }, set: { cfg.showMaxFreqOnly = $0; notify() }
                    ), accent: .tahoeAccentCyan.opacity(0.8), indented: true) { _ in }
                }

                ToggleRow(label: "Show Temperature", detail: "CPU temp + optional GPU temp", isOn: .init(
                    get: { cfg.showTemp }, set: { cfg.showTemp = $0; notify() }
                ), accent: .tahoeAccentOrange) { _ in }

                if cfg.showTemp {
                    ToggleRow(label: "Use Fahrenheit", detail: "Convert temperature values from Celsius to Fahrenheit", isOn: .init(
                        get: { cfg.useFahrenheit }, set: { cfg.useFahrenheit = $0; notify() }
                    ), accent: .tahoeAccentOrange.opacity(0.8), indented: true) { _ in }
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
    // Observe custom tokens so the "Custom" tile preview updates with opacity/hex edits
    @AppStorage("custom_hex_card") private var customCardHex: String = "#16213E"
    @AppStorage("custom_hex_cyan") private var customCyanHex: String = "#4CC9F0"
    @AppStorage("custom_hex_orange") private var customOrangeHex: String = "#FF8C00"
    @AppStorage("custom_hex_green") private var customGreenHex: String = "#00FF7F"
    @AppStorage("custom_hex_purple") private var customPurpleHex: String = "#A020F0"
    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        // Touch custom hex so body re-evaluates when editor pushes ARGB
        let _ = (customCardHex, customCyanHex, customOrangeHex, customGreenHex, customPurpleHex)
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(AppTheme.allCases) { theme in
                let isSelected = selectedThemeRaw == theme.rawValue
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedThemeRaw = theme.rawValue
                        AppTheme.postThemeChanged()
                    }
                }) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(theme.localizedName)
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
    /// Stable **English** storage keys (legacy Spanish prefs are migrated in `normalized` / `migrateStoredPreference`).
    case line = "Smooth Curves"
    case filledArea = "Filled Area"
    case bar = "Column Bars"
    case steppedLine = "Line Only"

    static let storageKey = "app_chart_style"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .line: return "waveform.path.ecg"
        case .filledArea: return "chart.area.fill"
        case .bar: return "chart.bar.fill"
        case .steppedLine: return "chart.line.uptrend.xyaxis"
        }
    }

    /// Display name always follows app language via Localizable.strings (key = English rawValue).
    var localizedName: String { NSLocalizedString(rawValue, comment: "Chart rendering style") }

    /// Map legacy Spanish storage values (and English keys) to current cases.
    static func normalized(_ stored: String) -> AppChartStyle {
        switch stored {
        case line.rawValue, "Línea Suave (Spline)", "Linea Suave (Spline)":
            return .line
        case filledArea.rawValue, "Área Rellena (Gradient)", "Area Rellena (Gradient)":
            return .filledArea
        case bar.rawValue, "Histograma de Barras":
            return .bar
        case steppedLine.rawValue, "Línea Escalonada (Step)", "Linea Escalonada (Step)":
            return .steppedLine
        default:
            return AppChartStyle(rawValue: stored) ?? .line
        }
    }

    /// Rewrite UserDefaults if an old Spanish (or unknown) value is still stored.
    /// Call once at launch so UI never re-surfaces Spanish chart style keys.
    @discardableResult
    static func migrateStoredPreference(defaults: UserDefaults = .standard) -> AppChartStyle {
        let stored = defaults.string(forKey: storageKey) ?? line.rawValue
        let style = normalized(stored)
        if stored != style.rawValue {
            defaults.set(style.rawValue, forKey: storageKey)
        }
        return style
    }
}

struct ChartStyleSelectorGrid: View {
    @AppStorage(AppChartStyle.storageKey) private var selectedStyleRaw: String = AppChartStyle.line.rawValue
    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 12)]

    private var selectedStyle: AppChartStyle {
        AppChartStyle.normalized(selectedStyleRaw)
    }

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
                            .foregroundColor(selectedStyle == style ? Color.tahoeAccentCyan : .tahoeSubtext)
                        Text(style.localizedName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(selectedStyle == style ? .white : .tahoeSubtext)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(selectedStyle == style ? Color.white.opacity(0.1) : Color.white.opacity(0.03))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(selectedStyle == style ? Color.tahoeAccentCyan : Color.clear, lineWidth: 1)
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
        .onAppear {
            // Persist English keys if user still has Spanish chart style prefs.
            let style = AppChartStyle.migrateStoredPreference()
            if selectedStyleRaw != style.rawValue {
                selectedStyleRaw = style.rawValue
            }
        }
    }
}

extension Color {
    /// Parses `#RGB`, `#RRGGBB`, or `#AARRGGBB` (alpha first when 8 digits).
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

    /// sRGB components in 0…1. Prefer this over repeated NSColor conversions in bindings.
    var resolvedRGBA: (r: Double, g: Double, b: Double, a: Double) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        let ns = NSColor(self)
        if let srgb = ns.usingColorSpace(.sRGB) {
            srgb.getRed(&r, green: &g, blue: &b, alpha: &a)
        } else if let device = ns.usingColorSpace(.deviceRGB) {
            device.getRed(&r, green: &g, blue: &b, alpha: &a)
        } else if ns.type == .componentBased {
            ns.getRed(&r, green: &g, blue: &b, alpha: &a)
        }
        return (
            r: Double(min(max(r, 0), 1)),
            g: Double(min(max(g, 0), 1)),
            b: Double(min(max(b, 0), 1)),
            a: Double(min(max(a, 0), 1))
        )
    }

    /// Same RGB, new alpha (0…1).
    func withResolvedAlpha(_ alpha: Double) -> Color {
        let c = resolvedRGBA
        return Color(.sRGB, red: c.r, green: c.g, blue: c.b, opacity: min(max(alpha, 0), 1))
    }

    /// Opaque `#RRGGBB`, translucent `#AARRGGBB` (alpha first).
    var toHexString: String {
        let c = resolvedRGBA
        let ri = Int((c.r * 255).rounded())
        let gi = Int((c.g * 255).rounded())
        let bi = Int((c.b * 255).rounded())
        let ai = Int((c.a * 255).rounded())
        if ai < 255 {
            return String(format: "#%02X%02X%02X%02X", ai, ri, gi, bi)
        }
        return String(format: "#%02X%02X%02X", ri, gi, bi)
    }

    /// Always `#AARRGGBB` — used by the theme editor so opacity never drops on save.
    var toHexStringARGB: String {
        let c = resolvedRGBA
        let ri = Int((c.r * 255).rounded())
        let gi = Int((c.g * 255).rounded())
        let bi = Int((c.b * 255).rounded())
        let ai = Int((c.a * 255).rounded())
        return String(format: "#%02X%02X%02X%02X", ai, ri, gi, bi)
    }

    /// Build sRGB color from components without going through NSColorPicker quirks.
    static func srgb(r: Double, g: Double, b: Double, a: Double) -> Color {
        Color(.sRGB,
              red: min(max(r, 0), 1),
              green: min(max(g, 0), 1),
              blue: min(max(b, 0), 1),
              opacity: min(max(a, 0), 1))
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

/// Theme color editor with a **stable local Color** + **explicit opacity slider**.
/// Binding ColorPicker directly to hex re-encoding fights the macOS panel and resets alpha to 100%.
struct ColorTokenEditorSlot: View {
    let title: LocalizedStringKey
    @Binding var hex: String
    var onEdited: () -> Void = {}

    /// Local draft — ColorPicker writes here; we push ARGB hex outward.
    @State private var draftRGB: Color = .white
    @State private var opacity: Double = 1.0
    @State private var suppressPush = false

    private var preview: Color {
        let c = draftRGB.resolvedRGBA
        return Color.srgb(r: c.r, g: c.g, b: c.b, a: opacity)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.tahoeSubtext)

            HStack(spacing: 8) {
                // Opacity handled by the slider below — avoids macOS ColorPanel alpha reset
                ColorPicker("", selection: $draftRGB, supportsOpacity: false)
                    .labelsHidden()
                    .onChange(of: draftRGB) { _ in
                        guard !suppressPush else { return }
                        pushHex(userEdit: true)
                    }

                // Live swatch with current opacity
                RoundedRectangle(cornerRadius: 4)
                    .fill(preview)
                    .frame(width: 22, height: 22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
                    .background(
                        // Checkerboard hint for transparency
                        CheckerboardBackground()
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .frame(width: 22, height: 22)
                    )

                Text(hex)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }

            HStack(spacing: 8) {
                Text("Opacity")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.tahoeSubtext)
                    .frame(width: 48, alignment: .leading)
                Slider(value: $opacity, in: 0...1)
                    .controlSize(.small)
                    .onChange(of: opacity) { _ in
                        guard !suppressPush else { return }
                        pushHex(userEdit: true)
                    }
                Text("\(Int((opacity * 100).rounded()))%")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(width: 36, alignment: .trailing)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.04))
        .cornerRadius(8)
        .onAppear { pullFromHex() }
        .onChange(of: hex) { newValue in
            // External change (import / Edit Active Theme) — resync local draft
            guard !suppressPush else { return }
            if newValue.uppercased() != preview.toHexStringARGB.uppercased() {
                pullFromHex()
            }
        }
    }

    private func pullFromHex() {
        suppressPush = true
        let color = Color(hexString: hex) ?? .white
        let c = color.resolvedRGBA
        // Store opaque RGB in the picker; alpha lives in the slider
        draftRGB = Color.srgb(r: c.r, g: c.g, b: c.b, a: 1)
        opacity = c.a
        // Quietly normalize legacy #RRGGBB → #AARRGGBB without flipping app theme to Custom
        let normalized = Color.srgb(r: c.r, g: c.g, b: c.b, a: c.a).toHexStringARGB
        if normalized.uppercased() != hex.uppercased() {
            hex = normalized
        }
        DispatchQueue.main.async { suppressPush = false }
    }

    /// - Parameter userEdit: when true, notifies parent (switches preset to Custom).
    ///   Silent normalizes / resyncs must pass false so opening Themes does not force Custom.
    private func pushHex(userEdit: Bool) {
        let c = draftRGB.resolvedRGBA
        let composed = Color.srgb(r: c.r, g: c.g, b: c.b, a: opacity)
        let next = composed.toHexStringARGB
        guard next.uppercased() != hex.uppercased() else { return }
        suppressPush = true
        hex = next
        if userEdit {
            onEdited()
        }
        DispatchQueue.main.async { suppressPush = false }
    }
}

/// Tiny checkerboard so transparent swatches are visible on dark UI.
private struct CheckerboardBackground: View {
    var body: some View {
        Canvas { context, size in
            let cell: CGFloat = 4
            var y: CGFloat = 0
            var row = 0
            while y < size.height {
                var x: CGFloat = 0
                var col = 0
                while x < size.width {
                    let dark = (row + col) % 2 == 0
                    context.fill(
                        Path(CGRect(x: x, y: y, width: cell, height: cell)),
                        with: .color(dark ? Color.gray.opacity(0.55) : Color.white.opacity(0.85))
                    )
                    x += cell
                    col += 1
                }
                y += cell
                row += 1
            }
        }
    }
}

struct CustomThemeStudio: View {
    @AppStorage("custom_hex_card") private var cardHex: String = "#FF16213E"
    @AppStorage("custom_hex_cyan") private var cyanHex: String = "#FF4CC9F0"
    @AppStorage("custom_hex_orange") private var orangeHex: String = "#FFFF8C00"
    @AppStorage("custom_hex_green") private var greenHex: String = "#FF00FF7F"
    @AppStorage("custom_hex_purple") private var purpleHex: String = "#FFA020F0"
    @AppStorage("app_theme_preset") private var selectedThemeRaw: String = AppTheme.tahoe.rawValue

    private func markCustom() {
        selectedThemeRaw = AppTheme.custom.rawValue
        AppTheme.postThemeChanged()
    }

    private func copyCurrentThemeToCustom() {
        let curr = AppTheme.current
        // Always ARGB so card translucency (Tahoe ~0.82) is kept
        cardHex = curr.card.toHexStringARGB
        cyanHex = curr.accentCyan.toHexStringARGB
        orangeHex = curr.accentOrange.toHexStringARGB
        greenHex = curr.accentGreen.toHexStringARGB
        purpleHex = curr.accentPurple.toHexStringARGB
        selectedThemeRaw = AppTheme.custom.rawValue
        AppTheme.postThemeChanged()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Custom Theme Editor")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    Text("Use the Opacity slider for transparency (macOS color panel alone often resets alpha).")
                        .font(.system(size: 10))
                        .foregroundColor(.tahoeSubtext)
                }
                Spacer()
                TahoeButton(label: "Edit Active Theme", icon: "doc.on.doc", accent: .tahoeAccentOrange) {
                    copyCurrentThemeToCustom()
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 10)], spacing: 10) {
                ColorTokenEditorSlot(title: "Card Background", hex: $cardHex, onEdited: markCustom)
                ColorTokenEditorSlot(title: "Cyan Accent", hex: $cyanHex, onEdited: markCustom)
                ColorTokenEditorSlot(title: "Orange Accent", hex: $orangeHex, onEdited: markCustom)
                ColorTokenEditorSlot(title: "Green Accent", hex: $greenHex, onEdited: markCustom)
                ColorTokenEditorSlot(title: "Purple Accent", hex: $purpleHex, onEdited: markCustom)
            }

            Divider().background(Color.tahoeCardBorder)

            HStack(spacing: 12) {
                TahoeButton(label: "Export Theme (JSON)", icon: "square.and.arrow.up", accent: .tahoeAccentCyan) {
                    exportTheme()
                }
                TahoeButton(label: "Import Theme (JSON)", icon: "square.and.arrow.down", accent: .tahoeAccentGreen) {
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
        // Always export ARGB so opacity survives re-import
        let pack = ThemePresetPack(
            name: "Mi Tema Custom",
            cardHex: Color(hexString: cardHex)?.toHexStringARGB ?? cardHex,
            cyanHex: Color(hexString: cyanHex)?.toHexStringARGB ?? cyanHex,
            orangeHex: Color(hexString: orangeHex)?.toHexStringARGB ?? orangeHex,
            greenHex: Color(hexString: greenHex)?.toHexStringARGB ?? greenHex,
            purpleHex: Color(hexString: purpleHex)?.toHexStringARGB ?? purpleHex
        )
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
                    // Normalize to ARGB so older 6-digit JSON imports keep working and opacity is explicit
                    cardHex = Color(hexString: pack.cardHex)?.toHexStringARGB ?? pack.cardHex
                    cyanHex = Color(hexString: pack.cyanHex)?.toHexStringARGB ?? pack.cyanHex
                    orangeHex = Color(hexString: pack.orangeHex)?.toHexStringARGB ?? pack.orangeHex
                    greenHex = Color(hexString: pack.greenHex)?.toHexStringARGB ?? pack.greenHex
                    purpleHex = Color(hexString: pack.purpleHex)?.toHexStringARGB ?? pack.purpleHex
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
                SectionTitle("Language")
                LanguagePickerCard()

                SectionTitle("Select Visual Theme (Instant Application)")
                ThemeSelectorGrid()

                SectionTitle("Custom Theme Creator & Exchange (JSON)")
                CustomThemeStudio()

                SectionTitle("Chart Rendering Style")
                ChartStyleSelectorGrid()
            }
            .padding(20)
        }
    }
}

// MARK: - Language picker
struct LanguagePickerCard: View {
    @AppStorage(AppLanguage.storageKey) private var languageCode: String = ""
    @State private var pendingCode: String = ""
    @State private var showRestartAlert = false

    private var languages: [AppLanguage] { AppLanguage.available }

    var body: some View {
        TahoeCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "globe")
                        .foregroundColor(.tahoeAccentCyan)
                        .font(.system(size: 16, weight: .semibold))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("App Language", comment: ""))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.tahoeText)
                        Text(NSLocalizedString("Choose the interface language. The app will restart to apply the change.", comment: ""))
                            .font(.system(size: 11))
                            .foregroundColor(.tahoeSubtext)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                }

                Picker("", selection: Binding(
                    get: { languageCode },
                    set: { newValue in
                        if newValue != languageCode {
                            pendingCode = newValue
                            showRestartAlert = true
                        }
                    }
                )) {
                    ForEach(languages) { lang in
                        Text(lang.displayName).tag(lang.rawValue)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(maxWidth: 320, alignment: .leading)
                // Force menu row to match stored language after Cancel
                .id(languageCode)

                Text(String(format: NSLocalizedString("Current: %@", comment: "Current language label"), currentLanguageLabel))
                    .font(.system(size: 10))
                    .foregroundColor(.tahoeSubtext)
            }
        }
        .alert(NSLocalizedString("Restart required", comment: ""), isPresented: $showRestartAlert) {
            Button(NSLocalizedString("Cancel", comment: ""), role: .cancel) {
                pendingCode = languageCode
            }
            Button(NSLocalizedString("Apply & Restart", comment: "")) {
                let lang = AppLanguage(rawValue: pendingCode) ?? .system
                AppLanguage.select(lang, relaunch: true)
            }
        } message: {
            Text(NSLocalizedString("The app needs to restart to load the selected language.", comment: ""))
        }
    }

    private var currentLanguageLabel: String {
        let lang = AppLanguage(rawValue: languageCode) ?? .system
        if lang == .system {
            let preferred = Locale.preferredLanguages.first ?? "en"
            let code = String(preferred.prefix(while: { $0 != "-" && $0 != "_" }))
            let name = Locale.current.localizedString(forLanguageCode: code) ?? code
            return "\(NSLocalizedString("System Default", comment: "")) (\(name))"
        }
        return lang.displayName
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
                        if let url = URL(string: "https://github.com/DrogaBox/SMCAMDProcessor-personal") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    TahoeButton(label: "Donate (PayPal)", icon: "heart.fill", accent: .tahoeAccentOrange) {
                        DispatchQueue.global(qos: .userInitiated).async {
                            if let url = Bundle.main.url(forResource: "bravo", withExtension: "mp3") {
                                if let sound = NSSound(contentsOf: url, byReference: true) {
                                    sound.play()
                                }
                            }
                        }
                        if let url = URL(string: "https://www.paypal.com/donate/?business=mrleisures@gmail.com") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
            }
            .padding(18)
        }
    }
}


enum PopoverTab: Int, CaseIterable {
    case telemetry = 0
    case profiles = 1
    case settings = 2
}

struct PopoverTabButton: View {
    let title: String
    let icon: String
    let tab: PopoverTab
    @Binding var currentTab: PopoverTab
    let theme: AppTheme
    
    var body: some View {
        Button(action: {
            currentTab = tab
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 9, weight: .semibold))
            }
            .foregroundColor(currentTab == tab ? theme.text : theme.subtext)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(currentTab == tab ? theme.cardBorder.opacity(0.8) : Color.clear)
                    .animation(.easeInOut(duration: 0.2), value: currentTab)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PopoverProfilesView: View {
    @ObservedObject var model: TelemetryModel = TelemetryModel.shared
    private var theme: AppTheme { AppTheme.current }
    
    // activeEPP slider values: 0=Ahorro, 1=Eq. Ahorro, 2=Eq. Rendimiento, 3=Rendimiento
    private var sliderValue: Binding<Double> {
        Binding<Double>(
            get: {
                switch model.cppcEPPValue {
                case 0x00...0x1F: return 3.0 // Rendimiento
                case 0x20...0x5F: return 2.0 // Equilibrado Rend.
                case 0x60...0x9F: return 1.0 // Equilibrado Ahorro
                case 0xA0...0xFF: return 0.0 // Ahorro de Energía
                default: return 2.0
                }
            },
            set: { val in
                let intVal = Int(round(val))
                var newEPP: UInt8 = 0x3F
                if intVal == 3 { newEPP = 0x00 }
                else if intVal == 2 { newEPP = 0x3F }
                else if intVal == 1 { newEPP = 0x80 }
                else if intVal == 0 { newEPP = 0xC0 }
                
                // Disable Auto EPP when user overrides manually
                if model.autoEPPEnabled { model.autoEPPEnabled = false }
                model.setCPPCEPPValue(epp: newEPP)
            }
        )
    }
    
    private var currentProfileName: String {
        switch model.cppcEPPValue {
        case 0x00...0x1F: return "Rendimiento"
        case 0x20...0x5F: return "Equilibrado Rend."
        case 0x60...0x9F: return "Equilibrado Ahorro"
        case 0xA0...0xFF: return "Ahorro de Energía"
        default: return "Desconocido"
        }
    }
    
    private var currentProfileIcon: String {
        switch model.cppcEPPValue {
        case 0x00...0x1F: return "bolt.fill"
        case 0x20...0x5F: return "scale.3d"
        case 0x60...0x9F: return "leaf"
        case 0xA0...0xFF: return "leaf.fill"
        default: return "cpu"
        }
    }
    
    private var currentProfileColor: Color {
        switch model.cppcEPPValue {
        case 0x00...0x1F: return theme.accentRed
        case 0x20...0x5F: return theme.accentOrange
        case 0x60...0x9F: return theme.accentCyan
        case 0xA0...0xFF: return theme.accentGreen
        default: return theme.subtext
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // KDE Style Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(currentProfileColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: currentProfileIcon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(currentProfileColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.autoEPPEnabled ? "Perfil de Energía (Auto-EPP Activo)" : "Perfil de Energía")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(model.autoEPPEnabled ? theme.accentCyan : theme.subtext)
                    Text(currentProfileName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(theme.text)
                }
                Spacer()
            }
            .padding(.top, 4)
            
            // KDE Style Slider
            VStack(spacing: 8) {
                Slider(value: sliderValue, in: 0...3, step: 1)
                    .accentColor(currentProfileColor)
                    .disabled(model.autoEPPEnabled)
                
                HStack {
                    Text("Ahorro")
                        .font(.system(size: 9))
                        .foregroundColor(sliderValue.wrappedValue == 0 ? theme.text : theme.subtext)
                    Spacer()
                    Text("Eq. Ahorro")
                        .font(.system(size: 9))
                        .foregroundColor(sliderValue.wrappedValue == 1 ? theme.text : theme.subtext)
                    Spacer()
                    Text("Eq. Rend.")
                        .font(.system(size: 9))
                        .foregroundColor(sliderValue.wrappedValue == 2 ? theme.text : theme.subtext)
                    Spacer()
                    Text("Rendimiento")
                        .font(.system(size: 9))
                        .foregroundColor(sliderValue.wrappedValue == 3 ? theme.text : theme.subtext)
                }
                .opacity(model.autoEPPEnabled ? 0.5 : 1.0)
            }
            
            Divider().background(theme.cardBorder)
            
            // Advanced Toggles
            VStack(alignment: .leading, spacing: 12) {
                Text("Controles Avanzados")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(theme.subtext)
                
                Toggle(isOn: $model.autoEPPEnabled) {
                    HStack {
                        Image(systemName: "cpu")
                            .foregroundColor(theme.accentCyan)
                            .frame(width: 16)
                        Text("Auto EPP (Zen 3)")
                            .font(.system(size: 11))
                            .foregroundColor(theme.text)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: theme.accentCyan))
                
                Toggle(isOn: $model.cpbEnabled) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(theme.accentOrange)
                            .frame(width: 16)
                        Text("Core Performance Boost")
                            .font(.system(size: 11))
                            .foregroundColor(theme.text)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: theme.accentOrange))
                .onChange(of: model.cpbEnabled) { newValue in
                    model.setCPB(enabled: newValue)
                }
            }
        }
        .padding(16)
    }
}

struct PopoverSettingsView: View {
    @AppStorage("pop_showCPU") private var showCPU = true
    @AppStorage("pop_showGPU") private var showGPU = true
    @AppStorage("pop_showRAM") private var showRAM = true
    @AppStorage("pop_showDisk") private var showDisk = true
    @AppStorage("pop_showNetwork") private var showNetwork = true
    @AppStorage("pop_processApp") private var processApp: String = "Activity Monitor"
    
    @State private var selectedShortcutOption: String = "Activity Monitor"
    @State private var customShortcutPath: String = ""
    
    private var theme: AppTheme { AppTheme.current }
    private let presetApps = ["Activity Monitor", "Terminal", "System Information", "Console"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header Section
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(theme.accentCyan)
                    .font(.system(size: 13, weight: .bold))
                Text("Popover Settings")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(theme.text)
            }
            .padding(.bottom, 2)
            
            Divider().background(theme.cardBorder.opacity(0.8))
            
            // Section 1: Active Monitors
            VStack(alignment: .leading, spacing: 8) {
                Text("ACTIVE MONITORS")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(theme.subtext)
                    .tracking(1.0)
                
                VStack(spacing: 6) {
                    PopoverToggleRow(title: "CPU Tracker", icon: "cpu", isOn: $showCPU, activeColor: theme.accentCyan, theme: theme)
                    PopoverToggleRow(title: "GPU Tracker", icon: "square.grid.3x1.below.line.grid.1x2", isOn: $showGPU, activeColor: theme.accentGreen, theme: theme)
                    PopoverToggleRow(title: "RAM Tracker", icon: "memorychip", isOn: $showRAM, activeColor: theme.accentOrange, theme: theme)
                    PopoverToggleRow(title: "Disk Tracker", icon: "internaldrive", isOn: $showDisk, activeColor: theme.accentPurple, theme: theme)
                    PopoverToggleRow(title: "Network Tracker", icon: "network", isOn: $showNetwork, activeColor: theme.accentCyan, theme: theme)
                }
            }
            
            Divider().background(theme.cardBorder.opacity(0.8))
            
            // Section 2: Shortcut Application
            VStack(alignment: .leading, spacing: 8) {
                Text("SHORTCUT APPLICATION")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(theme.subtext)
                    .tracking(1.0)
                
                Text("Launches when double-clicking resource metrics.")
                    .font(.system(size: 10))
                    .foregroundColor(theme.subtext)
                
                HStack(spacing: 8) {
                    Image(systemName: "app.badge.fill")
                        .font(.system(size: 11))
                        .foregroundColor(theme.accentCyan)
                        .frame(width: 16)
                    
                    Picker("", selection: $selectedShortcutOption) {
                        ForEach(presetApps, id: \.self) { app in
                            Text(app).tag(app)
                        }
                        Text("Custom...").tag("Custom")
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .font(.system(size: 11))
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(theme.cardBorder.opacity(0.3))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.cardBorder.opacity(0.6), lineWidth: 0.8)
                )
                
                if selectedShortcutOption == "Custom" {
                    TextField("Enter application name or path...", text: $customShortcutPath)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 11, design: .monospaced))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(theme.cardBorder.opacity(0.2))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(theme.cardBorder.opacity(0.6), lineWidth: 0.8)
                        )
                        .padding(.top, 2)
                        .onChange(of: customShortcutPath) { newVal in
                            processApp = newVal
                        }
                }
            }
            .onChange(of: selectedShortcutOption) { newVal in
                if newVal != "Custom" {
                    processApp = newVal
                } else {
                    processApp = customShortcutPath
                }
            }
            .onAppear {
                if presetApps.contains(processApp) {
                    selectedShortcutOption = processApp
                } else {
                    selectedShortcutOption = "Custom"
                    customShortcutPath = processApp
                }
            }
            
            Divider().background(theme.cardBorder.opacity(0.8))
                .padding(.top, 2)
            
            // Section 3: Advanced Preferences Button
            Button(action: {
                ViewController.launch()
                TelemetryModel.shared.selectedTab = .popover
                NotificationCenter.default.post(name: .init("CloseMenuBarPopover"), object: nil)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 11))
                    Text("Advanced Preferences...")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [theme.accentCyan, theme.accentCyan.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(8)
                .shadow(color: theme.accentCyan.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
        .foregroundColor(theme.text)
    }
}

// MARK: - PopoverToggleRow Helper
struct PopoverToggleRow: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    let activeColor: Color
    let theme: AppTheme
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(isOn ? activeColor : theme.subtext)
                .frame(width: 20)
            
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(theme.text)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: activeColor))
                .labelsHidden()
                .scaleEffect(0.8)
                .frame(height: 20)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(theme.cardBorder.opacity(0.15))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.cardBorder.opacity(0.4), lineWidth: 0.6)
        )
    }
}

// MARK: - Menu Bar Popover View
struct MenuBarPopoverView: View {
    @ObservedObject var model: TelemetryModel = TelemetryModel.shared
    /// Live theme (same store as RTL Wi-Fi Tahoe / Themes tab)
    @AppStorage("app_theme_preset") private var themePreset: String = AppTheme.tahoe.rawValue
    @AppStorage("custom_hex_card") private var customCardHex: String = "#16213E"
    @AppStorage("custom_hex_cyan") private var customCyanHex: String = "#4CC9F0"
    @AppStorage("custom_hex_orange") private var customOrangeHex: String = "#FF8C00"
    @AppStorage("custom_hex_green") private var customGreenHex: String = "#00FF7F"
    @AppStorage("custom_hex_purple") private var customPurpleHex: String = "#A020F0"
    @AppStorage("pop_processApp") private var processApp: String = "Activity Monitor"
    
    private var cfg: MenuBarConfig { MenuBarConfig.shared }
    private var theme: AppTheme { AppTheme.current }
    
    @State private var currentTab: PopoverTab = .telemetry

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
        // Touch custom hex so body re-evaluates when editor changes tokens
        let _ = (themePreset, customCardHex, customCyanHex, customOrangeHex, customGreenHex, customPurpleHex)
        VStack(spacing: 12) {
            // Header Section — RTL-style glass chrome
            VStack(spacing: 4) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "cpu.fill")
                            .foregroundColor(theme.accentCyan)
                            .font(.system(size: 13, weight: .bold))
                        HStack(spacing: 0) {
                            Text("AMD Power ")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(theme.text)
                            Text("Gadget")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(theme.accentCyan)
                        }
                    }
                    Spacer()
                    Button(action: {
                        MenuBarConfig.shared.popoverPinOpen.toggle()
                        NotificationCenter.default.post(name: .init("MenuBarConfigChanged"), object: nil)
                    }) {
                        Image(systemName: MenuBarConfig.shared.popoverPinOpen ? "pin.fill" : "pin")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(MenuBarConfig.shared.popoverPinOpen ? theme.accentGreen : theme.subtext)
                    }
                    .buttonStyle(.plain)
                    .help("Pin Popover Open")
                }
                
                HStack {
                    let appVer = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "3.17.0"
                    let kextVer = model.sysInfo.kextVersion.isEmpty ? "N/A" : model.sysInfo.kextVersion
                    
                    Text("App: v\(appVer) · \(theme.localizedName)")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(theme.subtext)
                    Spacer()
                    Text("Kext: v\(kextVer)")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(theme.subtext)
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)

            // Custom Segmented Picker
            HStack(spacing: 0) {
                PopoverTabButton(title: "Telemetry", icon: "chart.xyaxis.line", tab: .telemetry, currentTab: $currentTab, theme: theme)
                PopoverTabButton(title: "Perfiles", icon: "bolt.fill", tab: .profiles, currentTab: $currentTab, theme: theme)
                PopoverTabButton(title: "Settings", icon: "gearshape.fill", tab: .settings, currentTab: $currentTab, theme: theme)
            }
            .padding(4)
            .background(theme.cardBorder.opacity(0.4))
            .cornerRadius(8)
            .padding(.horizontal, 12)

            if currentTab == .telemetry {
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
                Divider().background(theme.cardBorder)
                
                HStack(spacing: 14) {
                    ForEach(rings, id: \.self) { ring in
                        if ring == "cpu" && cfg.popoverShowCPU && cfg.popoverCPUStyle == 0 {
                            // CPU Ring
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .stroke(theme.cardBorder.opacity(0.6), lineWidth: 4.5)
                                        .frame(width: 46, height: 46)
                                    Circle()
                                        .trim(from: 0, to: CGFloat(min(1.0, max(0.0, model.cpuLoadAvg / 100.0))))
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [theme.accentCyan, theme.accentCyan.opacity(0.55)]),
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
                                            .foregroundColor(theme.text)
                                        if cfg.popoverRingShowTemp {
                                            Text(String(format: "%.0f°", model.cpuTempC))
                                                .font(.system(size: 7.5, weight: .semibold))
                                                .foregroundColor(theme.subtext)
                                        }
                                    }
                                }
                                if cfg.popoverRingShowLabels {
                                    Text("CPU")
                                        .font(.system(size: 8.5, weight: .bold))
                                        .foregroundColor(theme.subtext)
                                }
                            }
                        } else if ring == "ram" && cfg.popoverShowRAM && cfg.popoverRAMStyle == 0 {
                            // RAM Ring
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .stroke(theme.cardBorder.opacity(0.6), lineWidth: 4.5)
                                        .frame(width: 46, height: 46)
                                    Circle()
                                        .trim(from: 0, to: CGFloat(min(1.0, max(0.0, model.ramUsagePct / 100.0))))
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [theme.accentOrange, theme.accentOrange.opacity(0.55)]),
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
                                            .foregroundColor(theme.text)
                                        if cfg.popoverRingShowTemp {
                                            let usedGB = (model.ramUsagePct / 100.0) * (Double(ProcessInfo.processInfo.physicalMemory) / (1024.0 * 1024.0 * 1024.0))
                                            Text(String(format: "%.0fG", usedGB))
                                                .font(.system(size: 7.5, weight: .semibold))
                                                .foregroundColor(theme.subtext)
                                        }
                                    }
                                }
                                if cfg.popoverRingShowLabels {
                                    Text("RAM")
                                        .font(.system(size: 8.5, weight: .bold))
                                        .foregroundColor(theme.subtext)
                                }
                            }
                        } else if ring == "disk" && cfg.popoverShowDisk && cfg.popoverDiskStyle == 0 {
                            // Disk Ring
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .stroke(theme.cardBorder.opacity(0.6), lineWidth: 4.5)
                                        .frame(width: 46, height: 46)
                                    Circle()
                                        .trim(from: 0, to: CGFloat(min(1.0, max(0.0, model.diskUsagePct / 100.0))))
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [theme.accentGreen, theme.accentGreen.opacity(0.55)]),
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
                                            .foregroundColor(theme.text)
                                        if cfg.popoverRingShowTemp {
                                            Text("SSD")
                                                .font(.system(size: 7.5, weight: .semibold))
                                                .foregroundColor(theme.subtext)
                                        }
                                    }
                                }
                                if cfg.popoverRingShowLabels {
                                    Text("DISK")
                                        .font(.system(size: 8.5, weight: .bold))
                                        .foregroundColor(theme.subtext)
                                }
                            }
                        } else if ring == "gpu" && cfg.popoverShowGPURing && cfg.popoverGPUStyle == 0 {
                            // GPU Ring
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .stroke(theme.cardBorder.opacity(0.6), lineWidth: 4.5)
                                        .frame(width: 46, height: 46)
                                    Circle()
                                        .trim(from: 0, to: CGFloat(min(1.0, max(0.0, model.gpuLoadPct / 100.0))))
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [theme.accentPurple, theme.accentPurple.opacity(0.55)]),
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
                                            .foregroundColor(theme.text)
                                        if cfg.popoverRingShowTemp {
                                            Text(String(format: "%.0f°", model.gpuTempC))
                                                .font(.system(size: 7.5, weight: .semibold))
                                                .foregroundColor(theme.subtext)
                                        }
                                    }
                                }
                                if cfg.popoverRingShowLabels {
                                    Text("GPU")
                                        .font(.system(size: 8.5, weight: .bold))
                                        .foregroundColor(theme.subtext)
                                }
                            }
                        } else if ring == "vram" && cfg.popoverShowVRAM && cfg.popoverGPUStyle == 0 {
                            // VRAM Ring
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .stroke(theme.cardBorder.opacity(0.6), lineWidth: 4.5)
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
                                                gradient: Gradient(colors: [theme.accentPurple.opacity(0.9), theme.accentOrange.opacity(0.75)]),
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
                                            .foregroundColor(theme.text)
                                        if cfg.popoverRingShowTemp {
                                            Text(String(format: "%.0fG", vramGB))
                                                .font(.system(size: 7.5, weight: .semibold))
                                                .foregroundColor(theme.subtext)
                                        }
                                    }
                                }
                                if cfg.popoverRingShowLabels {
                                    Text("VRAM")
                                        .font(.system(size: 8.5, weight: .bold))
                                        .foregroundColor(theme.subtext)
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
                Divider().background(theme.cardBorder)
                
                VStack(spacing: 10) {
                    ForEach(rings, id: \.self) { ring in
                        if ring == "cpu" && cfg.popoverShowCPU {
                            if cfg.popoverCPUStyle == 1 {
                                let cpuTempStr = cfg.popoverRingShowTemp ? String(format: " • %.0f°C", model.cpuTempC) : ""
                                LinearProgressBar(
                                    label: "CPU",
                                    pct: model.cpuLoadAvg,
                                    detailText: String(format: "%.0f%%%@", model.cpuLoadAvg, cpuTempStr),
                                    color: theme.accentCyan
                                )
                            }
                            if cfg.popoverShowCPUSparkline {
                                let cpuTempStr = cfg.popoverRingShowTemp ? String(format: " • %.0f°C", model.cpuTempC) : ""
                                MiniSparkline(
                                    label: "CPU Temp",
                                    currentVal: String(format: "%.0f°C", model.cpuTempC),
                                    color: theme.accentCyan,
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
                                    color: theme.accentPurple
                                )
                            }
                            if cfg.popoverShowGPUSparkline {
                                MiniSparkline(
                                    label: "GPU Temp",
                                    currentVal: String(format: "%.0f°C", model.gpuTempC),
                                    color: theme.accentPurple,
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
                                    color: theme.accentPurple.opacity(0.8)
                                )
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            // GPU & Network Stats
            if cfg.popoverShowGPU || cfg.popoverShowNetwork {
                Divider().background(theme.cardBorder)
                
                VStack(alignment: .leading, spacing: 6) {
                    if cfg.popoverShowGPU {
                        // GPU Row
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 10))
                                    .foregroundColor(theme.accentPurple)
                                    .frame(width: 14)
                                Text(model.sysInfo.gpuModel.isEmpty || model.sysInfo.gpuModel == "Unknown" ? "Radeon GPU" : model.sysInfo.gpuModel)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(theme.text)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                Spacer()
                                if model.gpuTempC > 0 {
                                    Text(String(format: "%.0f°C • %.0fW", model.gpuTempC, model.gpuPowerW))
                                        .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                                        .foregroundColor(theme.text.opacity(0.9))
                                } else {
                                    Text("Inactive")
                                        .font(.system(size: 9.5, weight: .semibold))
                                        .foregroundColor(theme.subtext.opacity(0.9))
                                }
                            }
                            if model.gpuTempC > 0 {
                                HStack {
                                    Spacer()
                                    let vramGB = model.gpuVramUsedBytes / (1024.0 * 1024.0 * 1024.0)
                                    let fanRPMStr = model.gpuFanRPM > 0 ? String(format: " • %.0f RPM", model.gpuFanRPM) : ""
                                    Text(String(format: "VRAM: %.2fG%@", vramGB, fanRPMStr))
                                        .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                                        .foregroundColor(theme.subtext)
                                }
                            }
                        }
                    }

                    if cfg.popoverShowNetwork {
                        // Network Row
                        Button(action: {
                            let task = Process()
                            task.launchPath = "/usr/bin/open"
                            task.arguments = ["/System/Library/PreferencePanes/Network.prefPane"]
                            try? task.run()
                        }) {
                            VStack(spacing: 4) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.up.arrow.down")
                                        .font(.system(size: 9))
                                        .foregroundColor(.green)
                                        .frame(width: 14)
                                    Text("Network")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(theme.text)
                                    Spacer()
                                    Text("↓ \(formatSpeed(model.netDownloadMBps))  ↑ \(formatSpeed(model.netUploadMBps))")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(theme.text.opacity(0.85))
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
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
            }

            // Top Processes List
            if cfg.popoverShowProcesses {
                Divider().background(theme.cardBorder)
                
                Button(action: {
                    let task = Process()
                    task.launchPath = "/usr/bin/open"
                    task.arguments = ["-a", processApp]
                    try? task.run()
                }) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Top Processes")
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundColor(theme.subtext)
                            Spacer()
                            Image(systemName: "list.bullet")
                                .font(.system(size: 8))
                                .foregroundColor(theme.subtext.opacity(0.9))
                        }
                        .padding(.bottom, 2)

                        if model.topProcesses.isEmpty {
                            HStack {
                                Spacer()
                                Text("Loading...")
                                    .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                                    .foregroundColor(theme.subtext.opacity(0.9))
                                    .padding(.vertical, 4)
                                Spacer()
                            }
                        } else {
                            ForEach(model.topProcesses) { proc in
                                HStack {
                                    Text(proc.name)
                                        .font(.system(size: 9.5, weight: .semibold))
                                        .foregroundColor(theme.text.opacity(0.9))
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                    Spacer()
                                    Text(String(format: "%.1f%%", proc.cpuUsage))
                                        .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                                        .foregroundColor(proc.cpuUsage > 50 ? theme.accentOrange : theme.subtext)
                                }
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal, 12)
                    .frame(height: 95)
                }
                .buttonStyle(.plain)
            }
            } else if currentTab == .profiles {
                PopoverProfilesView()
            } else if currentTab == .settings {
                PopoverSettingsView()
            }

            Divider().background(theme.cardBorder)

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
                    .foregroundColor(theme.text)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(theme.cardBorder.opacity(0.6))
                    .cornerRadius(5)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "power")
                            .font(.system(size: 9.5))
                        Text("Quit")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(theme.accentRed)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(theme.accentRed.opacity(0.12))
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(theme.accentRed.opacity(0.35), lineWidth: 1))
                    .cornerRadius(5)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(minWidth: 260, maxWidth: 360)
        .fixedSize(horizontal: false, vertical: true)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(theme.background.opacity(0.92))
                VisualEffectBackground(
                    material: .hudWindow,
                    blendingMode: .behindWindow,
                    state: .active,
                    cornerRadius: 16
                )
                .opacity(theme.glassOpacity)
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(theme.cardBorder, lineWidth: 1)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .id(themePreset) // force rebuild when theme changes
    }
}

// MARK: - Popover Config Tab
struct PopoverConfigView: View {
    @ObservedObject var model: TelemetryModel
    @State private var cfg = MenuBarConfig.shared
    @State private var items: [RingOrderItem] = []
    @AppStorage("app_theme_preset") private var themePreset: String = AppTheme.tahoe.rawValue

    struct RingOrderItem: Identifiable, Equatable {
        let id: String
        let name: String
        let color: Color
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle("Popover Theme")
                Text("Same presets as RTL Wi-Fi Tahoe (and Themes & Appearance). Applies to the menu bar popover and main window.")
                    .font(.system(size: 12)).foregroundColor(.tahoeSubtext)
                ThemeSelectorGrid()
                    .id(themePreset)

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

                    ToggleRow(label: "Pin Popover Open", detail: "Prevent the popover from closing when clicking outside", isOn: .init(
                        get: { cfg.popoverPinOpen }, set: { cfg.popoverPinOpen = $0; notify(widthChanged: false) }
                    ), accent: .tahoeAccentCyan) { _ in }

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
            print("Failed to rewrite history: \(error)")
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
                SectionTitle("History & Trends")
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
                    Text("Visible charts:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.tahoeSubtext)
                    
                    Button(action: { showCpuLoad.toggle() }) {
                        HStack(spacing: 6) {
                            Image(systemName: showCpuLoad ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(showCpuLoad ? Color.tahoeAccentCyan : .tahoeSubtext)
                            Text("CPU Load")
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
                            Text("Temperatures")
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
                            Text("RAM Usage")
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
                            Text("GPU Load")
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
                            Text("CPU Power")
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
                            Text("CPU Frequency")
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
                            let maxVal = data.map { $0.cpuLoad }.max() ?? 0.0
                            let minVal = data.map { $0.cpuLoad }.min() ?? 0.0
                            HistoryCard(
                                title: "CPU Load",
                                subtitle: "Average utilization over time",
                                accent: Color.tahoeAccentCyan,
                                peakInfo: String(format: "%.1f%%", maxVal),
                                lowestInfo: String(format: "%.1f%%", minVal)
                            ) {
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
                            let maxCpuTemp = data.map { $0.cpuTemp }.max() ?? 0.0
                            let minCpuTemp = data.map { $0.cpuTemp }.min() ?? 0.0
                            let maxGpuTemp = data.map { $0.gpuTemp }.max() ?? 0.0
                            let minGpuTemp = data.map { $0.gpuTemp }.min() ?? 0.0
                            HistoryCard(
                                title: "Thermal History",
                                subtitle: "CPU and GPU temperatures",
                                accent: Color.tahoeAccentRed,
                                peakInfo: String(format: "CPU %.0f°C / GPU %.0f°C", maxCpuTemp, maxGpuTemp),
                                lowestInfo: String(format: "CPU %.0f°C / GPU %.0f°C", minCpuTemp, minGpuTemp)
                            ) {
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
                            let maxVal = data.map { $0.ramUsage }.max() ?? 0.0
                            let minVal = data.map { $0.ramUsage }.min() ?? 0.0
                            HistoryCard(
                                title: "Memory Usage",
                                subtitle: "RAM utilization percentage",
                                accent: Color.tahoeAccentGreen,
                                peakInfo: String(format: "%.1f%%", maxVal),
                                lowestInfo: String(format: "%.1f%%", minVal)
                            ) {
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
                            let maxVal = data.map { $0.gpuLoad }.max() ?? 0.0
                            let minVal = data.map { $0.gpuLoad }.min() ?? 0.0
                            HistoryCard(
                                title: "GPU Load",
                                subtitle: "Radeon Graphics utilization percentage",
                                accent: Color.tahoeAccentPurple,
                                peakInfo: String(format: "%.1f%%", maxVal),
                                lowestInfo: String(format: "%.1f%%", minVal)
                            ) {
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
                            let maxVal = data.map { $0.safeCpuWatts }.max() ?? 0.0
                            let minVal = data.map { $0.safeCpuWatts }.min() ?? 0.0
                            HistoryCard(
                                title: "CPU Package Power",
                                subtitle: "Real-time energy consumption in Watts",
                                accent: Color.tahoeAccentOrange,
                                peakInfo: String(format: "%.1fW", maxVal),
                                lowestInfo: String(format: "%.1fW", minVal)
                            ) {
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
                            let maxVal = data.map { $0.safeCpuFreqAvg }.max() ?? 0.0
                            let minVal = data.map { $0.safeCpuFreqAvg }.min() ?? 0.0
                            HistoryCard(
                                title: "CPU Average Frequency",
                                subtitle: "Average core frequency in GHz",
                                accent: Color.tahoeAccentCyan,
                                peakInfo: String(format: "%.2f GHz", maxVal),
                                lowestInfo: String(format: "%.2f GHz", minVal)
                            ) {
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
    let peakInfo: String?
    let lowestInfo: String?
    let content: Content
    
    init(title: String, subtitle: String, accent: Color, peakInfo: String? = nil, lowestInfo: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.accent = accent
        self.peakInfo = peakInfo
        self.lowestInfo = lowestInfo
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
                
                if let peak = peakInfo, let lowest = lowestInfo {
                    HStack(spacing: 8) {
                        VStack(alignment: .trailing, spacing: 2) {
                            HStack(spacing: 4) {
                                Text("Máx:")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Color.tahoeSubtext)
                                Text(peak)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(accent)
                            }
                            HStack(spacing: 4) {
                                Text("Mín:")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Color.tahoeSubtext)
                                Text(lowest)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.tahoeSubtext)
                            }
                        }
                    }
                }
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
struct HUDBackdrop: NSViewRepresentable {
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
        .panelCard(scheme: colorScheme)
    }
}