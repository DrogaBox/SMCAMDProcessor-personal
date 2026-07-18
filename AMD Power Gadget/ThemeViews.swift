//
//  ThemeViews.swift
//  AMD Power Gadget
//
//  Extracted from MainDashboardView.swift (2026) — Theme & Appearance Views
//

import SwiftUI

// MARK: - Optimized Theme Selector Grid
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
