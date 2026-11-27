//
//  SettingsView.swift
//  BeautyCRM
//
//  Налаштування: картка майстра і групи «Робота», «Додаток», «Акаунт».
//  Праворуч у рядках — поточне значення, щоб не відкривати кожен екран.
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

    @Query(filter: #Predicate<Service> { $0.deletedAt == nil })
    private var services: [Service]

    // Профіль — запитом, щоб рядки оновились одразу після змін на підекранах
    @Query private var profiles: [UserProfile]

    @State private var showGuide = false

    @State private var showDeleteAccount = false

    // Підпис рядка «Нагадування» оновлюється одразу після змін
    @AppStorage(ReminderSettings.beforeEnabledKey) private var remindersBefore = true
    @AppStorage(ReminderSettings.leadKey) private var remindersLead = ReminderLead.hour1.rawValue

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    private var profile: UserProfile? {
        guard let userID = appState.session.userID else {
            return nil
        }
        return profiles.first { $0.authUserID == userID }
            ?? UserProfileManager.profile(context: context, userID: userID)
    }

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(alignment: .leading, spacing: 8) {

                    masterCard
                        .padding(.bottom, 8)

                    groupTitle("settings.group.work")

                    group {
                        // Значок послуг — від спеціалізації, як на Головній
                        link(title: "settings.services", icon: profession.config.serviceIcon.image, value: serviceCountText) {
                            ServicesListView()
                        }
                        divider
                        link(title: "settings.workingHours", icon: Image(systemName: "clock"), value: workingHoursText) {
                            WorkingHoursSettingsView()
                        }
                        divider
                        link(title: "settings.reminders", icon: Image(systemName: "bell"), value: remindersText) {
                            ReminderSettingsView()
                        }
                        divider
                        link(title: "settings.profession", icon: Image(systemName: "person.text.rectangle"), value: professionTitle) {
                            ProfessionSettingsView()
                        }
                    }

                    groupTitle("settings.group.app")

                    group {
                        link(
                            title: "settings.appearance",
                            icon: Image(systemName: "circle.lefthalf.filled"),
                            value: localization.localizedString(for: theme.appearance.titleKey)
                        ) {
                            ThemeSettingsView()
                        }
                        divider
                        link(title: "settings.language", icon: Image(systemName: "globe"), value: languageTitle) {
                            LanguageSettingsView()
                        }
                        divider
                        link(title: "signup.currency.label", icon: Image(systemName: "banknote"), value: profile?.currencyCode) {
                            CurrencySettingsView()
                        }
                        divider
                        Button {
                            showGuide = true
                        } label: {
                            row(title: "settings.guide", icon: Image(systemName: "questionmark.circle"), value: nil, isDestructive: false)
                        }
                        .accessibilityIdentifier("settings.guide")
                    }

                    // Політика, умови, підтримка — вимога App Store і зручність для майстра
                    groupTitle("settings.group.about")

                    group {
                        Link(destination: Constants.privacyPolicyURL) {
                            row(title: "settings.privacy", icon: Image(systemName: "hand.raised"), value: nil, isDestructive: false)
                        }
                        .accessibilityIdentifier("settings.privacy")
                        divider
                        Link(destination: Constants.termsURL) {
                            row(title: "settings.terms", icon: Image(systemName: "doc.text"), value: nil, isDestructive: false)
                        }
                        .accessibilityIdentifier("settings.terms")
                        divider
                        Link(destination: Constants.supportURL) {
                            row(title: "settings.support", icon: Image(systemName: "envelope"), value: Constants.supportEmail, isDestructive: false)
                        }
                        .accessibilityIdentifier("settings.support")
                    }

                    groupTitle("settings.group.account")

                    group {
                        Button {
                            appState.session.logout()
                            profession.reset()
                            router.currentScreen = .welcome
                        } label: {
                            row(title: "settings.logout", icon: Image(systemName: "rectangle.portrait.and.arrow.right"), value: nil, isDestructive: true)
                        }
                        .accessibilityIdentifier("settings.logout")
                        divider
                        // Вимога App Store: акаунт можна видалити прямо в додатку
                        Button {
                            showDeleteAccount = true
                        } label: {
                            row(title: "settings.deleteAccount", icon: Image(systemName: "trash"), value: nil, isDestructive: true)
                        }
                        .accessibilityIdentifier("settings.deleteAccount")
                    }

                    Text("\(Constants.appName) \(appVersion)")
                        .font(.footnote)
                        .foregroundColor(colors.textMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 16)
                }
                .padding()
            }
            .background(colors.background)
            .navigationTitle(localization.localizedString(for: "settings.title"))
            .sheet(isPresented: $showDeleteAccount) {
                DeleteAccountView()
            }
            .fullScreenCover(isPresented: $showGuide) {
                OnboardingView {
                    showGuide = false
                }
                .environmentObject(theme)
                .environmentObject(localization)
            }
        }
    }

    // MARK: - MASTER CARD

    private var masterCard: some View {

        NavigationLink {
            ProfileSettingsView()
        } label: {

            HStack(spacing: 14) {

                Circle()
                    .fill(colors.cardSecondary)
                    .frame(width: 54, height: 54)
                    .overlay(
                        Text(String((profile?.firstName ?? "").prefix(1)))
                            .font(.title2.bold())
                            .foregroundColor(colors.accent)
                    )

                VStack(alignment: .leading, spacing: 3) {

                    Text(profileName)
                        .font(.headline)
                        .foregroundColor(colors.textPrimary)
                        .lineLimit(1)

                    Text(masterSubtitle)
                        .font(.subheadline)
                        .foregroundColor(colors.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(colors.textMuted)
            }
            .padding()
            .background(colors.card)
            .cornerRadius(18)
        }
        .accessibilityIdentifier("settings.profile")
    }

    // MARK: - VALUES

    private var profileName: String {
        guard let profile else {
            return localization.localizedString(for: "settings.profile")
        }
        return "\(profile.firstName) \(profile.lastName)"
    }

    // «Перукар · Studio Demo»; без салону — лише спеціалізація
    private var masterSubtitle: String {
        [professionTitle, profile?.businessName]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }

    private var professionTitle: String {
        guard let current = profession.current else {
            return localization.localizedString(for: "settings.profession.notSelected")
        }
        return localization.localizedString(for: current.config.titleKey)
    }

    private var serviceCountText: String {
        let userID = appState.session.userID
        return "\(services.filter { $0.userID == userID }.count)"
    }

    private var workingHoursText: String {
        let hours = DayTimeScale.workingHours(profile)
        if hours.isFlexible {
            return localization.localizedString(for: "settings.schedule.flexible")
        }
        return "\(timeText(hours.startMinute))–\(timeText(hours.endMinute))"
    }

    // «за 1 годину» або «Вимкнено»
    private var remindersText: String {
        guard remindersBefore else {
            return localization.localizedString(for: "reminders.off")
        }
        return localization.localizedString(for: (ReminderLead(rawValue: remindersLead) ?? .hour1).titleKey)
    }

    private var languageTitle: String? {
        SupportedLanguage.all.first { $0.code == localization.languageCode }?.title
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    private func timeText(_ minute: Int) -> String {
        String(format: "%d:%02d", minute / 60, minute % 60)
    }

    // MARK: - ROWS

    private func groupTitle(_ key: String) -> some View {
        Text(localization.localizedString(for: key))
            .font(.footnote.weight(.semibold))
            .foregroundColor(colors.textSecondary)
            .padding(.horizontal, 4)
            .padding(.top, 8)
    }

    private func group<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(colors.card)
        .cornerRadius(18)
    }

    private var divider: some View {
        Divider()
            .overlay(colors.divider)
            .padding(.leading, 52)
    }

    private func link<Destination: View>(
        title: String,
        icon: Image,
        value: String?,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {

        NavigationLink {
            destination()
        } label: {
            row(title: title, icon: icon, value: value, isDestructive: false)
        }
        .accessibilityIdentifier(title)
    }

    private func row(title: String, icon: Image, value: String?, isDestructive: Bool) -> some View {

        HStack(spacing: 14) {

            icon
                .font(.headline)
                .foregroundColor(isDestructive ? colors.danger : colors.accent)
                .frame(width: 24)

            Text(localization.localizedString(for: title))
                .foregroundColor(isDestructive ? colors.danger : colors.textPrimary)

            Spacer()

            if let value {
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(colors.textSecondary)
                    .lineLimit(1)
            }

            if !isDestructive {
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(colors.textMuted)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}


// MARK: - CURRENCY

// Валюта окремим екраном: суми не перераховуються, змінюється лише позначка
struct CurrencySettingsView: View {

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var currency: CurrencyManager

    @Environment(\.modelContext)
    private var context

    // Валюта, яку майстер вибрав, — чекає підтвердження
    @State private var pendingCode: String?

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

        List {

            Section {

                ForEach(SupportedCurrency.all) { item in

                    Button {
                        // Суми не перераховуються — спершу попередити
                        if profile?.currencyCode != item.code {
                            pendingCode = item.code
                        }
                    } label: {
                        HStack {
                            Text("\(item.symbol)  \(localization.localizedString(for: "currency.\(item.code)"))")
                                .foregroundColor(colors.textPrimary)
                            Spacer()
                            if profile?.currencyCode == item.code {
                                Image(systemName: "checkmark")
                                    .foregroundColor(colors.accent)
                            }
                        }
                    }
                    .listRowBackground(colors.card)
                }

            } footer: {
                Text(localization.localizedString(for: "settings.profile.currencyNote"))
            }
        }
        .scrollContentBackground(.hidden)
        .background(colors.background)
        .navigationTitle(localization.localizedString(for: "signup.currency.label"))
        .alert(
            String(
                format: localization.localizedString(for: "currency.change.title"),
                pendingCode ?? ""
            ),
            isPresented: Binding(
                get: { pendingCode != nil },
                set: { if !$0 { pendingCode = nil } }
            )
        ) {
            Button(localization.localizedString(for: "currency.change.confirm")) {
                if let code = pendingCode {
                    choose(code)
                }
                pendingCode = nil
            }
            Button(localization.localizedString(for: "common.cancel"), role: .cancel) {
                pendingCode = nil
            }
        } message: {
            Text(localization.localizedString(for: "settings.profile.currencyNote"))
        }
    }

    private func choose(_ code: String) {

        guard let profile, profile.currencyCode != code else {
            return
        }

        let saved = UserProfileManager.update(
            profile: profile,
            firstName: profile.firstName,
            lastName: profile.lastName,
            businessName: profile.businessName ?? "",
            currencyCode: code,
            context: context
        )

        if saved {
            currency.setCurrency(code)
        }
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
    @State private var isFlexible = true

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

            // Вільний чи фіксований графік — картками, щоб майстер упізнав свій варіант
            Section {
                scheduleCard(flexible: true)
                scheduleCard(flexible: false)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
            .listRowSeparator(.hidden)

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

            } header: {
                Text(localization.localizedString(for: isFlexible ? "settings.schedule.windowHeader" : "settings.schedule.hoursHeader"))
            } footer: {
                Text(localization.localizedString(for: isFlexible ? "settings.schedule.flexibleFooter" : "settings.workingHours.description"))
            }
            .brandRows(colors)
        }
        .brandForm(colors)
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
            isFlexible = hours.isFlexible
        }
        .onChange(of: isFlexible) {
            save()
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
        profile.flexibleSchedule = isFlexible
        context.saveReportingErrors()
    }

    private func scheduleCard(flexible: Bool) -> some View {

        let isSelected = isFlexible == flexible
        let key = flexible ? "settings.schedule.flexible" : "settings.schedule.fixed"

        return Button {
            guard !isSelected else { return }
            withAnimation(.easeOut(duration: 0.15)) {
                isFlexible = flexible
                // Вільний графік починається зі звичної рамки 8:00–20:00
                if flexible {
                    startMinute = DayTimeScale.defaultFlexibleWindow.startMinute
                    endMinute = DayTimeScale.defaultFlexibleWindow.endMinute
                }
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? colors.accent : colors.textMuted)
                VStack(alignment: .leading, spacing: 4) {
                    Text(localization.localizedString(for: key))
                        .font(.headline)
                        .foregroundColor(colors.textPrimary)
                    Text(localization.localizedString(for: key + ".hint"))
                        .font(.subheadline)
                        .foregroundColor(colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16).fill(colors.card))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? colors.accent : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(flexible ? "schedule.flexible" : "schedule.fixed")
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

// Ім'я і назва салону. Валюта — окремим рядком у Налаштуваннях
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
            .brandRows(colors)

            Section(localization.localizedString(for: "signup.business.title")) {

                TextField(localization.localizedString(for: "signup.business.name"), text: $businessName)
            }
            .brandRows(colors)

            if !errorKey.isEmpty {
                Text(localization.localizedString(for: errorKey))
                    .foregroundColor(colors.danger)
                    .font(.caption)
                    .listRowBackground(Color.clear)
            }
        }
        .brandForm(colors)
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneButton()
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
