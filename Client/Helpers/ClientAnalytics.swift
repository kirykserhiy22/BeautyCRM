//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 23.05.26.
//

import Foundation

struct ClientAnalytics {

    let totalVisits: Int
    let completedVisits: Int
    let cancelledVisits: Int

    let revenue: Double
    let averageCheck: Double

    let lastVisitDate: Date?
}

enum ClientAnalyticsCalculator {

    static func calculate(
        client: Client,
        appointments: [Appointment]
    ) -> ClientAnalytics {

        // appointments for this client

        let clientAppointments = appointments.filter {
            $0.clientID == client.id
        }

        // completed

        let completed = clientAppointments.filter {
            $0.status == .completed
        }

        // cancelled
        // Archived appointments were cancelled before archiving

        let cancelled = clientAppointments.filter {

            $0.status == .cancelled ||
            $0.status == .archived

        }

        // revenue

        let revenue = completed.reduce(0) {
            $0 + ($1.finalPrice ?? 0)
        }

        // average

        let averageCheck: Double

        if completed.isEmpty {

            averageCheck = 0

        } else {

            averageCheck = revenue / Double(completed.count)
        }

        // last visit

        let lastVisit = completed
            .sorted {
                $0.startDate > $1.startDate
            }
            .first?
            .startDate

        return ClientAnalytics(
            totalVisits: clientAppointments.count,
            completedVisits: completed.count,
            cancelledVisits: cancelled.count,
            revenue: revenue,
            averageCheck: averageCheck,
            lastVisitDate: lastVisit
        )
    }
}
