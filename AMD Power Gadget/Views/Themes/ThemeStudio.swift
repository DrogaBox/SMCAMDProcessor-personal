//
// Extracted from ThemeViews.swift during post-refactor cleanup
//

import SwiftUI

struct CustomThemeStudio: View {
    @AppStorage("custom_hex_card") private var cardHex: String = "#FF16213E"
    @AppStorage("custom_hex_cyan") private var cyanHex: String = "#FF4CC9F0"
    @AppStorage("custom_hex_orange") private var orangeHex: String = "#FFFF8C00"
    @AppStorage("custom_hex_green") private var greenHex: String = "#FF00FF7F"
    @AppStorage("custom_hex_purple") private var purpleHex: String = "#FFA020F0"
    @AppStorage("app_theme_preset") private var selectedThemeRaw: String = AppTheme.tahoe.rawValue

    private func markCustom() {
        selectedThemeRaw = AppTheme.custom.rawValue
        AppTheme.postThemeChanged()
    }

    private func copyCurrentThemeToCustom() {
        let curr = AppTheme.current
        cardHex = curr.card.toHexStringARGB
        cyanHex = curr.accentCyan.toHexStringARGB
        orangeHex = curr.accentOrange.toHexStringARGB
        greenHex = curr.accentGreen.toHexStringARGB
        purpleHex = curr.accentPurple.toHexStringARGB
        selectedThemeRaw = AppTheme.custom.rawValue
        AppTheme.postThemeChanged()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Custom Theme Editor")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    Text("Use the Opacity slider for transparency (macOS color panel alone often resets alpha).")
                        .font(.system(size: 10))
                        .foregroundColor(.tahoeSubtext)
                }
                Spacer()
                TahoeButton(label: "Edit Active Theme", icon: "doc.on.doc", accent: .tahoeAccentOrange) {
                    copyCurrentThemeToCustom()
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 10)], spacing: 10) {
                ColorTokenEditorSlot(title: "Card Background", hex: $cardHex, onEdited: markCustom)
                ColorTokenEditorSlot(title: "Cyan Accent", hex: $cyanHex, onEdited: markCustom)
                ColorTokenEditorSlot(title: "Orange Accent", hex: $orangeHex, onEdited: markCustom)
                ColorTokenEditorSlot(title: "Green Accent", hex: $greenHex, onEdited: markCustom)
                ColorTokenEditorSlot(title: "Purple Accent", hex: $purpleHex, onEdited: markCustom)
            }

            Divider().background(Color.tahoeCardBorder)

            HStack(spacing: 12) {
                TahoeButton(label: "Export Theme (JSON)", icon: "square.and.arrow.up", accent: .tahoeAccentCyan) {
                    exportTheme()
                }
                TahoeButton(label: "Import Theme (JSON)", icon: "square.and.arrow.down", accent: .tahoeAccentGreen) {
                    importTheme()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.tahoeCard)
                .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
        )
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.tahoeCardBorder, lineWidth: 1))
        .cornerRadius(14)
    }

    private func exportTheme() {
        let pack = ThemePresetPack(
            name: "Mi Tema Custom",
            cardHex: Color(hexString: cardHex)?.toHexStringARGB ?? cardHex,
            cyanHex: Color(hexString: cyanHex)?.toHexStringARGB ?? cyanHex,
            orangeHex: Color(hexString: orangeHex)?.toHexStringARGB ?? orangeHex,
            greenHex: Color(hexString: greenHex)?.toHexStringARGB ?? greenHex,
            purpleHex: Color(hexString: purpleHex)?.toHexStringARGB ?? purpleHex
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(pack)
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.json]
            panel.nameFieldStringValue = "MiTemaCustom.json"
            panel.begin { resp in
                if resp == .OK, let url = panel.url {
                    do {
                        try data.write(to: url)
                    } catch {
                        DispatchQueue.main.async {
                            let alert = NSAlert()
                            alert.messageText = NSLocalizedString("Export Failed", comment: "")
                            alert.informativeText = error.localizedDescription
                            alert.alertStyle = .warning
                            alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
                            alert.runModal()
                        }
                    }
                }
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Export Failed", comment: "")
            alert.informativeText = NSLocalizedString("Could not encode theme data.", comment: "")
            alert.alertStyle = .warning
            alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
            alert.runModal()
        }
    }

    private func importTheme() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.begin { resp in
            if resp == .OK, let url = panel.url {
                do {
                    let data = try Data(contentsOf: url)
                    let pack = try JSONDecoder().decode(ThemePresetPack.self, from: data)
                    
                    cardHex = Color(hexString: pack.cardHex)?.toHexStringARGB ?? pack.cardHex
                    cyanHex = Color(hexString: pack.cyanHex)?.toHexStringARGB ?? pack.cyanHex
                    orangeHex = Color(hexString: pack.orangeHex)?.toHexStringARGB ?? pack.orangeHex
                    greenHex = Color(hexString: pack.greenHex)?.toHexStringARGB ?? pack.greenHex
                    purpleHex = Color(hexString: pack.purpleHex)?.toHexStringARGB ?? pack.purpleHex
                    selectedThemeRaw = AppTheme.custom.rawValue
                } catch {
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("Import Failed", comment: "")
                    alert.informativeText = error.localizedDescription
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
                    alert.runModal()
                }
            }
        }
    }
}

