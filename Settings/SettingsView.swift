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
    @EnvironmentObject var profession: ProfessionManager
    
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
                
                // MARK: - PROFILE

                NavigationLink {

                    ProfileSettingsView()

                } label: {

                    settingsRow(
                        title: "settings.profile",
                        icon: "person.crop.circle",
                        value: profileName
                    )
                }


                // MARK: - APPEARANCE
                
                NavigationLink {
                    
                    ThemeSettingsView()
                        .environmentObject(theme)
                    
                } label: {
                    
                    settingsRow(title: "settings.appearance", icon: "paintbrush")
                }
                
                
                // MARK: - PROFESSION

                NavigationLink {

                    ProfessionSettingsView()

                } label: {

                    settingsRow(
                        title: "settings.profession",
                        icon: "person.text.rectangle",
                        value: professionTitle
                    )
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

                    profession.reset()
                    
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

    // Ім'я майстра для рядка «Профіль»
    private var profileName: String? {
        guard
            let userID = appState.session.userID,
            let profile = UserProfileManager.profile(context: context, userID: userID)
        else {
            return nil
        }
        return "\(profile.firstName) \(profile.lastName)"
    }

    // Поточна спеціалізація для рядка налаштувань
    private var professionTitle: String {
        guard let current = profession.current else {
            return localization.localizedString(for: "settings.profession.notSelected")
        }
        return localization.localizedString(for: current.config.titleKey)
    }
    
    
    private func settingsRow(
        title: String,
        icon: String,
        value: String? = nil
    ) -> some View {
        
        HStack(spacing: 14) {
            
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(colors.accent)
                .frame(width: 24)
            
            
            Text(localization.localizedString(for: title))
                .foregroundColor(colors.textPrimary)
            
            
            Spacer()

            if let value {
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(colors.textSecondary)
            }
            
            
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
        context.saveReportingErrors()
    }

    private func timeText(_ minute: Int) -> String {
        String(format: "%02d:%02d", minute / 60, minute % 60)
    }
}


// MARK: - PROFESSION

// Зміна спеціалізації: вибір одразу зберігається в профіль
struct ProfessionSettingsView: View {

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var profession: ProfessionManager

    @Environment(\.modelContext)
    private var context

    @Environment(\.dismiss)
    private var dismiss

    @State private var selection: Profession?

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    var body: some View {

        ScrollView {
            ProfessionPickerView(selection: $selection, showsHeader: false)
                .padding()
        }
        .background(colors.background)
        .navigationTitle(localization.localizedString(for: "settings.profession"))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(localization.localizedString(for: "common.done")) {
                    dismiss()
                }
            }
        }
        .onAppear {
            selection = profession.current
        }
        .onChange(of: selection) {
            guard
                let selection,
                selection != profession.current,
                let userID = appState.session.userID,
                let profile = UserProfileManager.profile(context: context, userID: userID)
            else {
                return
            }
            profession.choose(selection, for: profile, context: context)
        }
    }
}


// MARK: - PROFILE

// Ім'я, назва салону і валюта — те, що вводилось при реєстрації
struct ProfileSettingsView: View {

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var currency: CurrencyManager

    @Environment(\.modelContext)
    private var context

    @Environment(\.dismiss)
    private var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var businessName = ""
    @State private var currencyCode = "EUR"

    // Ключ Localizable.strings; порожній — помилки немає
    @State private var errorKey = ""

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    private var profile: UserProfile? {
        guard let userID = appState.session.userID else {
            return nil
        }
        return UserProfileManager.profile(context: context, userID: userID)
    }

    var body: some View {

        Form {

            Section(localization.localizedString(for: "signup.profile.title")) {

                TextField(localization.localizedString(for: "signup.firstName"), text: $firstName)
                    .textContentType(.givenName)

                TextField(localization.localizedString(for: "signup.lastName"), text: $lastName)
                    .textContentType(.familyName)
            }

            Section(localization.localizedString(for: "signup.business.title")) {

                TextField(localization.localizedString(for: "signup.business.name"), text: $businessName)
            }

            Section {

                Picker(
                    localization.localizedString(for: "signup.currency.label"),
                    selection: $currencyCode
                ) {
                    ForEach(SupportedCurrency.all) { item in
                        Text("\(item.symbol) \(localization.localizedString(for: "currency.\(item.code)"))")
                            .tag(item.code)
                    }
                }

            } footer: {

                Text(localization.localizedString(for: "settings.profile.currencyNote"))
            }

            if !errorKey.isEmpty {
                Text(localization.localizedString(for: errorKey))
                    .foregroundColor(colors.danger)
                    .font(.caption)
            }
        }
        .scrollContentBackground(.hidden)
        .background(colors.background)
        .navigationTitle(localization.localizedString(for: "settings.profile"))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(localization.localizedString(for: "common.save")) {
                    save()
                }
            }
        }
        .onAppear {
            guard let profile else {
                return
            }
            firstName = profile.firstName
            lastName = profile.lastName
            businessName = profile.businessName ?? ""
            currencyCode = profile.currencyCode
        }
    }

    private func save() {

        if let key = UserProfileManager.validationErrorKey(firstName: firstName, lastName: lastName) {
            errorKey = key
            return
        }

        guard let profile else {
            return
        }

        errorKey = ""

        let saved = UserProfileManager.update(
            profile: profile,
            firstName: firstName,
            lastName: lastName,
            businessName: businessName,
            currencyCode: currencyCode,
            context: context
        )

        guard saved else {
            return
        }

        // Нова валюта — одразу в усьому додатку
        currency.setCurrency(currencyCode)
        dismiss()
    }
}
