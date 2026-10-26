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
                
                
                // MARK: - WORKING HOURS

                NavigationLink {

                    WorkingHoursSettingsView()

                } label: {

                    settingsRow(title: "settings.workingHours", icon: "clock")
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



// MARK: - WORKING HOURS

// Робочі години майстра: від них залежить шкала смужки зайнятості в календарі
struct WorkingHoursSettingsView: View {

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager

    @Environment(\.modelContext)
    private var context

    @Environment(\.dismiss)
    private var dismiss

    @State private var startMinute = DayTimeScale.defaultWorkingHours.startMinute
    @State private var endMinute = DayTimeScale.defaultWorkingHours.endMinute

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    // Кожні 30 хвилин: 00:00, 00:30 … 24:00
    private let options = Array(stride(from: 0, through: 24 * 60, by: 30))

    private var profile: UserProfile? {
        guard let userID = appState.session.userID else {
            return nil
        }
        return UserProfileManager.profile(context: context, userID: userID)
    }

    var body: some View {

        Form {

            Section {

                Picker(
                    localization.localizedString(for: "settings.workingHours.start"),
                    selection: $startMinute
                ) {
                    ForEach(options.filter { $0 < 24 * 60 }, id: \.self) { minute in
                        Text(timeText(minute)).tag(minute)
                    }
                }

                Picker(
                    localization.localizedString(for: "settings.workingHours.end"),
                    selection: $endMinute
                ) {
                    ForEach(options.filter { $0 > startMinute }, id: \.self) { minute in
                        Text(timeText(minute)).tag(minute)
                    }
                }

            } footer: {

                Text(localization.localizedString(for: "settings.workingHours.description"))
            }
        }
        .scrollContentBackground(.hidden)
        .background(colors.background)
        .navigationTitle(localization.localizedString(for: "settings.workingHours"))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(localization.localizedString(for: "common.done")) {
                    save()
                    dismiss()
                }
            }
        }
        .onAppear {
            let hours = DayTimeScale.workingHours(profile)
            startMinute = hours.startMinute
            endMinute = hours.endMinute
        }
        .onChange(of: startMinute) {
            if endMinute <= startMinute {
                endMinute = startMinute + 60
            }
            save()
        }
        .onChange(of: endMinute) {
            save()
        }
    }

    private func save() {
        guard let profile, endMinute > startMinute else {
            return
        }
        profile.workStartMinute = startMinute
        profile.workEndMinute = endMinute
        try? context.save()
    }

    private func timeText(_ minute: Int) -> String {
        String(format: "%02d:%02d", minute / 60, minute % 60)
    }
}
