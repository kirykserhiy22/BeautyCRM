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
    @EnvironmentObject var profession: ProfessionManager

    // Старий акаунт без спеціалізації — один раз попросити обрати
    @State private var showProfessionPrompt = false

    // Гід по додатку — один раз після реєстрації
    @State private var showGuide = false

    private enum Tab: String, Hashable {
        case home, clients, calendar, analytics, settings
    }

    @State private var tab: Tab = .home

    // Зміна номера перебудовує вкладку з головного екрана (див. TabReset.swift)
    @State private var resets: [Tab: Int] = [:]

    // Тап по вкладці: покинута скидається; повторний тап по поточній — теж
    private var selection: Binding<Tab> {
        Binding(
            get: { tab },
            set: { newTab in
                reset(tab)
                tab = newTab
            }
        )
    }

    private func reset(_ old: Tab) {
        guard !UnsavedForms.shared.hasUnsaved(in: old.rawValue) else {
            return
        }
        resets[old, default: 0] += 1
    }

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }


    var body: some View {

        TabView(selection: selection) {
            HomeView()
                .environment(\.formTab, Tab.home.rawValue)
                .id(resets[.home, default: 0])
                .tabItem {
                    Label("tab.home", systemImage: "house")
                }
                .tag(Tab.home)

            ClientsListView()
                .environment(\.formTab, Tab.clients.rawValue)
                .id(resets[.clients, default: 0])
                .tabItem {
                    Label("tab.clients", systemImage: "person.3")
                }
                .tag(Tab.clients)

            CalendarScreen()
                .environment(\.formTab, Tab.calendar.rawValue)
                .id(resets[.calendar, default: 0])
                .tabItem {
                    Label("tab.calendar", systemImage: "calendar")
                }
                .tag(Tab.calendar)

            AnalyticsView()
                .environment(\.formTab, Tab.analytics.rawValue)
                .id(resets[.analytics, default: 0])
                .tabItem {
                    Label("tab.analytics", systemImage: "chart.bar")
                }
                .tag(Tab.analytics)

            SettingsView()
                .environment(\.formTab, Tab.settings.rawValue)
                .id(resets[.settings, default: 0])
                .tabItem {
                    Label("tab.settings", systemImage: "gear")
                }
                .tag(Tab.settings)
        }
        .tint(colors.accent)
        // Нагадування майстру стежать за записами
        .background(ReminderSyncView())
        // Тап по нагадуванню — запис відкривається на Головній
        .onChange(of: appState.openAppointmentID) { _, id in
            if id != nil {
                tab = .home
            }
        }
        // «Переглянути» день з Головної — перейти в Календар (Головна скидається, як при звичайному перемиканні)
        .onChange(of: appState.openCalendarDay) { _, day in
            if day != nil, tab != .calendar {
                reset(tab)
                tab = .calendar
            }
        }
        .task {
            if let userID = appState.session.userID {
                SyncTracking.prepareWorkspace(
                    context: context,
                    userID: userID
                )

                if let profile = UserProfileManager.profile(context: context, userID: userID),
                   profile.profession == nil {
                    showProfessionPrompt = true
                }

                showGuide = OnboardingStore.isPending(userID: userID)

                // Робочий простір і профіль на сервері (якщо без інтернету — наступного разу)
                if let profile = UserProfileManager.profile(context: context, userID: userID) {
                    await ServerAccount.push(profile: profile)
                }
            }
        }
        // Поверх вкладок, а не окремим вікном: не конфліктує з вибором спеціалізації
        .overlay {
            if showGuide {
                OnboardingView {
                    if let userID = appState.session.userID {
                        OnboardingStore.markSeen(userID: userID)
                    }
                    withAnimation(.easeOut(duration: 0.25)) {
                        showGuide = false
                    }
                }
                .transition(.opacity)
            }
        }
        .fullScreenCover(isPresented: $showProfessionPrompt) {
            ProfessionPromptView { chosen in
                if let userID = appState.session.userID,
                   let profile = UserProfileManager.profile(context: context, userID: userID) {
                    profession.choose(chosen, for: profile, context: context)
                }
                showProfessionPrompt = false
            }
            .environmentObject(theme)
            .environmentObject(localization)
        }
    }
}
