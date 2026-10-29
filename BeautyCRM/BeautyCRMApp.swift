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
                // Теми поки світлі: у темному режимі iPhone частина їхніх кольорів
                // темніє, а частина ні, і текст зливається з фоном (#24).
                // Прибрати, коли в тем з'являться темні палітри.
                .preferredColorScheme(.light)
                .environment(\.locale, localization.locale)
                .environmentObject(appState)
                .environmentObject(router)
                .environmentObject(theme)
                .environmentObject(localization)
                .environmentObject(currency)
                .environmentObject(profession)
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
