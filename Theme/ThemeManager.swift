//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 30.04.26.
//
import SwiftUI
import Combine

final class ThemeManager: ObservableObject {
    
    @Published var currentTheme: AppTheme = .spaceGray
    
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
            
        // MARK: - SPACE GRAY
            
        case .spaceGray:
            
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
                textMuted: Color(.systemGray6),
                
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
                floatingButton: .black
            )
            
        // MARK: - BLACK
            
        case .black:
            
            return ThemeColors(
                
                // SCREEN
                background: .black,
                secondaryBackground: Color(.systemGray6),
                
                // CARDS
                card: Color(
                    red: 28 / 255,
                    green: 28 / 255,
                    blue: 30 / 255
                ),
                
                cardSecondary: Color(
                    red: 44 / 255,
                    green: 44 / 255,
                    blue: 46 / 255
                ),
                
                // TEXT
                textPrimary: .white,
                textSecondary: Color(.systemGray3),
                textMuted: Color(.systemGray),
                
                // BRAND
                accent: .white,
                
                // BUTTONS
                buttonPrimary: .white,
                buttonSecondary: Color(.darkGray),
                buttonDestructive: .red,
                
                // STATUS
                success: .green,
                warning: .orange,
                danger: .red,
                
                // UI
                divider: Color.white.opacity(0.08),
                border: Color.white.opacity(0.06),
                shadow: Color.white.opacity(0.05),
                
                // INPUTS
                inputBackground: Color(
                    red: 44 / 255,
                    green: 44 / 255,
                    blue: 46 / 255
                ),
                
                // FLOATING BUTTON
                floatingButton: .white
            )
            
        // MARK: - ELITE LIGHT
            
        case .eliteLight:
            
            return ThemeColors(
                
                // SCREEN
                background: Color(
                    red: 248 / 255,
                    green: 248 / 255,
                    blue: 250 / 255
                ),
                
                secondaryBackground: .white,
                
                // CARDS
                card: .white,
                
                cardSecondary: Color(
                    red: 242 / 255,
                    green: 242 / 255,
                    blue: 247 / 255
                ),
                
                // TEXT
                textPrimary: .black,
                textSecondary: Color(.darkGray),
                textMuted: .gray,
                
                // BRAND
                accent: .purple,
                
                // BUTTONS
                buttonPrimary: .purple,
                buttonSecondary: Color(.systemGray5),
                buttonDestructive: .red,
                
                // STATUS
                success: .green,
                warning: .orange,
                danger: .red,
                
                // UI
                divider: Color.black.opacity(0.04),
                border: Color.black.opacity(0.05),
                shadow: Color.black.opacity(0.05),
                
                // INPUTS
                inputBackground: .white,
                
                // FLOATING BUTTON
                floatingButton: .purple
            )
        }
    }
}
