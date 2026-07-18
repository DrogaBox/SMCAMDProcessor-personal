//
// Extracted from ThemeViews.swift during post-refactor cleanup
//

import SwiftUI

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
         case line.rawValue, "Smooth Line (Spline)", "Línea Suave (Spline)":
             return .line
         case filledArea.rawValue, "Filled Area (Gradient)", "Área Rellena (Gradient)":
             return .filledArea
         case bar.rawValue, "Bar Histogram", "Histograma de Barras":
             return .bar
         case steppedLine.rawValue, "Stepped Line (Step)", "Línea Escalonada (Step)":
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
