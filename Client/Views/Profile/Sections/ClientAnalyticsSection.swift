//
//  ClientAnalyticsSection.swift
//  BeautyCRM
//
//  Коротка колонка з головним про клієнта: наступний запис, останній візит,
//  скільки разів приходив, скільки заплатив і середній чек.
//

import SwiftUI
import SwiftData

struct ClientAnalyticsSection: View {

    let client: Client

    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var currency: CurrencyManager
    @EnvironmentObject var localization: LocalizationManager
    @Query private var appointments: [Appointment]

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    private var analytics: ClientAnalytics {
        ClientAnalyticsCalculator.calculate(
            client: client,
            appointments: appointments
        )
    }

    var body: some View {

        let analytics = analytics

        VStack(spacing: 12) {

            if let next = analytics.nextAppointmentDate {
                row("clients.nextAppointment", AppFormatting.template("EEEdMMMMjmm", next, locale: localization.locale))
            }

            row("clients.lastVisit", lastVisitText(analytics.lastVisitDate))

            // Тап — уся історія візитів: що робили, скільки заплатили, нотатки
            NavigationLink {
                ClientVisitHistoryView(client: client)
            } label: {
                row("clients.visits", "\(analytics.completedVisits)", showsChevron: true)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("client.visits")

            row("clients.totalSpent", currency.format(analytics.revenue))

            row("clients.averageCheck", currency.format(analytics.averageCheck))
        }
        .padding()
        .background(colors.card)
        .cornerRadius(20)
    }

    private func row(_ titleKey: String, _ value: String, showsChevron: Bool = false) -> some View {

        HStack {

            Text(localization.localizedString(for: titleKey))
                .foregroundColor(colors.textSecondary)

            Spacer()

            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(colors.textPrimary)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(colors.accent)
            }
        }
        .font(.subheadline)
        .accessibilityElement(children: .combine)
    }

    private func lastVisitText(_ date: Date?) -> String {

        guard let date else {
            return localization.localizedString(for: "clients.noVisitsYet")
        }

        return AppFormatting.date(date, locale: localization.locale, format: .medium)
    }
}
