//
//  VisualEffectComponents.swift
//  AMD Power Gadget
//
//  Extracted from MainDashboardView.swift (2026) — Visual Effect Blur Background
//

import SwiftUI

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
