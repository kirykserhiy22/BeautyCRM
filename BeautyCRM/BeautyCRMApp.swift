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


    init() {
        SyncTracking.start()
    }

    var body: some Scene {
        
        WindowGroup {
            
            RootView()
                .environment(\.locale, localization.locale)
                .environmentObject(appState)
                .environmentObject(router)
                .environmentObject(theme)
                .environmentObject(localization)
                .environmentObject(currency)
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
