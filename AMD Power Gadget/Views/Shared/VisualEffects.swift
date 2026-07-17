//
// Auto-extracted during Phase 2 restructure
//

import SwiftUI

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

