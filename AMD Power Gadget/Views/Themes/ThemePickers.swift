//
// Extracted from ThemeViews.swift during post-refactor cleanup
//

import SwiftUI

struct CheckerboardBackground: View {
    var body: some View {
        Canvas { context, size in
            let cell: CGFloat = 4
            var y: CGFloat = 0
            var row = 0
            while y < size.height {
                var x: CGFloat = 0
                var col = 0
                while x < size.width {
                    let dark = (row + col) % 2 == 0
                    context.fill(
                        Path(CGRect(x: x, y: y, width: cell, height: cell)),
                        with: .color(dark ? Color.gray.opacity(0.55) : Color.white.opacity(0.85))
                    )
                    x += cell
                    col += 1
                }
                y += cell
                row += 1
            }
        }
    }
}

// MARK: - Custom Theme Studio
struct SectionWithIcon<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.tahoeAccentCyan)
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.tahoeText)
                Spacer()
            }
            content()
        }
    }
}

// MARK: - Card Opacity Editor
struct LanguagePickerCard: View {
    @AppStorage(AppLanguage.storageKey) private var languageCode: String = ""
    @State private var pendingCode: String = ""
    @State private var showRestartAlert = false

    private var languages: [AppLanguage] { AppLanguage.available }

    var body: some View {
        TahoeCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "globe")
                        .foregroundColor(.tahoeAccentCyan)
                        .font(.system(size: 16, weight: .semibold))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("App Language", comment: ""))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.tahoeText)
                        Text(NSLocalizedString("Choose the interface language. The app will restart to apply the change.", comment: ""))
                            .font(.system(size: 11))
                            .foregroundColor(.tahoeSubtext)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                }

                Picker("", selection: Binding(
                    get: { languageCode },
                    set: { newValue in
                        if newValue != languageCode {
                            pendingCode = newValue
                            showRestartAlert = true
                        }
                    }
                )) {
                    ForEach(languages) { lang in
                        Text(lang.displayName).tag(lang.rawValue)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(maxWidth: 320, alignment: .leading)
                .id(languageCode)

                Text(String(format: NSLocalizedString("Current: %@", comment: "Current language label"), currentLanguageLabel))
                    .font(.system(size: 10))
                    .foregroundColor(.tahoeSubtext)
            }
        }
        .alert(NSLocalizedString("Restart required", comment: ""), isPresented: $showRestartAlert) {
            Button(NSLocalizedString("Cancel", comment: ""), role: .cancel) {
                pendingCode = languageCode
            }
            Button(NSLocalizedString("Apply & Restart", comment: "")) {
                let lang = AppLanguage(rawValue: pendingCode) ?? .system
                AppLanguage.select(lang, relaunch: true)
            }
        } message: {
            Text(NSLocalizedString("The app needs to restart to load the selected language.", comment: ""))
        }
    }

    private var currentLanguageLabel: String {
        let lang = AppLanguage(rawValue: languageCode) ?? .system
        if lang == .system {
            let preferred = Locale.preferredLanguages.first ?? "en"
            let code = String(preferred.prefix(while: { $0 != "-" && $0 != "_" }))
            let name = Locale.current.localizedString(forLanguageCode: code) ?? code
            return "\(NSLocalizedString("System Default", comment: "")) (\(name))"
        }
        return lang.displayName
    }
}

// MARK: - Legacy Theme Selector (for backward compatibility)
typealias ThemeSelectorGrid = OptimizedThemeSelectorGrid
