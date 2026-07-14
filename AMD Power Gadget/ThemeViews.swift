//
//  ThemeViews.swift
//  AMD Power Gadget
//
//  Extracted from MainDashboardView.swift (2026) — Theme & Appearance Views
//

import SwiftUI

// MARK: - Optimized Theme Selector Grid
struct OptimizedThemeSelectorGrid: View {
    @AppStorage("app_theme_preset") private var selectedThemeRaw: String = AppTheme.tahoe.rawValue
    @AppStorage("custom_hex_card") private var customCardHex: String = "#16213E"
    @AppStorage("custom_hex_cyan") private var customCyanHex: String = "#4CC9F0"
    @AppStorage("custom_hex_orange") private var customOrangeHex: String = "#FF8C00"
    @AppStorage("custom_hex_green") private var customGreenHex: String = "#00FF7F"
    @AppStorage("custom_hex_purple") private var customPurpleHex: String = "#A020F0"
    
    // Use 3 columns to fit more themes on screen
    private let columns = [
        GridItem(.flexible(), spacing: 12), 
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        let _ = (customCardHex, customCyanHex, customOrangeHex, customGreenHex, customPurpleHex)
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(AppTheme.allCases) { theme in
                CompactThemeButton(
                    theme: theme, 
                    isSelected: selectedThemeRaw == theme.rawValue
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedThemeRaw = theme.rawValue
                        AppTheme.postThemeChanged()
                    }
                }
            }
        }
    }
}

// MARK: - Compact Theme Button
private struct CompactThemeButton: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Color preview
                HStack(spacing: 4) {
                    Circle().fill(theme.accentCyan).frame(width: 8, height: 8)
                    Circle().fill(theme.accentOrange).frame(width: 8, height: 8)
                    Circle().fill(theme.accentGreen).frame(width: 8, height: 8)
                    Circle().fill(theme.accentPurple).frame(width: 8, height: 8)
                }
                .padding(6)
                .background(theme.card)
                .cornerRadius(8)
                
                // Theme name
                Text(theme.localizedName)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(isSelected ? theme.accentCyan : .tahoeSubtext)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(theme.accentCyan)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(10)
            .background(theme.card.opacity(isSelected ? 0.8 : 0.3))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? theme.accentCyan : Color.clear, lineWidth: 2)
            )
            .shadow(color: isSelected ? theme.accentCyan.opacity(0.3) : Color.clear, radius: 6)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Compact Card Opacity Editor
struct CompactCardOpacityEditor: View {
    @AppStorage("tahoe_card_opacity") private var cardOpacity: Double = 0.45

    var body: some View {
        TahoeCard {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Background Opacity")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.tahoeText)
                    Text("Adjust transparency")
                        .font(.system(size: 10))
                        .foregroundColor(.tahoeSubtext)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text("0%")
                        .font(.system(size: 9))
                        .foregroundColor(.tahoeSubtext)
                    
                    Slider(value: Binding(
                        get: { cardOpacity },
                        set: { newValue in 
                            cardOpacity = newValue
                            AppTheme.postThemeChanged()
                        }
                    ), in: 0...1, step: 0.05)
                    .accentColor(.tahoeAccentCyan)
                    .frame(width: 120)
                    
                    Text("\(Int(cardOpacity * 100))%")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.tahoeAccentCyan)
                        .frame(width: 35, alignment: .trailing)
                }
            }
        }
    }
}

// MARK: - Chart Styles Content View
struct ChartStylesContentView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Chart Rendering Styles")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.tahoeText)
                    
                    Text("Choose how charts are rendered in the dashboard. Optimized styles use less CPU and battery.")
                        .font(.system(size: 13))
                        .foregroundColor(.tahoeSubtext)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                ChartStyleSelectorGrid()
            }
            .padding(18)
        }
    }
}

// MARK: - Chart Style Selector
struct ChartStyleSelectorGrid: View {
    @AppStorage(AppChartStyle.storageKey) private var selectedStyleRaw: String = AppChartStyle.lightweightArea.rawValue
    private let columns = [GridItem(.flexible(), spacing: 12)]