// MARK: - Themes Content View
struct ColorTokenEditorSlot: View {
    let title: LocalizedStringKey
    @Binding var hex: String
    var onEdited: () -> Void = {}

    @State private var draftRGB: Color = .white
    @State private var opacity: Double = 1.0
    @State private var suppressPush = false

    private var preview: Color {
        let c = draftRGB.resolvedRGBA
        return Color.srgb(r: c.r, g: c.g, b: c.b, a: opacity)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.tahoeSubtext)

            HStack(spacing: 8) {
                ColorPicker("", selection: $draftRGB, supportsOpacity: false)
                    .labelsHidden()
                    .onChange(of: draftRGB) { _ in
                        guard !suppressPush else { return }
                        pushHex(userEdit: true)
                    }

                RoundedRectangle(cornerRadius: 4)
                    .fill(preview)
                    .frame(width: 22, height: 22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
                    .background(
                        CheckerboardBackground()
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .frame(width: 22, height: 22)
                    )

                Text(hex)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }

            HStack(spacing: 8) {
                Text("Opacity")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.tahoeSubtext)
                    .frame(width: 48, alignment: .leading)
                Slider(value: $opacity, in: 0...1)
                    .controlSize(.small)
                    .onChange(of: opacity) { _ in
                        guard !suppressPush else { return }
                        pushHex(userEdit: true)
                    }
                Text("\(Int((opacity * 100).rounded()))%")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(width: 36, alignment: .trailing)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.04))
        .cornerRadius(8)
        .onAppear { pullFromHex() }
        .onChange(of: hex) { newValue in
            guard !suppressPush else { return }
            if newValue.uppercased() != preview.toHexStringARGB.uppercased() {
                pullFromHex()
            }
        }
    }

    private func pullFromHex() {
        suppressPush = true
        let color = Color(hexString: hex) ?? .white
        let c = color.resolvedRGBA
        draftRGB = Color.srgb(r: c.r, g: c.g, b: c.b, a: 1)
        opacity = c.a
        let normalized = Color.srgb(r: c.r, g: c.g, b: c.b, a: c.a).toHexStringARGB
        if normalized.uppercased() != hex.uppercased() {
            hex = normalized
        }
        Task { @MainActor in suppressPush = false }
    }

    private func pushHex(userEdit: Bool) {
        let c = draftRGB.resolvedRGBA
        let composed = Color.srgb(r: c.r, g: c.g, b: c.b, a: opacity)
        let next = composed.toHexStringARGB
        guard next.uppercased() != hex.uppercased() else { return }
        suppressPush = true
        hex = next
        if userEdit {
            onEdited()
        }
        Task { @MainActor in suppressPush = false }
    }
}

// MARK: - Checkerboard Background
struct CardOpacityEditorCard: View {
    @AppStorage("tahoe_card_opacity") private var cardOpacity: Double = 0.45

    var body: some View {
        TahoeCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("Adjust the opacity of the data cards background to increase readability or enhance the glassmorphism effect.", comment: ""))
                    .font(.system(size: 11))
                    .foregroundColor(.tahoeSubtext)
                
                HStack {
                    Text("0%")
                        .font(.system(size: 10))
                        .foregroundColor(.tahoeSubtext)
                    Slider(value: Binding(
                        get: { cardOpacity },
                        set: { newValue in 
                            cardOpacity = newValue
                            AppTheme.postThemeChanged()
                        }
                    ), in: 0...1, step: 0.05)
                    .accentColor(.tahoeAccentCyan)
                    
                    Text("\(Int(cardOpacity * 100))%")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.tahoeText)
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
    }
}

// MARK: - Language Picker
