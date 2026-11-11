//
//  ThemeStorage.swift
//  BeautyCRM
//

import Foundation

final class ThemeStorage {

    private let key = "app_theme"
    private let appearanceKey = "app_appearance"

    func save(_ theme: AppTheme) {
        UserDefaults.standard.set(theme.rawValue, forKey: key)
    }

    // Стара тема, якої вже немає, — фірмова Dark Cherry
    func load() -> AppTheme {
        guard let value = UserDefaults.standard.string(forKey: key),
              let theme = AppTheme(rawValue: value) else {
            return .darkCherry
        }
        return theme
    }

    func saveAppearance(_ mode: AppearanceMode) {
        UserDefaults.standard.set(mode.rawValue, forKey: appearanceKey)
    }

    func loadAppearance() -> AppearanceMode {
        UserDefaults.standard.string(forKey: appearanceKey)
            .flatMap(AppearanceMode.init(rawValue:)) ?? .system
    }
}
