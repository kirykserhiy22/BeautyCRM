//
//  ReminderSettingsView.swift
//  BeautyCRM
//
//  Налаштування → Нагадування: чи нагадувати перед записом, за скільки,
//  і чи нагадувати завершити запис. Розклад перебудовує ReminderSyncView сам.
//

import SwiftUI
import UserNotifications
import SwiftData

struct ReminderSettingsView: View {

    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var appState: AppState
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var context

    @Query private var profiles: [UserProfile]

    // Нагадування клієнтам: редагуємо копію, у профіль — при виході з екрана
    @State private var address = ""
    @State private var template = ""
    @State private var signature = ""
    @State private var didLoad = false

    private var profile: UserProfile? {
        profiles.first { $0.authUserID == appState.session.userID }
    }

    @AppStorage(ReminderSettings.beforeEnabledKey) private var beforeEnabled = true
    @AppStorage(ReminderSettings.leadKey) private var leadRaw = ReminderLead.hour1.rawValue
    @AppStorage(ReminderSettings.finishEnabledKey) private var finishEnabled = true

    // Сповіщення вимкнені в налаштуваннях iPhone — показуємо підказку
    @State private var isDenied = false

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    var body: some View {

        Form {

            if isDenied {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Label(
                            localization.localizedString(for: "reminders.denied"),
                            systemImage: "bell.slash"
                        )
                        .foregroundColor(colors.warning)

                        Button(localization.localizedString(for: "reminders.openSettings")) {
                            if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .accessibilityIdentifier("reminders.openSettings")
                    }
                    .padding(.vertical, 4)
                }
                .brandRows(colors)
            }

            Section {

                Toggle(localization.localizedString(for: "reminders.before"), isOn: $beforeEnabled)
                    .accessibilityIdentifier("reminders.before")

                if beforeEnabled {
                    Picker(localization.localizedString(for: "reminders.lead"), selection: $leadRaw) {
                        ForEach(ReminderLead.allCases) { lead in
                            Text(localization.localizedString(for: lead.titleKey)).tag(lead.rawValue)
                        }
                    }
                    .accessibilityIdentifier("reminders.lead")
                }

                Toggle(localization.localizedString(for: "reminders.finish"), isOn: $finishEnabled)
                    .accessibilityIdentifier("reminders.finish")

            } header: {
                Text(localization.localizedString(for: "reminders.section.me"))
            } footer: {
                Text(localization.localizedString(for: "reminders.footer"))
            }
            .brandRows(colors)

            clientSections
        }
        .brandForm(colors)
        .navigationTitle(localization.localizedString(for: "settings.reminders"))
        .task {
            await refreshPermission()
        }
        .onAppear(perform: loadClientSettings)
        .onDisappear(perform: saveClientSettings)
        .onChange(of: scenePhase) { _, phase in
            // Повернулись із налаштувань iPhone — перевірити ще раз
            if phase == .active {
                Task { await refreshPermission() }
            }
        }
    }

    // MARK: - CLIENTS

    @ViewBuilder
    private var clientSections: some View {

        Section {

            TextField(localization.localizedString(for: "clientMessage.addressPlaceholder"), text: $address, axis: .vertical)
                .accessibilityIdentifier("reminders.address")

        } header: {
            Text(localization.localizedString(for: "reminders.section.clients"))
        } footer: {
            Text(localization.localizedString(for: "clientMessage.addressFooter"))
        }
        .brandRows(colors)

        Section {

            // Поле росте разом із текстом — без прокрутки всередині
            TextField("", text: $template, axis: .vertical)
                .lineLimit(4...14)
                .accessibilityIdentifier("reminders.template")

            // Вставки: тап додає в кінець тексту
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(ClientMessageToken.allCases) { token in
                        Button {
                            insert(token)
                        } label: {
                            Text(tokenTitle(token))
                                .font(.footnote.weight(.medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(colors.cardSecondary)
                                .foregroundColor(colors.accent)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack {
                Text(localization.localizedString(for: "clientMessage.signature"))
                    .foregroundColor(colors.textPrimary)
                // Порожньо — підписуємо ім'ям майстра
                TextField(profile?.firstName ?? "", text: $signature)
                    .multilineTextAlignment(.trailing)
                    .accessibilityIdentifier("reminders.signature")
            }

            Button(localization.localizedString(for: "clientMessage.reset")) {
                template = editableDefaultTemplate
            }
            .disabled(template == editableDefaultTemplate)

        } header: {
            Text(localization.localizedString(for: "clientMessage.template.title"))
        } footer: {
            Text(localization.localizedString(for: "clientMessage.template.footer"))
        }
        .brandRows(colors)

        Section {
            Text(preview)
                .font(.subheadline)
                .foregroundColor(colors.textSecondary)
                .padding(.vertical, 4)
        } header: {
            Text(localization.localizedString(for: "clientMessage.preview"))
        }
        .brandRows(colors)
    }

    private func tokenTitle(_ token: ClientMessageToken) -> String {
        localization.localizedString(for: token.titleKey)
    }

    private var editableDefaultTemplate: String {
        ClientMessageTemplate.localized(ClientReminderText.defaultTemplate(localization), title: tokenTitle)
    }

    // Приклад: завтра о 14:00
    private var preview: String {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let start = Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: tomorrow) ?? tomorrow
        let values = ClientReminderText.values(
            clientName: localization.localizedString(for: "clientMessage.sampleName"),
            start: start,
            services: [localization.localizedString(for: "clientMessage.sampleService")],
            price: "",
            address: address,
            localization: localization
        )
        let signatureText = signature.trimmingCharacters(in: .whitespaces).isEmpty ? profile?.firstName : signature
        return ClientMessageTemplate.render(
            template: ClientMessageTemplate.neutral(template, title: tokenTitle),
            values: values,
            signature: signatureText
        )
    }

    private func insert(_ token: ClientMessageToken) {
        let piece = "{\(tokenTitle(token))}"
        if template.isEmpty || template.hasSuffix(" ") || template.hasSuffix("\n") {
            template += piece
        } else {
            template += " " + piece
        }
    }

    private func loadClientSettings() {
        guard !didLoad else { return }
        didLoad = true
        address = profile?.reminderAddress ?? ""
        signature = profile?.reminderSignature ?? ""
        template = ClientMessageTemplate.localized(
            ClientReminderText.template(profile: profile, localization: localization),
            title: tokenTitle
        )
    }

    private func saveClientSettings() {
        guard let profile, didLoad else { return }

        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSignature = signature.trimmingCharacters(in: .whitespacesAndNewlines)
        let neutral = ClientMessageTemplate.neutral(template, title: tokenTitle)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        // Стандартний текст не зберігаємо: тоді він міняється разом із мовою додатку
        let isDefault = neutral.isEmpty || neutral == ClientReminderText.defaultTemplate(localization)

        let newAddress = trimmedAddress.isEmpty ? nil : trimmedAddress
        let newSignature = trimmedSignature.isEmpty ? nil : trimmedSignature
        let newTemplate = isDefault ? nil : neutral

        guard newAddress != profile.reminderAddress
                || newSignature != profile.reminderSignature
                || newTemplate != profile.reminderTemplate else {
            return
        }

        profile.reminderAddress = newAddress
        profile.reminderSignature = newSignature
        profile.reminderTemplate = newTemplate
        _ = context.saveReportingErrors()
    }

    private func refreshPermission() async {
        let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        isDenied = status == .denied
    }
}