    private var selectedStyle: AppChartStyle {
        AppChartStyle.normalized(selectedStyleRaw)
    }
    
    // Separate optimized and classic styles
    private var optimizedStyles: [AppChartStyle] {
        AppChartStyle.allCases.filter { $0.isOptimized }
    }
    
    private var classicStyles: [AppChartStyle] {
        AppChartStyle.allCases.filter { !$0.isOptimized }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Optimized styles section (recommended)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.tahoeAccentGreen)
                    Text("Optimized Styles")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.tahoeText)
                    Text("(Recommended for low power)")
                        .font(.system(size: 10))
                        .foregroundColor(.tahoeAccentGreen)
                }
                
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(optimizedStyles) { style in
                        ChartStyleButton(
                            style: style,
                            isSelected: selectedStyle == style,
                            isOptimized: true
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedStyleRaw = style.rawValue
                            }
                        }
                    }
                }
            }
            .padding(12)
            .background(Color.tahoeAccentGreen.opacity(0.08))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.tahoeAccentGreen.opacity(0.3), lineWidth: 1))
            
            // Classic styles section
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 11))
                        .foregroundColor(.tahoeSubtext)
                    Text("Classic Styles")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.tahoeText)
                    Text("(Higher CPU usage)")
                        .font(.system(size: 10))
                        .foregroundColor(.tahoeSubtext)
                }
                
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(classicStyles) { style in
                        ChartStyleButton(
                            style: style,
                            isSelected: selectedStyle == style,
                            isOptimized: false
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedStyleRaw = style.rawValue
                            }
                        }
                    }
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.03))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.tahoeCardBorder, lineWidth: 1))
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
            let style = AppChartStyle.migrateStoredPreference()
            if selectedStyleRaw != style.rawValue {
                selectedStyleRaw = style.rawValue
            }
        }
    }
}

// MARK: - Chart Style Button Component
private struct ChartStyleButton: View {
    let style: AppChartStyle
    let isSelected: Bool
    let isOptimized: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: style.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isSelected ? (isOptimized ? .tahoeAccentGreen : .tahoeAccentCyan) : .tahoeSubtext)
                    
                    Text(style.localizedName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .tahoeSubtext)
                    
                    Spacer()
                    
                    if isOptimized {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.tahoeAccentGreen)
                    }
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(isOptimized ? .tahoeAccentGreen : .tahoeAccentCyan)
                    }
                }
                
                Text(style.description)
                    .font(.system(size: 9))
                    .foregroundColor(.tahoeSubtext)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.white.opacity(0.12) : Color.white.opacity(0.03))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected 
                            ? (isOptimized ? Color.tahoeAccentGreen : Color.tahoeAccentCyan)
                            : Color.clear, 
                        lineWidth: isSelected ? 2 : 0
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - AppChartStyle Enum
enum AppChartStyle: String, CaseIterable, Identifiable {
    case line = "Smooth Curves"
    case filledArea = "Filled Area"
    case bar = "Column Bars"
    case steppedLine = "Line Only"
    
    // New lightweight optimized styles (2026-07-14)
    case lightweightArea = "Lightweight Area"
    case minimalistLine = "Minimalist Sparkline"
    case gradientBar = "Gradient Bar"
    case compactCard = "Compact Card"

