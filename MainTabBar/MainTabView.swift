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
                    Label("tab.home", systemImage: "house")
                }

            ClientsListView()
                .tabItem {
                    Label("tab.clients", systemImage: "person.3")
                }

            CalendarScreen()
                .tabItem {
                    Label("tab.calendar", systemImage: "calendar")
                }

            AnalyticsView()
                .tabItem {
                    Label("tab.analytics", systemImage: "chart.bar")
                }

            SettingsView()
                .tabItem {
                    Label("tab.settings", systemImage: "gear")
                }
        }
        .tint(colors.accent)
        .task {
            if let userID = appState.session.userID {
                SyncTracking.prepareWorkspace(
                    context: context,
                    userID: userID
                )
            }
        }
    }
}
