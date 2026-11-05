//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 30.04.26.
//
import SwiftUI

extension Color {

    // Колір, що сам змінюється зі світлою й темною темою iPhone
    init(light: UInt32, dark: UInt32, lightOpacity: CGFloat = 1, darkOpacity: CGFloat = 1) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: dark, alpha: darkOpacity)
                : UIColor(hex: light, alpha: lightOpacity)
        })
    }
}

private extension UIColor {

    convenience init(hex: UInt32, alpha: CGFloat) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

struct ThemeColors {

    // SCREEN
    let background: Color
    let secondaryBackground: Color

    // CARDS
    let card: Color
    let cardSecondary: Color

    // TEXT
    let textPrimary: Color
    let textSecondary: Color
    let textMuted: Color
    

    // BRAND
    let accent: Color

    // BUTTONS
    let buttonPrimary: Color
    let buttonSecondary: Color
    let buttonDestructive: Color

    // STATUS
    let success: Color
    let warning: Color
    let danger: Color

    // UI
    let divider: Color
    let border: Color
    let shadow: Color

    // INPUTS
    let inputBackground: Color

    // FLOATING BUTTON
    let floatingButton: Color
    
    // TAB BAR

    let tabBarBackground: Color
    let tabBarInactive: Color
}
