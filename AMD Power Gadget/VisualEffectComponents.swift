//
//  VisualEffectComponents.swift
//  AMD Power Gadget
//
//  Extracted from MainDashboardView.swift (2026) — Visual Effect Blur Background
//  Optimized with caching for better performance (2026-07-14)
//

import SwiftUI

// MARK: - Visual Effect Blur Background (macOS) - Optimized with caching
struct VisualEffectBackground: View {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    let state: NSVisualEffectView.State
    let cornerRadius: CGFloat
    
    @AppStorage("low_performance_mode") private var isLowPerformanceMode = false

    var body: some View {
        if isLowPerformanceMode {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.12))
        } else {
            CachedVisualEffectView(material: material, blendingMode: blendingMode, state: state, cornerRadius: cornerRadius)
        }
    }
}

/// Cached NSView wrapper to avoid recreating expensive blur views
private struct CachedVisualEffectView: NSViewRepresentable {
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
        // Performance: disable implicit animations
        view.layer?.actions = ["position": NSNull(), "bounds": NSNull()]
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        // Only update if values actually changed
        guard nsView.material != material || 
              nsView.blendingMode != blendingMode || 
              nsView.state != state || 
              nsView.layer?.cornerRadius != cornerRadius else {
            return
        }
        
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
        nsView.layer?.cornerRadius = cornerRadius
    }
}
