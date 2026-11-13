//
//  ReminderSettingsView.swift
//  BeautyCRM
//
//  Налаштування → Нагадування: чи нагадувати перед записом, за скільки,
//  і чи нагадувати завершити запис. Розклад перебудовує ReminderSyncView сам.
//

import SwiftUI
import UserNotifications

struct ReminderSettingsView: View {

    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager
    @Environment(\.scenePhase) private var scenePhase

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
        }
        .brandForm(colors)
        .navigationTitle(localization.localizedString(for: "settings.reminders"))
        .task {
            await refreshPermission()
        }
        .onChange(of: scenePhase) { _, phase in
            // Повернулись із налаштувань iPhone — перевірити ще раз
            if phase == .active {
                Task { await refreshPermission() }
            }
        }
    }

    private func refreshPermission() async {
        let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        isDenied = status == .denied
    }
}
