//
//  Untitled 3.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 23.05.26.
//

import SwiftUI
import SwiftData

struct ClientAnalyticsSection: View {

    let client: Client

    @EnvironmentObject var currency: CurrencyManager
    @EnvironmentObject var localization: LocalizationManager
    @Query private var appointments: [Appointment]

    // MARK: - ANALYTICS

    private var analytics: ClientAnalytics {

        ClientAnalyticsCalculator.calculate(
            client: client,
            appointments: appointments
        )
    }

    // MARK: - BODY

    var body: some View {

        VStack(spacing: 18) {

            // GRID

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 14
            ) {

                ClientStatCard(
                    title: "clients.visits",
                    value: "\(analytics.totalVisits)",
                    icon: "calendar"
                )

                ClientStatCard(
                    title: "clients.completed",
                    value: "\(analytics.completedVisits)",
                    icon: "checkmark.circle"
                )

                ClientStatCard(
                    title: "clients.revenue",
                    value: currency.format(analytics.revenue),
                    icon: "eurosign.circle"
                )

                ClientStatCard(
                    title: "clients.cancelled",
                    value: "\(analytics.cancelledVisits)",
                    icon: "xmark.circle"
                )
            }

            // EXTRA STATS

            VStack(spacing: 12) {

                analyticsRow(
                    title: localization.localizedString(for: "clients.averageCheck"),
                    value: currency.format(
                        analytics.averageCheck
                    )
                )

                analyticsRow(
                    title: localization.localizedString(for: "clients.lastVisit"),
                    value: formattedLastVisit
                )
            }
            .padding()
            .background(.gray.opacity(0.08))
            .cornerRadius(20)
        }
    }
}

// MARK: - HELPERS

private extension ClientAnalyticsSection {

    

    var formattedLastVisit: String {

        guard let date = analytics.lastVisitDate else {
            return localization.localizedString(for: "clients.noVisitsYet")
        }

        return AppFormatting.date(
            date,
            locale: localization.locale,
            format: .medium
        )
    }

    func analyticsRow(
        title: String,
        value: String
    ) -> some View {

        HStack {

            Text(title)

            Spacer()

            Text(value)
                .fontWeight(.semibold)
        }
    }
}
