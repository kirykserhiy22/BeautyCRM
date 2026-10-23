//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 30.04.26.
//
import SwiftUI
import SwiftData


struct SettingsView: View {
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager
    
    @Environment(\.modelContext)
    private var context
    
    
    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }
    
    
    var body: some View {
        
        NavigationStack {
            
            VStack(
                spacing: 20
            ) {
                
                // MARK: - APPEARANCE
                
                NavigationLink {
                    
                    ThemeSettingsView()
                        .environmentObject(theme)
                    
                } label: {
                    
                    settingsRow(title: "settings.appearance", icon: "paintbrush")
                }
                
                
                // MARK: - LANGUAGE
                
                NavigationLink {
                    
                    LanguageSettingsView()
                        .environmentObject(localization)
                    
                } label: {
                    
                    settingsRow(title: "settings.language", icon: "globe")
                }
                
                
                Spacer()
                
                
                // MARK: - LOGOUT
                
                Button {
                    
                    appState.session.logout()
                    
                    router.currentScreen = .welcome
                    
                } label: {
                    
                    settingsRow(title: "settings.logout", icon: "rectangle.portrait.and.arrow.right")
                }
            }
            .padding()
            .background(colors.background)
            .navigationTitle("settings.title")
        }
    }
    
    
    // MARK: - ROW
    
    
    private func settingsRow(
        title: String,
        icon: String
    ) -> some View {
        
        HStack(spacing: 14) {
            
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(colors.accent)
                .frame(width: 24)
            
            
            Text(localization.localizedString(for: title))
                .foregroundColor(colors.textPrimary)
            
            
            Spacer()
            
            
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundColor(colors.textMuted)
        }
        .padding()
        .background(colors.card)
        .cornerRadius(16)
        .shadow(
            color: colors.shadow,
            radius: 4,
            y: 2
        )
    }
}
