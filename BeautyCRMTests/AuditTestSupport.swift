//
//  AuditTestSupport.swift
//  BeautyCRMTests
//
//  Спільні помічники для тестів аудиту (docs/audit/REPORT.md).
//  Тести, що описують знайдену ваду, обгорнуті в XCTExpectFailure:
//  зараз вони «очікувано падають» і не червонять збірку, а коли ваду
//  виправлять — тест повідомить про це, і обгортку треба буде прибрати.
//

import XCTest
import SwiftData
@testable import BeautyCRM

enum AuditFixtures {

    static let userID = "audit-user"

    static func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: UserProfile.self, Client.self, Appointment.self, Service.self, DayOff.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    // Конкретна дата в поточному часовому поясі: 2026-11-02 — понеділок
    static func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int,
        _ minute: Int = 0
    ) -> Date {
        Calendar.current.date(
            from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        )!
    }

    // Час у «базовий» понеділок 2026-11-02
    static func date(hour: Int, _ minute: Int = 0) -> Date {
        date(2026, 11, 2, hour, minute)
    }

    static func appointment(
        start: Date,
        minutes: Int,
        status: AppointmentStatus = .active,
        client: String = "Demo Client"
    ) -> Appointment {
        let appointment = Appointment(
            userID: userID,
            clientID: UUID(),
            clientName: client,
            startDate: start,
            duration: minutes
        )
        appointment.status = status
        return appointment
    }
}
