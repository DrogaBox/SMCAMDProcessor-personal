//
//  DashboardTab.swift
//  AMD Power Gadget
//
//  Extracted from MainDashboardView.swift (2026) — Dashboard Tab Definitions
//

import Foundation

enum DashboardTab: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    // rawValue is the English localization key (Crowdin source).
    case dashboard  = "Dashboard"
    case telemetry  = "Telemetry"
    case fanControl = "Fan Control"
    case themes     = "Themes & Appearance"
    case chartStyles = "Chart Styles"
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
        case .chartStyles: return "chart.line.uptrend.xyaxis"
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
