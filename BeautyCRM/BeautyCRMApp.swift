//
//  BeautyCRMApp.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 30.04.26.
//
import SwiftUI
import SwiftData

@main
struct BeautyCRMApp: App {
    
    @StateObject private var appState = AppState()
    @StateObject private var router = AppRouter()
    @StateObject private var theme = ThemeManager()
    @StateObject private var localization = LocalizationManager()
    @StateObject private var currency = CurrencyManager()
    @StateObject private var profession = ProfessionManager()


    init() {
        SyncTracking.start()
    }

    var body: some Scene {
        
        WindowGroup {
            
            RootView()
                // Фірмова тема йде за iPhone. Старі теми лише світлі: у темному режимі
                // частина їхніх кольорів темніє, і текст зливається з фоном (#24).
                .preferredColorScheme(theme.currentTheme.followsSystemAppearance ? nil : .light)
                .tint(theme.colors(for: theme.currentTheme).accent)
                .environment(\.locale, localization.locale)
                .environmentObject(appState)
                .environmentObject(router)
                .environmentObject(theme)
                .environmentObject(localization)
                .environmentObject(currency)
                .environmentObject(profession)
                .onAppear {
                    currency.setLocale(localization.locale)
                }
                .onChange(of: localization.languageCode) {
                    currency.setLocale(localization.locale)
                }
                .modelContainer(for: [
                    UserProfile.self,
                    Client.self,
                    Appointment.self,
                    Service.self,
                    DayOff.self
                ])
                .onAppear {
                    theme.loadSavedTheme()
                }
        }
    }
}