    static let storageKey = "app_chart_style"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .line: return "waveform.path.ecg"
        case .filledArea: return "chart.area.fill"
        case .bar: return "chart.bar.fill"
        case .steppedLine: return "chart.line.uptrend.xyaxis"
        case .lightweightArea: return "chart.xyaxis.line"
        case .minimalistLine: return "waveform"
        case .gradientBar: return "slider.horizontal.3"
        case .compactCard: return "rectangle.compress.vertical"
        }
    }
    
    var description: String {
        switch self {
        case .line: return "Classic smooth curves with interpolation"
        case .filledArea: return "Area chart with gradient fill"
        case .bar: return "Vertical bar chart columns"
        case .steppedLine: return "Simple line without smoothing"
        case .lightweightArea: return "Optimized area chart - 50% less CPU usage"
        case .minimalistLine: return "Ultra-light sparkline - minimal rendering"
        case .gradientBar: return "Horizontal gradient progress bars"
        case .compactCard: return "Compact cards with integrated charts"
        }
    }
    
    var isOptimized: Bool {
        switch self {
        case .lightweightArea, .minimalistLine, .gradientBar, .compactCard:
            return true
        default:
            return false
        }
    }

    var localizedName: String { NSLocalizedString(rawValue, comment: "Chart rendering style") }

    static func normalized(_ stored: String) -> AppChartStyle {
        switch stored {
         case line.rawValue, "Smooth Line (Spline)", "Smooth Line (Spline)":
             return .line
         case filledArea.rawValue, "Filled Area (Gradient)", "Filled Area (Gradient)":
             return .filledArea
         case bar.rawValue, "Bar Histogram":
             return .bar
         case steppedLine.rawValue, "Stepped Line (Step)", "Stepped Line (Step)":
            return .steppedLine
        case lightweightArea.rawValue:
            return .lightweightArea
        case minimalistLine.rawValue:
            return .minimalistLine
        case gradientBar.rawValue:
            return .gradientBar
        case compactCard.rawValue:
            return .compactCard
        default:
            return AppChartStyle(rawValue: stored) ?? .line
        }
    }

    @discardableResult
    static func migrateStoredPreference(defaults: UserDefaults = .standard) -> AppChartStyle {
        let stored = defaults.string(forKey: storageKey) ?? lightweightArea.rawValue
        let style = normalized(stored)
        
        // If this is the first time (no stored value), set optimized default
        if defaults.object(forKey: storageKey) == nil {
            defaults.set(lightweightArea.rawValue, forKey: storageKey)
            return .lightweightArea
        }
        
        // Migrate old values to new format
        if stored != style.rawValue {
            defaults.set(style.rawValue, forKey: storageKey)
        }
        return style
    }
}

// MARK: - Color Hex Extensions
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

    func withResolvedAlpha(_ alpha: Double) -> Color {
        let c = resolvedRGBA
        return Color(.sRGB, red: c.r, green: c.g, blue: c.b, opacity: min(max(alpha, 0), 1))
    }

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

    var toHexStringARGB: String {
        let c = resolvedRGBA
        let ri = Int((c.r * 255).rounded())
        let gi = Int((c.g * 255).rounded())
        let bi = Int((c.b * 255).rounded())
        let ai = Int((c.a * 255).rounded())
        return String(format: "#%02X%02X%02X%02X", ai, ri, gi, bi)
    }

    static func srgb(r: Double, g: Double, b: Double, a: Double) -> Color {
        Color(.sRGB,
              red: min(max(r, 0), 1),
              green: min(max(g, 0), 1),
              blue: min(max(b, 0), 1),
              opacity: min(max(a, 0), 1))
    }
}

// MARK: - Theme Preset Pack (Codable)
struct ThemePresetPack: Codable {
    var name: String
    var cardHex: String
    var cyanHex: String
    var orangeHex: String
    var greenHex: String
    var purpleHex: String
}

// MARK: - Color Token Editor
struct ColorTokenEditorSlot: View {
    let title: LocalizedStringKey
    @Binding var hex: String
    var onEdited: () -> Void = {}

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
                ColorPicker("", selection: $draftRGB, supportsOpacity: false)
                    .labelsHidden()
                    .onChange(of: draftRGB) { _ in
                        guard !suppressPush else { return }
                        pushHex(userEdit: true)
                    }

                RoundedRectangle(cornerRadius: 4)
                    .fill(preview)
                    .frame(width: 22, height: 22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
                    .background(
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
        draftRGB = Color.srgb(r: c.r, g: c.g, b: c.b, a: 1)
        opacity = c.a
        let normalized = Color.srgb(r: c.r, g: c.g, b: c.b, a: c.a).toHexStringARGB
        if normalized.uppercased() != hex.uppercased() {
            hex = normalized
        }
        Task { @MainActor in suppressPush = false }
    }

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
        Task { @MainActor in suppressPush = false }
    }
}

// MARK: - Checkerboard Background
struct CheckerboardBackground: View {
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

// MARK: - Custom Theme Studio
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
        
