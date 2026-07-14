//
//  SharedComponents.swift
//  AMD Power Gadget
//
//  Extracted from MainDashboardView.swift (2026) — Reusable UI Components
//

import SwiftUI

// MARK: - TahoeCard
struct TahoeCard<Content: View>: View {
    let accent: Color
    @ViewBuilder let content: Content
    @AppStorage("theme_glass_material") private var glassMaterial: Int = 0
    @AppStorage("app_theme_preset") private var themePreset: String = AppTheme.tahoe.rawValue
    @AppStorage("custom_hex_card") private var cardHex: String = "#16213E"
    @AppStorage("tahoe_card_opacity") private var cardOpacity: Double = 0.45

    init(accent: Color = .tahoeCardBorder, @ViewBuilder content: () -> Content) {
        self.accent = accent; self.content = content()
    }

    var cardFill: Color {
        _ = themePreset
        _ = cardHex
        _ = cardOpacity
        return Color.tahoeCard
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(cardFill)
            )
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent, lineWidth: 1))
            .cornerRadius(14)
    }
}

// MARK: - TahoeButton
struct TahoeButton: View {
    let label: LocalizedStringKey; let icon: String; let accent: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon).font(.system(size: 12, weight: .semibold))
                Text(label).font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(accent)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity)
            .background(accent.opacity(0.12))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(accent.opacity(0.35)))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ToggleRow
struct ToggleRow: View {
    let label: LocalizedStringKey
    let detail: LocalizedStringKey
    @Binding var isOn: Bool
    let accent: Color
    var indented: Bool = false
    let onChange: (Bool) -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 12, weight: .semibold)).foregroundColor(.tahoeText)
                Text(detail).font(.system(size: 10)).foregroundColor(.tahoeSubtext)
            }
            .padding(.leading, indented ? 20 : 0)
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: accent))
                .labelsHidden()
                .onChange(of: isOn) { onChange($0) }
        }
        .padding(.vertical, 8)
        .padding(.leading, indented ? 28 : 14)
        .padding(.trailing, 14)
        .background(Color.tahoeCard)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.tahoeCardBorder))
        .cornerRadius(8)
    }
}

// MARK: - SidebarMiniButtonStyle
struct SidebarMiniButtonStyle: ButtonStyle {
    let accent: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 9, weight: .semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundColor(.tahoeText)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(accent.opacity(configuration.isPressed ? 0.22 : 0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(accent.opacity(0.18), lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
    }
}

// MARK: - SectionTitle
struct SectionTitle: View {
    let title: LocalizedStringKey
    init(_ title: LocalizedStringKey) { self.title = title }
    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundColor(.tahoeText)
            .textCase(.uppercase)
    }
}

// MARK: - UnsupportedFeatureOverlay
struct UnsupportedFeatureOverlay<Content: View>: View {
    let isSupported: Bool
    let reasonText: LocalizedStringKey
    @ViewBuilder let content: Content
    
    @State private var overrideDisabledBlock = false
    
    var body: some View {
        if !isSupported && !overrideDisabledBlock {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) { overrideDisabledBlock = true }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.tahoeAccentOrange)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(reasonText)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.tahoeAccentOrange)
                        Text("Haz clic para revelar la interfaz bloqueada")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.tahoeSubtext)
                    }
                    Spacer()
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .background(Color.tahoeCard)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.tahoeAccentOrange.opacity(0.6), lineWidth: 1.5))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        } else {
            if !isSupported {
                ZStack {
                    content
                        .disabled(true)
                        .opacity(0.35)
                        .blur(radius: 2.0)
                    
                    VStack {
                        Image(systemName: "eye.slash.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.8))
                        Text("Haz clic para ocultar")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)
                    
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) { overrideDisabledBlock = false }
                        }
                }
            } else {
                content
            }
        }
    }
}
