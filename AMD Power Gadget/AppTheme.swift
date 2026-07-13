//
//  AppTheme.swift
//  AMD Power Gadget
//
//  Extracted from MainDashboardView.swift (2026) — Design Tokens & Themes Engine
//

import SwiftUI

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
        let opacity = UserDefaults.standard.object(forKey: "tahoe_card_opacity") as? Double ?? 0.45
        switch self {
        // Opacity controlled by user preferences (default 0.45 for contrast)
        case .tahoe: return Color(red: 0.13, green: 0.13, blue: 0.16).opacity(opacity)
        case .classic: return Color(red: 0.12, green: 0.14, blue: 0.19).opacity(opacity)
        case .midnight: return Color(red: 0.08, green: 0.11, blue: 0.22).opacity(opacity)
        case .ember: return Color(red: 0.18, green: 0.11, blue: 0.09).opacity(opacity)
        case .matrix: return Color(red: 0.05, green: 0.10, blue: 0.07).opacity(opacity)
        case .rose: return Color(red: 0.16, green: 0.10, blue: 0.18).opacity(opacity)
        case .cyberpunk: return Color(red: 0.12, green: 0.08, blue: 0.22).opacity(opacity)
        case .solarized: return Color(red: 0.15, green: 0.18, blue: 0.20).opacity(opacity)
        case .monochrome: return Color(red: 0.12, green: 0.12, blue: 0.12).opacity(opacity)
        case .nordic: return Color(red: 0.18, green: 0.22, blue: 0.28).opacity(opacity)
        case .custom:
            let hex = UserDefaults.standard.string(forKey: "custom_hex_card") ?? "#16213E"
            return (Color(hexString: hex) ?? Color(red: 0.13, green: 0.13, blue: 0.16)).opacity(opacity)
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

// MARK: - Color Extensions for Tahoe Theme
extension Color {
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
