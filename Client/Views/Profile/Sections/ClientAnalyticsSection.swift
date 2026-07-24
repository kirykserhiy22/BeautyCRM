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
                    title: "Visits",
                    value: "\(analytics.totalVisits)",
                    icon: "calendar"
                )

                ClientStatCard(
                    title: "Completed",
                    value: "\(analytics.completedVisits)",
                    icon: "checkmark.circle"
                )

                ClientStatCard(
                    title: "Revenue",
                    value: currency.format(analytics.revenue),
                    icon: "eurosign.circle"
                )

                ClientStatCard(
                    title: "Cancelled",
                    value: "\(analytics.cancelledVisits)",
                    icon: "xmark.circle"
                )
            }

            // EXTRA STATS

            VStack(spacing: 12) {

                analyticsRow(
                    title: "Average Check",
                    value: currency.format(
                        analytics.averageCheck
                    )
                )

                analyticsRow(
                    title: "Last Visit",
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
            return "No visits yet"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        return formatter.string(from: date)
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
