//
//  ClientNextAppointmentTests.swift
//  BeautyCRMTests
//
//  Рядок «Наступний запис» у картці клієнта.
//

import XCTest
@testable import BeautyCRM

@MainActor
final class ClientNextAppointmentTests: XCTestCase {

    private typealias F = AuditFixtures

    func testNextAppointmentIsNearestActiveOneInFuture() {
        let client = Client(userID: F.userID, name: "Demo Client")

        func appointment(_ day: Int, _ status: AppointmentStatus) -> Appointment {
            let appointment = Appointment(
                userID: F.userID, clientID: client.id, clientName: client.name,
                startDate: F.date(2026, 11, day, 10), duration: 60
            )
            appointment.status = status
            return appointment
        }

        let result = ClientAnalyticsCalculator.calculate(
            client: client,
            appointments: [
                appointment(5, .active),      // уже минув, лише чекає завершення
                appointment(20, .active),
                appointment(14, .cancelled),  // скасований не рахується
                appointment(16, .active)
            ],
            now: F.date(2026, 11, 10, 12)
        )

        XCTAssertEqual(result.nextAppointmentDate, F.date(2026, 11, 16, 10))
    }

    func testNoNextAppointmentWhenNothingPlanned() {
        let client = Client(userID: F.userID, name: "Demo Client")

        let result = ClientAnalyticsCalculator.calculate(client: client, appointments: [])

        XCTAssertNil(result.nextAppointmentDate)
    }

    func testClientSinceTakesEarlierFirstVisit() {
        let client = Client(userID: F.userID, name: "Demo Client")
        client.createdAt = F.date(2026, 11, 1, 9)

        let old = Appointment(
            userID: F.userID, clientID: client.id, clientName: client.name,
            startDate: F.date(2026, 3, 2, 10), duration: 60
        )
        old.status = .completed

        XCTAssertEqual(ClientAnalyticsCalculator.clientSince(client: client, appointments: [old]), F.date(2026, 3, 2, 10))
        XCTAssertEqual(ClientAnalyticsCalculator.clientSince(client: client, appointments: []), F.date(2026, 11, 1, 9))
    }
}
