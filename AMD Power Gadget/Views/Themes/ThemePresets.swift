//
// Extracted from ThemeViews.swift during post-refactor cleanup
//

import SwiftUI

struct ThemePresetPack: Codable {
    var name: String
    var cardHex: String
    var cyanHex: String
    var orangeHex: String
    var greenHex: String
    var purpleHex: String
}

// MARK: - Color Token Editor
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
