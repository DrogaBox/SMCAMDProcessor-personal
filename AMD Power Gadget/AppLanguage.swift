//
//  AppLanguage.swift
//  AMD Power Gadget
//
//  In-app language preference (overrides system language for this app only).
//

import Foundation
import AppKit

/// User preference for app UI language.
/// - `system` (empty code): follow macOS language
/// - otherwise: ISO language code matching a bundled `*.lproj` folder (e.g. `es`, `de`)
enum AppLanguage: String, CaseIterable, Identifiable {
    case system = ""
    case english = "en"
    case spanish = "es"
    case german = "de"
    case italian = "it"
    case french = "fr"
    case portuguese = "pt"
    case dutch = "nl"
    case polish = "pl"
    case russian = "ru"
    case japanese = "ja"
    case korean = "ko"
    case chinese = "zh"
    case czech = "cs"
    case danish = "da"
    case finnish = "fi"
    case greek = "el"
    case hungarian = "hu"
    case norwegian = "no"
    case romanian = "ro"
    case swedish = "sv"
    case turkish = "tr"
    case ukrainian = "uk"
    case vietnamese = "vi"
    case arabic = "ar"
    case hebrew = "he"
    case catalan = "ca"
    case afrikaans = "af"
    case serbian = "sr"

    var id: String { rawValue }

    static let storageKey = "app_language_code"
    /// Apple's per-app language override key (UserDefaults).
    private static let appleLanguagesKey = "AppleLanguages"

    /// Languages that actually ship a Localizable.strings in the app bundle.
    static var available: [AppLanguage] {
        let bundled = Set(
            Bundle.main.localizations
                .map { $0.replacingOccurrences(of: "-", with: "_") }
                .map { String($0.prefix(while: { $0 != "_" })) }
                .filter { $0 != "Base" }
        )
        var list: [AppLanguage] = [.system]
        for lang in AppLanguage.allCases where lang != .system {
            if bundled.contains(lang.rawValue) || Bundle.main.path(forResource: lang.rawValue, ofType: "lproj") != nil {
                list.append(lang)
            }
        }
        // Always offer English even if filtering is weird
        if !list.contains(.english) { list.insert(.english, at: 1) }
        return list
    }

    static var current: AppLanguage {
        let code = UserDefaults.standard.string(forKey: storageKey) ?? ""
        return AppLanguage(rawValue: code) ?? .system
    }

    /// Display name in the *currently active* UI language when possible.
    var displayName: String {
        switch self {
        case .system:
            return NSLocalizedString("System Default", comment: "Language picker: follow macOS")
        default:
            let locale = Locale(identifier: rawValue)
            if let name = locale.localizedString(forLanguageCode: rawValue) {
                return name.capitalized(with: locale)
            }
            return rawValue
        }
    }

    /// English label for Crowdin / fallbacks.
    var englishName: String {
        switch self {
        case .system: return "System Default"
        case .english: return "English"
        case .spanish: return "Spanish"
        case .german: return "German"
        case .italian: return "Italian"
        case .french: return "French"
        case .portuguese: return "Portuguese"
        case .dutch: return "Dutch"
        case .polish: return "Polish"
        case .russian: return "Russian"
        case .japanese: return "Japanese"
        case .korean: return "Korean"
        case .chinese: return "Chinese"
        case .czech: return "Czech"
        case .danish: return "Danish"
        case .finnish: return "Finnish"
        case .greek: return "Greek"
        case .hungarian: return "Hungarian"
        case .norwegian: return "Norwegian"
        case .romanian: return "Romanian"
        case .swedish: return "Swedish"
        case .turkish: return "Turkish"
        case .ukrainian: return "Ukrainian"
        case .vietnamese: return "Vietnamese"
        case .arabic: return "Arabic"
        case .hebrew: return "Hebrew"
        case .catalan: return "Catalan"
        case .afrikaans: return "Afrikaans"
        case .serbian: return "Serbian"
        }
    }

    /// Apply the stored preference to AppleLanguages so Bundle/NSLocalizedString pick it up.
    /// Call as early as possible at launch (before building UI).
    static func applyStoredPreference() {
        let code = UserDefaults.standard.string(forKey: storageKey) ?? ""
        if code.isEmpty {
            UserDefaults.standard.removeObject(forKey: appleLanguagesKey)
        } else {
            UserDefaults.standard.set([code], forKey: appleLanguagesKey)
        }
        UserDefaults.standard.synchronize()
    }

    /// Persist selection and optionally relaunch so all UI strings reload.
    static func select(_ language: AppLanguage, relaunch: Bool) {
        UserDefaults.standard.set(language.rawValue, forKey: storageKey)
        applyStoredPreference()
        if relaunch {
            relaunchApp()
        }
    }

    static func relaunchApp() {
        let path = Bundle.main.bundlePath
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = ["-n", path]
        try? task.run()
        DispatchQueue.main.async {
            NSApplication.shared.terminate(nil)
        }
    }
}
