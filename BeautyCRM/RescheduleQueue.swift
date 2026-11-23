//
//  RescheduleQueue.swift
//  BeautyCRM
//
//  «Чекають перенесення»: записи, які майстер скасував з позначкою «Перенести пізніше»
//  (захворів, невідкладні справи). Ці клієнти — у пріоритеті: їх треба записати першими.
//
//  RescheduleQueue — чистий розрахунок списку (перевіряють тести).
//  RescheduleBanner — плашка на Головній, RescheduleListView — сам список.
//

import SwiftUI
import SwiftData


// MARK: - LOGIC

enum RescheduleQueue {

    // Хто чекає нової дати: найдавніший скасований запис — першим.
    // Клієнтів, яких уже видалили, не показуємо.
    static func waiting(_ appointments: [Appointment], activeClientIDs: Set<UUID>) -> [Appointment] {
        appointments
            .filter {
                $0.status == .cancelled
                    && $0.rescheduleRequestedAt != nil
                    && $0.deletedAt == nil
                    && activeClientIDs.contains($0.clientID)
            }
            .sorted { $0.startDate < $1.startDate }
    }
}


// MARK: - HOME BANNER

struct RescheduleBanner: View {

    let count: Int

    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    var body: some View {

        NavigationLink {
            RescheduleListView()
        } label: {

            HStack(spacing: 14) {

                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.title2)
                    .foregroundColor(colors.warning)

                VStack(alignment: .leading, spacing: 3) {
                    Text(localization.localizedString(for: "reschedule.title"))
                        .font(.headline)
                        .foregroundColor(colors.textPrimary)
                    Text(localization.localizedString(for: "reschedule.banner.subtitle"))
                        .font(.subheadline)
                        .foregroundColor(colors.textSecondary)
                }

                Spacer()

                Text("\(count)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(minWidth: 30, minHeight: 30)
                    .padding(.horizontal, 4)
                    .background(Capsule().fill(colors.warning))

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(colors.textSecondary)
            }
            .padding(18)
            .background(RoundedRectangle(cornerRadius: 22).fill(colors.card))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(colors.warning.opacity(0.5), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("reschedule.banner")
    }
}


// MARK: - LIST

struct RescheduleListView: View {

    @Environment(\.modelContext) private var context
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager

    @Query private var appointments: [Appointment]
    @Query(filter: #Predicate<Client> { $0.deletedAt == nil })
    private var clients: [Client]

    @State private var booking: Appointment?
    @State private var notifying: Appointment?

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    private var waiting: [Appointment] {
        let userID = appState.session.userID
        return RescheduleQueue.waiting(
            appointments.filter { $0.userID == userID },
            activeClientIDs: Set(clients.filter { $0.userID == userID }.map(\.id))
        )
    }

    var body: some View {

        List {

            Section {
                Text(localization.localizedString(for: "reschedule.hint"))
                    .font(.subheadline)
                    .foregroundColor(colors.textSecondary)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
            }

            if waiting.isEmpty {
                EmptyStateView(
                    systemImage: "checkmark.circle",
                    titleKey: "reschedule.empty.title",
                    messageKey: "reschedule.empty.message"
                )
                .listRowBackground(Color.clear)
            }

            ForEach(waiting) { appointment in
                row(appointment)
                    .listRowBackground(colors.card)
                    .swipeActions(edge: .trailing) {
                        // Клієнт відмовився або домовились інакше
                        Button(role: .destructive) {
                            AppointmentEngine.finishReschedule(appointment: appointment)
                            context.saveReportingErrors()
                        } label: {
                            Label(localization.localizedString(for: "reschedule.dismiss"), systemImage: "xmark")
                        }
                    }
            }
        }
        .scrollContentBackground(.hidden)
        .background(colors.background)
        .navigationTitle(localization.localizedString(for: "reschedule.title"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $booking) { appointment in
            AppointmentFormView(preselectedClientID: appointment.clientID, rescheduling: appointment)
        }
        // Повідомити клієнта: те саме вікно, що й нагадування, але текст майстер пише сам
        .sheet(item: $notifying) { appointment in
            ClientReminderView(appointment: appointment, purpose: .reschedule)
        }
    }

    private func row(_ appointment: Appointment) -> some View {

        HStack(spacing: 12) {

            VStack(alignment: .leading, spacing: 4) {

                Text(appointment.clientName)
                    .font(.headline)
                    .foregroundColor(colors.textPrimary)

                Text(appointment.services.map(\.serviceName).joined(separator: " · "))
                    .font(.subheadline)
                    .foregroundColor(colors.textSecondary)
                    .lineLimit(2)

                Text(
                    String(
                        format: localization.localizedString(for: "reschedule.wasAt"),
                        AppFormatting.template("dMMMM", appointment.startDate, locale: localization.locale)
                            + ", " + AppFormatting.clock(appointment.startDate)
                    )
                )
                .font(.caption)
                .foregroundColor(colors.warning)

                if let notified = appointment.rescheduleNotifiedAt {
                    Label(
                        String(
                            format: localization.localizedString(for: "reschedule.notified"),
                            AppFormatting.pattern("d MMM, HH:mm", notified, locale: localization.locale)
                        ),
                        systemImage: "checkmark.circle"
                    )
                    .font(.caption)
                    .foregroundColor(colors.success)
                }
            }

            Spacer()

            VStack(spacing: 8) {

                Button {
                    booking = appointment
                } label: {
                    Text(localization.localizedString(for: "reschedule.book"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(minWidth: 96)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(colors.buttonPrimary))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("reschedule.book")

                Button {
                    notifying = appointment
                } label: {
                    Text(localization.localizedString(for: "reschedule.notify"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(colors.accent)
                        .frame(minWidth: 96)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(Capsule().stroke(colors.accent, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("reschedule.notify")
            }
        }
        .padding(.vertical, 6)
    }
}
