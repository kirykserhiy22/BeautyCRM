//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 30.04.26.
//

import Foundation

final class AppState: ObservableObject {
    
    @Published var session = SessionManager()
    @Published var theme = ThemeManager()
    
    init() {
        theme.loadSavedTheme()
    }
}
