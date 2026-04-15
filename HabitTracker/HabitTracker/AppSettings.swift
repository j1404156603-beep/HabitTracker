import Combine
import Foundation
import SwiftUI

@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("settings.notificationsEnabled") var notificationsEnabled: Bool = true
    @AppStorage("settings.syncEnabled") var syncEnabled: Bool = true

    enum Appearance: String, CaseIterable, Identifiable {
        case system
        case dark
        case light

        var id: String { rawValue }

        var labelKey: LocalizedStringKey {
            switch self {
            case .system: return "appearance_system"
            case .dark: return "appearance_dark"
            case .light: return "appearance_light"
            }
        }

        var preferredColorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .dark: return .dark
            case .light: return .light
            }
        }
    }

    @AppStorage("settings.appearance") var appearanceRawValue: String = Appearance.system.rawValue

    var appearance: Appearance {
        get { Appearance(rawValue: appearanceRawValue) ?? .system }
        set { appearanceRawValue = newValue.rawValue }
    }

    enum AppLanguage: String, CaseIterable, Identifiable {
        case zhHans = "zh-Hans"
        case en = "en"

        var id: String { rawValue }

        var displayNameKey: LocalizedStringKey {
            switch self {
            case .zhHans: return "settings_language_zh"
            case .en: return "settings_language_en"
            }
        }

        var locale: Locale {
            Locale(identifier: rawValue)
        }
    }

    @AppStorage("settings.language") var languageRawValue: String = AppLanguage.zhHans.rawValue

    var language: AppLanguage {
        get { AppLanguage(rawValue: languageRawValue) ?? .zhHans }
        set { languageRawValue = newValue.rawValue }
    }
}

