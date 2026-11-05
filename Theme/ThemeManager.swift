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
    
    private let storage = ThemeStorage()
    
    // MARK: - LOAD
    
    func loadSavedTheme() {
        currentTheme = storage.load()
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

            // MARK: - SPACE GRAY
            
        case .classic:
            
            return ThemeColors(
                
                // SCREEN
                background: Color(.systemGroupedBackground),
                secondaryBackground: Color(.systemGray6),
                
                // CARDS
                card: .white,
                cardSecondary: Color(.systemGray5),
                
                // TEXT
                textPrimary: .black,
                textSecondary: .gray,
                textMuted: Color(.systemGray3),
                
                // BRAND
                accent: .blue,
                
                // BUTTONS
                buttonPrimary: .blue,
                buttonSecondary: Color(.systemGray4),
                buttonDestructive: .red,
                
                // STATUS
                success: .green,
                warning: .orange,
                danger: .red,
                
                // UI
                divider: Color.black.opacity(0.06),
                border: Color.black.opacity(0.05),
                shadow: Color.black.opacity(0.08),
                
                // INPUTS
                inputBackground: .white,
                
                // FLOATING BUTTON
                floatingButton: .black,
                tabBarBackground: .white,
                
                tabBarInactive:
                    Color.gray.opacity(0.7)
            )
            
            // MARK: - BLACK
            
        case .graphite:

            return ThemeColors(

                // SCREEN
                background: Color(
                    red: 175 / 255,
                    green: 180 / 255,
                    blue: 187 / 255
                ),

                secondaryBackground: Color(
                    red: 190 / 255,
                    green: 194 / 255,
                    blue: 200 / 255
                ),

                // CARDS
                card: Color(.systemGray5),

                cardSecondary: Color(
                    red: 247 / 255,
                    green: 247 / 255,
                    blue: 248 / 255
                ),

                // TEXT
                textPrimary: Color(
                    red: 35 / 255,
                    green: 38 / 255,
                    blue: 42 / 255
                ),

                textSecondary: Color(
                    red: 96 / 255,
                    green: 101 / 255,
                    blue: 108 / 255
                ),

                textMuted: Color(
                    red: 150 / 255,
                    green: 154 / 255,
                    blue: 160 / 255
                ),

                // BRAND
                accent: Color(
                    red: 84 / 255,
                    green: 92 / 255,
                    blue: 104 / 255
                ),

                // BUTTONS
                buttonPrimary: Color(
                    red: 84 / 255,
                    green: 92 / 255,
                    blue: 104 / 255
                ),

                buttonSecondary: Color(
                    red: 210 / 255,
                    green: 214 / 255,
                    blue: 220 / 255
                ),

                buttonDestructive: .red,

                // STATUS
                success: .green,
                warning: .orange,
                danger: .red,

                // UI
                divider: Color.black.opacity(0.05),

                border: Color.black.opacity(0.06),

                shadow: Color.black.opacity(0.06),

                // INPUTS
                inputBackground: .white,

                // FLOATING BUTTON
                floatingButton: Color(
                    red: 65 / 255,
                    green: 72 / 255,
                    blue: 82 / 255
                ),

                // TAB BAR
                tabBarBackground: Color(
                    red: 232 / 255,
                    green: 234 / 255,
                    blue: 237 / 255
                ),

                tabBarInactive: Color.gray
            )
                // MARK: - ELITE LIGHT
                
        case .pearlivory:

            return ThemeColors(

                // SCREEN
                background: Color(
                    red: 247 / 255,
                    green: 246 / 255,
                    blue: 242 / 255
                ),

                secondaryBackground: Color(
                    red: 235 / 255,
                    green: 233 / 255,
                    blue: 228 / 255
                ),


                // CARDS
                card: Color(
                    red: 255 / 255,
                    green: 255 / 255,
                    blue: 252 / 255
                ),

                cardSecondary: Color(
                    red: 241 / 255,
                    green: 239 / 255,
                    blue: 234 / 255
                ),


                // TEXT
                textPrimary: Color(
                    red: 45 / 255,
                    green: 43 / 255,
                    blue: 38 / 255
                ),

                textSecondary: Color(
                    red: 110 / 255,
                    green: 105 / 255,
                    blue: 95 / 255
                ),

                textMuted: Color(
                    red: 160 / 255,
                    green: 155 / 255,
                    blue: 145 / 255
                ),


                // BRAND
                accent: Color(
                    red: 145 / 255,
                    green: 120 / 255,
                    blue: 80 / 255
                ),


                // BUTTONS
                buttonPrimary: Color(
                    red: 135 / 255,
                    green: 110 / 255,
                    blue: 75 / 255
                ),

                buttonSecondary: Color(
                    red: 225 / 255,
                    green: 220 / 255,
                    blue: 210 / 255
                ),

                buttonDestructive: .red,


                // STATUS
                success: .green,
                warning: .orange,
                danger: .red,


                // UI
                divider: Color.black.opacity(0.04),

                border: Color(
                    red: 215 / 255,
                    green: 210 / 255,
                    blue: 200 / 255
                ),

                shadow: Color.black.opacity(0.05),


                // INPUTS
                inputBackground: Color(
                    red: 252 / 255,
                    green: 250 / 255,
                    blue: 245 / 255
                ),


                // FLOATING BUTTON
                floatingButton: Color(
                    red: 125 / 255,
                    green: 100 / 255,
                    blue: 65 / 255
                ),


                // TAB BAR
                tabBarBackground: Color(
                    red: 250 / 255,
                    green: 249 / 255,
                    blue: 246 / 255
                ),

                tabBarInactive:
                    Color(
                        red: 135 / 255,
                        green: 130 / 255,
                        blue: 120 / 255
                    )
            )
        }
    }
}
