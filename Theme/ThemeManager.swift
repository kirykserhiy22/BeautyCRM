//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 30.04.26.
//
import SwiftUI
import Combine

final class ThemeManager: ObservableObject {
    
    @Published var currentTheme: AppTheme = .darkCherry

    // Світлий чи темний вигляд: як в iPhone або вибраний вручну
    @Published var appearance: AppearanceMode = .system

    private let storage = ThemeStorage()

    // MARK: - LOAD

    func loadSavedTheme() {
        currentTheme = storage.load()
        appearance = storage.loadAppearance()
    }

    func setAppearance(_ mode: AppearanceMode) {
        appearance = mode
        storage.saveAppearance(mode)
    }
    
    // MARK: - SAVE
    
    func setTheme(_ theme: AppTheme) {
        
        currentTheme = theme
        
        storage.save(theme)
    }
    
    // MARK: - COLORS
    
    func colors(for theme: AppTheme) -> ThemeColors {
        
        switch theme {

            // MARK: - DARK CHERRY

        case .darkCherry:

            return ThemeColors(

                // SCREEN
                background: Color(light: 0xF7EFF2, dark: 0x2A0814),
                secondaryBackground: Color(light: 0xEFE3E7, dark: 0x210610),

                // CARDS
                card: Color(light: 0xFFFFFF, dark: 0x4A0E24),
                cardSecondary: Color(light: 0xF2E6EA, dark: 0x5A1830),

                // TEXT
                textPrimary: Color(light: 0x2A0814, dark: 0xFFFFFF),
                textSecondary: Color(light: 0x7A5A64, dark: 0xE3C4CE),
                textMuted: Color(light: 0xC4AEB6, dark: 0x9C6F7F),

                // BRAND
                accent: Color(light: 0xB0073A, dark: 0xFF3B6B),

                // BUTTONS
                buttonPrimary: Color(light: 0xE20942, dark: 0xE20942),
                buttonSecondary: Color(light: 0xEBD9DF, dark: 0x6B2A40),
                buttonDestructive: Color(light: 0xB0073A, dark: 0xFF3B6B),

                // STATUS
                success: Color(light: 0x3F6B4A, dark: 0xA6B8A0),
                warning: Color(light: 0xA8660B, dark: 0xE8B04A),
                danger: Color(light: 0xB0073A, dark: 0xFF3B6B),

                // UI
                divider: Color(light: 0x2A0814, dark: 0xFFFFFF, lightOpacity: 0.08, darkOpacity: 0.1),
                border: Color(light: 0x2A0814, dark: 0xFFFFFF, lightOpacity: 0.08, darkOpacity: 0.12),
                shadow: Color(light: 0x2A0814, dark: 0x000000, lightOpacity: 0.08, darkOpacity: 0.3),

                // INPUTS
                inputBackground: Color(light: 0xFFFFFF, dark: 0x3A0B1C),

                // FLOATING BUTTON
                floatingButton: Color(light: 0xE20942, dark: 0xE20942),
                tabBarBackground: Color(light: 0xFFFFFF, dark: 0x3A0B1C),

                tabBarInactive: Color(light: 0x7A5A64, dark: 0xC9A5B1)
            )
        }
    }
}


// MARK: - APPEARANCE

enum AppearanceMode: String, CaseIterable, Identifiable {

    case system
    case light
    case dark

    var id: String { rawValue }

    // nil — iOS сам вибирає за налаштуванням iPhone
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var titleKey: String {
        "settings.appearance.\(rawValue)"
    }
}
