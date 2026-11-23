//
//  PostponeAppointments.swift
//  BeautyCRM
//
//  «Відкласти записи з … по …»: майстер захворів чи має невідкладні справи.
//  Записи в ці дні скасовуються з позначкою «Перенести пізніше» (список «Чекають перенесення»),
//  а самі дні за бажанням стають вихідними. Готових текстів клієнтам немає — майстер пише сам.
//
//  PostponePlan — чистий розрахунок (тести), PostponeAppointmentsView — екран із чеклистом.
//

import SwiftUI
import SwiftData


// MARK: - LOGIC

enum PostponePlan {

    // Найдовший проміжок за один раз — щоб випадково не вибрати рік
    static let maxDays = 62

    // Дні від «з» до «по» включно (не більше maxDays)
    static func days(from: Date, to: Date, calendar: Calendar = .current) -> [Date] {
        let start = calendar.startOfDay(for: min(from, to))
        let end = calendar.startOfDay(for: max(from, to))
        var result: [Date] = []
        var day = start
        while day <= end && result.count < maxDays {
            result.append(day)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return result
    }

    // Які записи відкладати: заплановані в ці дні, які ще не закінчились; від ранніх до пізніх
    static func appointments(
        _ appointments: [Appointment],
        from: Date,
        to: Date,
        now: Date,
        calendar: Calendar = .current
    ) -> [Appointment] {
        let keys = Set(days(from: from, to: to, calendar: calendar).map { DayOff.key(for: $0, calendar: calendar) })
        return appointments
            .filter {
                $0.status == .active
                    && $0.deletedAt == nil
                    && $0.endDate > now
                    && keys.contains(DayOff.key(for: $0.startDate, calendar: calendar))
            }
            .sorted { $0.startDate < $1.startDate }
    }

    // Відкласти: кожен запис — «Перенести пізніше»
    static func postpone(_ appointments: [Appointment], now: Date = Date()) {
        for appointment in appointments {
            AppointmentEngine.cancel(appointment: appointment, rescheduleLater: true, now: now)
        }
    }

    // Дні, яких ще немає серед вихідних
    static func newDaysOff(
        days: [Date],
        existingKeys: Set<String>,
        calendar: Calendar = .current
    ) -> [Date] {
        days.filter { !existingKeys.contains(DayOff.key(for: $0, calendar: calendar)) }
    }
}


// MARK: - SCREEN

struct PostponeAppointmentsView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager

    @Query private var allAppointments: [Appointment]
    @Query(filter: #Predicate<DayOff> { $0.deletedAt == nil })
    private var dayOffs: [DayOff]

    @State private var from = Date()
    @State private var to = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var makeDaysOff = true
    // Записи, з яких майстер зняв галочку (решта — відкладаються)
    @State private var excluded: Set<UUID> = []

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    private var found: [Appointment] {
        let userID = appState.session.userID
        return PostponePlan.appointments(
            allAppointments.filter { $0.userID == userID },
            from: from,
            to: to,
            now: Date()
        )
    }

    private var selected: [Appointment] {
        found.filter { !excluded.contains($0.id) }
    }

    var body: some View {

        let found = found
        let selectedCount = found.filter { !excluded.contains($0.id) }.count

        ScrollView {

            VStack(alignment: .leading, spacing: 16) {

                Text(localization.localizedString(for: "postpone.hint"))
                    .font(.subheadline)
                    .foregroundColor(colors.textSecondary)
                    .padding(.horizontal, 4)

                VStack(spacing: 0) {
                    DatePicker(
                        localization.localizedString(for: "postpone.from"),
                        selection: $from,
                        displayedComponents: .date
                    )
                    .padding(.vertical, 6)

                    Divider().overlay(colors.divider)

                    DatePicker(
                        localization.localizedString(for: "postpone.to"),
                        selection: $to,
                        in: from...,
                        displayedComponents: .date
                    )
                    .padding(.vertical, 6)

                    Divider().overlay(colors.divider)

                    Toggle(localization.localizedString(for: "postpone.makeDaysOff"), isOn: $makeDaysOff)
                        .padding(.vertical, 6)
                        .accessibilityIdentifier("postpone.makeDaysOff")
                }
                .foregroundColor(colors.textPrimary)
                .environment(\.locale, localization.locale)
                .formCard(colors)

                FormSectionTitle(
                    text: localization.localizedString(for: "postpone.section"),
                    colors: colors
                )

                if found.isEmpty {
                    Text(localization.localizedString(for: "postpone.empty"))
                        .font(.subheadline)
                        .foregroundColor(colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .formCard(colors)
                } else {
                    VStack(spacing: 0) {
                        ForEach(found) { appointment in
                            row(appointment)
                            if appointment.id != found.last?.id {
                                Divider().overlay(colors.divider)
                            }
                        }
                    }
                    .formCard(colors)
                }

                FormPrimaryButton(
                    title: selectedCount > 0
                        ? String(format: localization.localizedString(for: "postpone.button"), selectedCount)
                        : localization.localizedString(for: "postpone.daysOffOnly"),
                    isEnabled: selectedCount > 0 || makeDaysOff,
                    colors: colors
                ) {
                    apply()
                }
                .accessibilityIdentifier("postpone.apply")
            }
            .padding()
        }
        .background(colors.background)
        .tint(colors.accent)
        .navigationTitle(localization.localizedString(for: "postpone.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: from) { _, newValue in
            if to < newValue {
                to = newValue
            }
        }
    }

    private func row(_ appointment: Appointment) -> some View {

        let isOn = !excluded.contains(appointment.id)

        return Button {
            if isOn {
                excluded.insert(appointment.id)
            } else {
                excluded.remove(appointment.id)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isOn ? colors.accent : colors.textSecondary)

                VStack(alignment: .leading, spacing: 3) {
                    Text(appointment.clientName)
                        .font(.headline)
                        .foregroundColor(colors.textPrimary)
                    Text(
                        AppFormatting.template("EEdMMMM", appointment.startDate, locale: localization.locale)
                            + ", " + AppFormatting.clock(appointment.startDate)
                            + " · " + appointment.services.map(\.serviceName).joined(separator: ", ")
                    )
                    .font(.subheadline)
                    .foregroundColor(colors.textSecondary)
                    .lineLimit(2)
                }

                Spacer()
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("postpone.row")
    }

    private func apply() {

        PostponePlan.postpone(selected)

        if makeDaysOff, let userID = appState.session.userID {
            let existingKeys = Set(dayOffs.filter { $0.userID == userID }.map(\.dayKey))
            let days = PostponePlan.days(from: from, to: to)
            for day in PostponePlan.newDaysOff(days: days, existingKeys: existingKeys) {
                context.insert(DayOff(userID: userID, date: day))
            }
        }

        if context.saveReportingErrors() {
            dismiss()
        }
    }
}
