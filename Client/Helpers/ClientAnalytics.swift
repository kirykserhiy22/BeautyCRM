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

    let revenue: Decimal
    let averageCheck: Decimal

    let lastVisitDate: Date?

    // Найближчий активний запис, що ще попереду
    var nextAppointmentDate: Date? = nil
}

enum ClientAnalyticsCalculator {

    // «З нами з…»: раніша з двох дат — коли клієнта додали в базу
    // чи коли він уперше прийшов (старі візити часто вносять пізніше)
    static func clientSince(
        client: Client,
        appointments: [Appointment]
    ) -> Date {

        let firstVisit = appointments
            .filter { $0.clientID == client.id && $0.status == .completed }
            .map(\.startDate)
            .min()

        return min(client.createdAt, firstVisit ?? client.createdAt)
    }

    static func calculate(
        client: Client,
        appointments: [Appointment],
        now: Date = Date()
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

        let revenue = completed.reduce(Decimal(0)) {
            $0 + ($1.finalPrice ?? 0)
        }

        // average

        let averageCheck: Decimal

        if completed.isEmpty {

            averageCheck = 0

        } else {

            averageCheck = revenue / Decimal(completed.count)
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
            lastVisitDate: lastVisit,
            nextAppointmentDate: clientAppointments
                .filter { $0.status == .active && $0.startDate >= now }
                .map(\.startDate)
                .min()
        )
    }
}
