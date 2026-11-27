//
//  ClientVisitHistory.swift
//  BeautyCRM
//
//  Історія візитів клієнта: усі його записи за датами — що робили, скільки
//  планували і скільки заплатили, нотатки. З будь-якого візиту — «Записати так само».
//
//  ClientVisitHistory — чистий розрахунок (список, фільтр, групи за роками), його перевіряють тести.
//  ClientVisitHistoryView / ClientVisitDetailView — екрани.
//

import SwiftUI
import SwiftData


// MARK: - LOGIC

enum ClientVisitFilter: String, CaseIterable, Identifiable {
    case all
    case completed
    case cancelled

    var id: String { rawValue }
    var titleKey: String { "visits.filter.\(rawValue)" }
}

enum ClientVisitHistory {

    // Записи клієнта для історії: від нових до старих.
    // «Приховані» (archived) — це теж скасовані, тож показуємо їх разом зі скасованими.
    static func visits(
        clientID: UUID,
        appointments: [Appointment],
        filter: ClientVisitFilter
    ) -> [Appointment] {
        appointments
            .filter { $0.clientID == clientID && $0.deletedAt == nil }
            .filter { appointment in
                switch filter {
                case .all: return true
                case .completed: return appointment.status == .completed
                case .cancelled: return isCancelled(appointment)
                }
            }
            .sorted { $0.startDate > $1.startDate }
    }

    // Групи за роками, свіжий рік першим
    static func byYear(_ visits: [Appointment], calendar: Calendar = .current) -> [(year: Int, visits: [Appointment])] {
        let groups = Dictionary(grouping: visits) { calendar.component(.year, from: $0.startDate) }
        return groups.keys.sorted(by: >).map { ($0, groups[$0] ?? []) }
    }

    static func isCancelled(_ appointment: Appointment) -> Bool {
        appointment.status == .cancelled || appointment.status == .archived
    }

    // Скільки заплачено — лише для завершених (як у підсумках картки клієнта)
    static func paid(_ appointment: Appointment) -> Decimal? {
        guard appointment.status == .completed else {
            return nil
        }
        return appointment.netPrice ?? appointment.totalFinalPrice
    }

    // Ціна послуги у візиті: фактична для завершених, інакше погоджена
    static func price(of item: AppointmentServiceItem, in appointment: Appointment) -> Decimal {
        appointment.status == .completed ? (item.finalPrice ?? item.plannedPrice) : item.plannedPrice
    }

    // «Записати так само»: які послуги з прайсу взяти і з якими цінами.
    // Фіксована ціна — з теперішнього прайсу (вона могла змінитися),
    // змінна — та, що заплатили минулого разу. Послуг, яких уже немає в прайсі, не беремо.
    static func repeatPlan(
        of appointment: Appointment,
        services: [Service]
    ) -> (services: [Service], customPrices: [UUID: Decimal]) {
        var picked: [Service] = []
        var prices: [UUID: Decimal] = [:]
        for item in appointment.services {
            guard let service = services.first(where: { $0.id == item.serviceID && $0.deletedAt == nil }),
                  !picked.contains(where: { $0.id == service.id }) else {
                continue
            }
            picked.append(service)
            if service.pricingType == .variable {
                prices[service.id] = price(of: item, in: appointment)
            }
        }
        return (picked, prices)
    }
}


// MARK: - HISTORY SCREEN

struct ClientVisitHistoryView: View {

    let client: Client

    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var currency: CurrencyManager

    @Query private var appointments: [Appointment]

