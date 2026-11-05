//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 30.04.26.
//
import Foundation

enum AppTheme: String, CaseIterable {
    // Фірмова тема Beauty Base
    case darkCherry
    case classic
    case graphite
    case pearlivory

    // Лише фірмова тема має темний варіант і йде за налаштуванням iPhone
    var followsSystemAppearance: Bool {
        self == .darkCherry
    }
}
