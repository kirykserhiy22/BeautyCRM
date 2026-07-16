//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 30.04.26.
//
import SwiftUI

struct SettingsView: View {
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var router: AppRouter
    
    var body: some View {
        
        VStack(spacing: 20) {
            
            Text("Settings")
                .font(.title)
            
            Button("Logout") {
                appState.session.logout()
                router.currentScreen = .auth
            }
        }
    }
}