    @State private var filter: ClientVisitFilter = .all

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    var body: some View {

        let visits = ClientVisitHistory.visits(clientID: client.id, appointments: appointments, filter: filter)

        ScrollView {

            VStack(alignment: .leading, spacing: 14) {

                Picker("", selection: $filter) {
                    ForEach(ClientVisitFilter.allCases) { item in
                        Text(localization.localizedString(for: item.titleKey)).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("visits.filter")

                if visits.isEmpty {
                    EmptyStateView(
                        systemImage: "calendar.badge.clock",
                        titleKey: "visits.empty.title",
                        messageKey: "visits.empty.message"
                    )
                    .padding(.top, 24)
                }

                ForEach(ClientVisitHistory.byYear(visits), id: \.year) { group in

                    Text(String(group.year))
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(colors.textSecondary)
                        .padding(.horizontal, 4)
                        .padding(.top, 6)

                    ForEach(group.visits) { visit in
                        NavigationLink {
                            ClientVisitDetailView(appointment: visit, clientID: client.id)
                        } label: {
                            row(visit)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .background(colors.background)
        .navigationTitle(localization.localizedString(for: "visits.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ visit: Appointment) -> some View {

        let cancelled = ClientVisitHistory.isCancelled(visit)
        let upcoming = visit.status == .active && visit.endDate > Date()
        let paid = ClientVisitHistory.paid(visit)

        return VStack(alignment: .leading, spacing: 6) {

            HStack(alignment: .firstTextBaseline) {

                Text(AppFormatting.template("dMMMM", visit.startDate, locale: localization.locale))
                    .font(.headline)
                    .foregroundColor(colors.textPrimary)

                if cancelled {
                    badge("visits.badge.cancelled", color: colors.danger)
                } else if upcoming {
                    badge("visits.badge.upcoming", color: colors.accent)
                } else if visit.status == .active {
                    badge("visits.badge.notCompleted", color: colors.warning)
                }

                Spacer()

                Text(paid.map(currency.format) ?? (cancelled ? "—" : currency.format(visit.totalPlannedPrice)))
                    .font(.headline)
                    .foregroundColor(paid == nil ? colors.textSecondary : colors.textPrimary)
            }

            Text(visit.services.map(\.serviceName).joined(separator: " · "))
                .font(.subheadline)
                .foregroundColor(colors.textSecondary)
                .lineLimit(2)

            // Заплатили не стільки, скільки планували — видно одразу.
            // Було повернення — тут повна оплата, а повернення окремим рядком нижче
            let fullPaid = visit.refundAmount != nil ? (visit.finalPrice ?? paid) : paid
            if let fullPaid, fullPaid != visit.totalPlannedPrice {
                Text(
                    String(
                        format: localization.localizedString(for: "visits.plannedPaid"),
                        currency.format(visit.totalPlannedPrice),
                        currency.format(fullPaid)
                    )
                )
                .font(.caption)
                .foregroundColor(colors.textSecondary)
            }

            // Повернення і причина — як у картці запису
            if visit.status == .completed, let refund = visit.refundAmount {
                Text(refundLine(refund, reason: visit.refundReason))
                    .font(.caption)
                    .foregroundColor(colors.warning)
                    .lineLimit(2)
            }

            if let notes = visit.notes?.trimmingCharacters(in: .whitespacesAndNewlines), !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(colors.textSecondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(colors.card)
        .cornerRadius(16)
        .opacity(cancelled ? 0.75 : 1)
        .contentShape(Rectangle())
    }

    private func refundLine(_ refund: Decimal, reason: String?) -> String {
        let amount = String(format: localization.localizedString(for: "refund.line"), currency.format(refund))
        guard let reason, !reason.isEmpty else { return amount }
        return "\(amount) · \(reason)"
    }

    private func badge(_ key: String, color: Color) -> some View {
        Text(localization.localizedString(for: key))
            .font(.caption2.weight(.semibold))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(color.opacity(0.15)))
    }
}


// MARK: - VISIT DETAIL

struct ClientVisitDetailView: View {

    let appointment: Appointment
    let clientID: UUID

    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var currency: CurrencyManager

    @State private var showRepeat = false

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    var body: some View {

        let paid = ClientVisitHistory.paid(appointment)
        let refund = appointment.status == .completed ? appointment.refundAmount : nil

        ScrollView {

            VStack(alignment: .leading, spacing: 16) {

                Text(
                    AppFormatting.template("EEEEdMMMMyyyy", appointment.startDate, locale: localization.locale)
                    + " · "
                    + AppFormatting.clock(appointment.startDate) + "–" + AppFormatting.clock(appointment.endDate)
                )
                .font(.headline)
                .foregroundColor(colors.textPrimary)

                VStack(spacing: 0) {

                    ForEach(appointment.services) { item in
                        HStack {
                            Text(item.serviceName)
                                .foregroundColor(colors.textPrimary)
                            Spacer()
                            Text(currency.format(ClientVisitHistory.price(of: item, in: appointment)))
                                .foregroundColor(colors.textPrimary)
                        }
                        .font(.subheadline)
                        .padding(.vertical, 10)

                        Divider().overlay(colors.divider)
                    }

                    // Повернення: спершу скільки заплатили, потім скільки повернули
                    if let refund = refund, let fullPrice = appointment.finalPrice {
                        HStack {
                            Text(localization.localizedString(for: "visits.paid"))
                            Spacer()
                            Text(currency.format(fullPrice))
                        }
                        .font(.subheadline)
                        .foregroundColor(colors.textPrimary)
                        .padding(.vertical, 10)

                        HStack {
                            Text(localization.localizedString(for: "visits.refunded"))
                            Spacer()
                            Text("−" + currency.format(refund))
                        }
                        .font(.subheadline)
                        .foregroundColor(colors.warning)
                        .padding(.bottom, 10)

                        Divider().overlay(colors.divider)
                    }

                    HStack {
                        Text(localization.localizedString(
                            for: paid == nil ? "visits.planned" : (refund == nil ? "visits.paid" : "visits.received")
                        ))
                            .fontWeight(.semibold)
                        Spacer()
                        Text(currency.format(paid ?? appointment.totalPlannedPrice))
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(colors.textPrimary)
                    .padding(.vertical, 10)

                    if let paid, paid != appointment.totalPlannedPrice {
                        Text(
                            String(
                                format: localization.localizedString(for: "visits.plannedWas"),
                                currency.format(appointment.totalPlannedPrice)
                            )
                        )
                        .font(.caption)
                        .foregroundColor(colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 8)
                    }
                }
                .padding(.horizontal)
                .background(colors.card)
                .cornerRadius(16)

                if let reason = appointment.refundReason, refund != nil {
                    Text(localization.localizedString(for: "visits.refundReason"))
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(colors.textSecondary)
                        .padding(.horizontal, 4)

                    Text(reason)
                        .foregroundColor(colors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(colors.card)
                        .cornerRadius(16)
                        .accessibilityIdentifier("visits.refundReason")
                }

                if let notes = appointment.notes?.trimmingCharacters(in: .whitespacesAndNewlines), !notes.isEmpty {
                    Text(localization.localizedString(for: "visits.notes"))
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(colors.textSecondary)
                        .padding(.horizontal, 4)

                    Text(notes)
                        .foregroundColor(colors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(colors.card)
                        .cornerRadius(16)
                }

                // Головна економія часу: ті самі послуги й ціни — лишається вибрати дату
                Button {
                    showRepeat = true
                } label: {
                    Label(localization.localizedString(for: "visits.repeat"), systemImage: "arrow.clockwise")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(colors.buttonPrimary)
                        .cornerRadius(16)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("visits.repeat")

                Text(localization.localizedString(for: "visits.repeatHint"))
                    .font(.caption)
                    .foregroundColor(colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .background(colors.background)
        .navigationTitle(appointment.clientName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showRepeat) {
            AppointmentFormView(preselectedClientID: clientID, repeating: appointment)
        }
    }
}
