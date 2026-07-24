//
//  Untitled 2.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 30.04.26.
//
import Foundation

final class ThemeStorage {
    
    private let key = "app_theme"
    
    func save(_ theme: AppTheme) {
        UserDefaults.standard.set(theme.rawValue, forKey: key)
    }
    
    func load() -> AppTheme {
        guard let value = UserDefaults.standard.string(forKey: key),
              let theme = AppTheme(rawValue: value) else {
            return .spaceGray
        }
        return theme
    }
}
