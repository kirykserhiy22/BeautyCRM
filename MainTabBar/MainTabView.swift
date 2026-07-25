//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 30.04.26.
//
import SwiftUI
import SwiftData

struct MainTabView: View {

    @Environment(\.modelContext) private var context
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var currency: CurrencyManager
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var theme: ThemeManager

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }


    var body: some View {

        TabView {

            HomeView()
                .tabItem {
                    Label(
                        "Home",
                        systemImage: "house"
                    )
                }


            ClientsListView()
                .tabItem {
                    Label(
                        "Clients",
                        systemImage: "person.3"
                    )
                }


            CalendarScreen()
                .tabItem {
                    Label(
                        "Calendar",
                        systemImage: "calendar"
                    )
                }


            AnalyticsView()
                .tabItem {
                    Label(
                        "Analytics",
                        systemImage: "chart.bar"
                    )
                }


            SettingsView()
                .tabItem {
                    Label(
                        "Settings",
                        systemImage: "gear"
                    )
                }
        }
        .tint(colors.accent)
    }
}
