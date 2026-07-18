//
//  VisualEffects.swift
//  AMD Power Gadget
//
//  Color helpers and surface tokens for the Tahoe design system.
//  Extracted from MainDashboardView.swift and cleaned up during post-refactor audit.
//

import SwiftUI

// MARK: - Panel Metric Colors
enum PanelMetricColor {
    static func green(for scheme: ColorScheme) -> Color { scheme == .light ? Color(red: 0.00, green: 0.44, blue: 0.18) : .green }
    static func cyan(for scheme: ColorScheme) -> Color { scheme == .light ? Color(red: 0.00, green: 0.43, blue: 0.54) : .cyan }
    static func mint(for scheme: ColorScheme) -> Color { scheme == .light ? Color(red: 0.00, green: 0.44, blue: 0.40) : .mint }
    static func yellow(for scheme: ColorScheme) -> Color { scheme == .light ? Color(red: 0.56, green: 0.36, blue: 0.00) : .yellow }
    static func red(for scheme: ColorScheme) -> Color { scheme == .light ? Color(red: 0.68, green: 0.08, blue: 0.10) : .red }
    static func orange(for scheme: ColorScheme) -> Color { scheme == .light ? Color(red: 0.68, green: 0.30, blue: 0.00) : .orange }
    static func pink(for scheme: ColorScheme) -> Color { scheme == .light ? Color(red: 0.68, green: 0.06, blue: 0.34) : .pink }
}

