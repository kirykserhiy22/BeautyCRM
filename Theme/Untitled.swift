//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 30.04.26.
//
import SwiftUI

final class ThemeManager: ObservableObject {
    
    @Published var currentTheme: AppTheme = .spaceGray
    
    private let storage = ThemeStorage()
    
    func loadSavedTheme() {
        currentTheme = storage.load()
    }
    
    func colors() -> ThemeColors {
        switch currentTheme {
            
        case .spaceGray:
            return ThemeColors(
                background: Color(.systemGray6),
                card: .white,
                primary: .gray,
                text: .black,
                secondaryText: .gray
            )
            
        case .black:
            return ThemeColors(
                background: .black,
                card: Color(.darkGray),
                primary: .white,
                text: .white,
                secondaryText: .gray
            )
            
        case .eliteLight:
            return ThemeColors(
                background: .white,
                card: Color(.systemGray5),
                primary: .purple,
                text: .black,
                secondaryText: .gray
            )
        }
    }
}
