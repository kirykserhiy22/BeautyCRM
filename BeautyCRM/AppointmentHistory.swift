//
//  AppointmentHistory.swift
//  BeautyCRM
//
//  «Усі записи» (Головна → внизу): пошук за клієнтом чи послугою, фільтр за статусом,
//  групи за місяцями. Звідси знаходять старий запис, щоб виправити суму чи оформити повернення.
//

import SwiftUI
import SwiftData


enum AppointmentHistoryFilter: String, CaseIterable, Identifiable {
    case all, planned, completed, cancelled

    var id: String { rawValue }

    var titleKey: String { "history.filter.\(rawValue)" }

    func matches(_ status: AppointmentStatus) -> Bool {
        switch self {
        case .all: return status != .archived
        case .planned: return status == .active
        case .completed: return status == .completed
        case .cancelled: return status == .cancelled
        }
    }
}


struct AppointmentHistoryMonth: Identifiable {
    let month: Date
    let appointments: [Appointment]
    var id: Date { month }
}


enum AppointmentHistory {

    // Найновіші зверху; приховані (архів) не показуємо
    static func months(
        _ appointments: [Appointment],
        filter: AppointmentHistoryFilter,
        search: String,
        calendar: Calendar = .current
    ) -> [AppointmentHistoryMonth] {

        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)

        let matching = appointments.filter { appointment in
            guard appointment.deletedAt == nil, filter.matches(appointment.status) else {
                return false
            }
            guard !query.isEmpty else {
                return true
            }
            return appointment.clientName.localizedCaseInsensitiveContains(query)
                || appointment.services.contains { $0.serviceName.localizedCaseInsensitiveContains(query) }
        }

        let grouped = Dictionary(grouping: matching) { appointment in
            calendar.dateInterval(of: .month, for: appointment.startDate)?.start ?? appointment.startDate
        }

        return grouped
            .map { month, items in
                AppointmentHistoryMonth(
                    month: month,
                    appointments: items.sorted { $0.startDate > $1.startDate }
                )
            }
            .sorted { $0.month > $1.month }
    }
}


struct AppointmentHistoryView: View {

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var currency: CurrencyManager

    @Query(sort: \Appointment.startDate, order: .reverse) private var appointments: [Appointment]

    @State private var filter: AppointmentHistoryFilter = .all
    @State private var search = ""
    @State private var selected: Appointment?

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    private var months: [AppointmentHistoryMonth] {
        let userID = appState.session.userID
        return AppointmentHistory.months(
            appointments.filter { $0.userID == userID },
            filter: filter,
            search: search
        )
    }

    var body: some View {

        ScrollView {

            LazyVStack(alignment: .leading, spacing: 14, pinnedViews: []) {

                Picker("", selection: $filter) {
                    ForEach(AppointmentHistoryFilter.allCases) { item in
                        Text(localization.localizedString(for: item.titleKey)).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("history.filter")

                if months.isEmpty {
                    Text(localization.localizedString(for: "history.empty"))
                        .font(.subheadline)
                        .foregroundColor(colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                }

                ForEach(months) { month in

                    VStack(alignment: .leading, spacing: 0) {

                        Text(monthTitle(month.month))
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(colors.textSecondary)
                            .padding(.bottom, 8)

                        VStack(spacing: 0) {
                            ForEach(Array(month.appointments.enumerated()), id: \.element.id) { index, appointment in
                                if index > 0 {
                                    Divider().overlay(colors.divider).padding(.leading, 14)
                                }
                                Button {
                                    selected = appointment
                                } label: {
                                    row(appointment)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .background(colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }
            .padding()
        }
        .background(colors.background.ignoresSafeArea())
        .searchable(
            text: $search,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: localization.localizedString(for: "history.search")
        )
        .navigationTitle(localization.localizedString(for: "history.title"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selected) { appointment in
            AppointmentDetailScreen(appointment: appointment)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private func row(_ appointment: Appointment) -> some View {

        let isCancelled = appointment.status == .cancelled

        return HStack(alignment: .center, spacing: 10) {

            VStack(alignment: .leading, spacing: 3) {
                Text(appointment.clientName)
                    .font(.subheadline.weight(.semibold))
                    .strikethrough(isCancelled)
                    .foregroundColor(isCancelled ? colors.textSecondary : colors.textPrimary)
                Text(details(appointment))
                    .font(.caption)
                    .foregroundColor(colors.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 3) {
                Text(currency.format(amount(appointment)))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(appointment.status == .completed ? colors.textPrimary : colors.textSecondary)
                Text(localization.localizedString(for: statusKey(appointment)))
                    .font(.caption2)
                    .foregroundColor(statusColor(appointment))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
        .accessibilityIdentifier("history.row")
    }

    // «Листопад 2026» — велика лише перша літера, без «р.»
    private func monthTitle(_ month: Date) -> String {
        let text = AppFormatting.template("LLLLyyyy", month, locale: localization.locale)
            .replacingOccurrences(of: "\\s*р\\.$", with: "", options: .regularExpression)
        return text.prefix(1).uppercased() + text.dropFirst()
    }

    private func details(_ appointment: Appointment) -> String {
        let date = AppFormatting.template("dMMM", appointment.startDate, locale: localization.locale)
        let time = AppFormatting.clock(appointment.startDate)
        let services = appointment.services.map(\.serviceName).joined(separator: ", ")
        return "\(date), \(time) · \(services)"
    }

    // Завершений — що отримано (з урахуванням повернення), інші — погоджена ціна
    private func amount(_ appointment: Appointment) -> Decimal {
        appointment.status == .completed
            ? (appointment.netPrice ?? appointment.totalFinalPrice)
            : appointment.totalPlannedPrice
    }

    private func statusKey(_ appointment: Appointment) -> String {
        switch appointment.status {
        case .active:
            return appointment.endDate < Date() ? "home.waitingForCompletion" : "history.status.planned"
        case .completed:
            return appointment.refundAmount != nil ? "history.status.refunded" : "history.status.completed"
        case .cancelled:
            return appointment.rescheduleRequestedAt == nil ? "history.status.cancelled" : "appointment.status.awaitingReschedule"
        case .archived:
            return "appointment.status.archived"
        }
    }

    private func statusColor(_ appointment: Appointment) -> Color {
        switch appointment.status {
        case .active: return appointment.endDate < Date() ? colors.warning : colors.accent
        case .completed: return appointment.refundAmount != nil ? colors.warning : colors.success
        case .cancelled: return colors.danger
        case .archived: return colors.textSecondary
        }
    }
}