        do {
            let data = try encoder.encode(pack)
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.json]
            panel.nameFieldStringValue = "MiTemaCustom.json"
            panel.begin { resp in
                if resp == .OK, let url = panel.url {
                    do {
                        try data.write(to: url)
                    } catch {
                        DispatchQueue.main.async {
                            let alert = NSAlert()
                            alert.messageText = NSLocalizedString("Export Failed", comment: "")
                            alert.informativeText = error.localizedDescription
                            alert.alertStyle = .warning
                            alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
                            alert.runModal()
                        }
                    }
                }
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Export Failed", comment: "")
            alert.informativeText = NSLocalizedString("Could not encode theme data.", comment: "")
            alert.alertStyle = .warning
            alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
            alert.runModal()
        }
    }

    private func importTheme() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.begin { resp in
            if resp == .OK, let url = panel.url {
                do {
                    let data = try Data(contentsOf: url)
                    let pack = try JSONDecoder().decode(ThemePresetPack.self, from: data)
                    
                    cardHex = Color(hexString: pack.cardHex)?.toHexStringARGB ?? pack.cardHex
                    cyanHex = Color(hexString: pack.cyanHex)?.toHexStringARGB ?? pack.cyanHex
                    orangeHex = Color(hexString: pack.orangeHex)?.toHexStringARGB ?? pack.orangeHex
                    greenHex = Color(hexString: pack.greenHex)?.toHexStringARGB ?? pack.greenHex
                    purpleHex = Color(hexString: pack.purpleHex)?.toHexStringARGB ?? pack.purpleHex
                    selectedThemeRaw = AppTheme.custom.rawValue
                } catch {
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("Import Failed", comment: "")
                    alert.informativeText = error.localizedDescription
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
                    alert.runModal()
                }
            }
        }
    }
}

// MARK: - Themes Content View
struct ThemesContentView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Themes & Appearance")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.tahoeText)
                    Text("Customize the visual appearance and chart styles")
                        .font(.system(size: 13))
                        .foregroundColor(.tahoeSubtext)
                }
                
                // Main content in optimized layout
                VStack(alignment: .leading, spacing: 18) {
                    // Language Selection
                    SectionWithIcon(title: "Language", icon: "globe") {
                        LanguagePickerCard()
                    }
                    
                    // Theme Selection - Make this the main focus
                    SectionWithIcon(title: "Visual Theme", icon: "paintpalette.fill") {
                        OptimizedThemeSelectorGrid()
                    }
                    
                    // Custom Theme
                    SectionWithIcon(title: "Custom Theme", icon: "wand.and.stars") {
                        CustomThemeStudio()
                    }
                    
                    // Card Opacity - Compact version
                    SectionWithIcon(title: "Card Opacity", icon: "rectangle.dock") {
                        CompactCardOpacityEditor()
                    }
                }
            }
            .padding(18)
        }
    }
}

// MARK: - Section with Icon Helper
struct SectionWithIcon<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.tahoeAccentCyan)
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.tahoeText)
                Spacer()
            }
            content()
        }
    }
}

// MARK: - Card Opacity Editor
struct CardOpacityEditorCard: View {
    @AppStorage("tahoe_card_opacity") private var cardOpacity: Double = 0.45

    var body: some View {
        TahoeCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("Adjust the opacity of the data cards background to increase readability or enhance the glassmorphism effect.", comment: ""))
                    .font(.system(size: 11))
                    .foregroundColor(.tahoeSubtext)
                
                HStack {
                    Text("0%")
                        .font(.system(size: 10))
                        .foregroundColor(.tahoeSubtext)
                    Slider(value: Binding(
                        get: { cardOpacity },
                        set: { newValue in 
                            cardOpacity = newValue
                            AppTheme.postThemeChanged()
                        }
                    ), in: 0...1, step: 0.05)
                    .accentColor(.tahoeAccentCyan)
                    
                    Text("\(Int(cardOpacity * 100))%")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.tahoeText)
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
    }
}

// MARK: - Language Picker
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

// MARK: - Legacy Theme Selector (for backward compatibility)
typealias ThemeSelectorGrid = OptimizedThemeSelectorGrid
