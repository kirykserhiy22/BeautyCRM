//
//  DataConsistencyTests.swift
//  BeautyCRMTests
//
//  Узгодженість даних між функціями: перейменування й видалення клієнта
//  доходять до його записів; мова за замовчуванням — мова iPhone.
//

import XCTest
import SwiftData
@testable import BeautyCRM

@MainActor
final class DataConsistencyTests: XCTestCase {

    private typealias F = AuditFixtures

    private var context: ModelContext!
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    override func setUpWithError() throws {
        context = try F.makeContext()
    }

    private func client(_ name: String) throws -> Client {
        let client = Client(userID: F.userID, name: name)
        context.insert(client)
        try context.save()
        return client
    }

    @discardableResult
    private func appointment(for client: Client, hoursFromNow: Double, minutes: Int = 60) throws -> Appointment {
        let appointment = Appointment(
            userID: F.userID,
            clientID: client.id,
            clientName: client.name,
            startDate: now.addingTimeInterval(hoursFromNow * 3600),
            duration: minutes
        )
        context.insert(appointment)
        try context.save()
        return appointment
    }

    func testRenameReachesPastAndFutureAppointments() throws {
        let olena = try client("Олена")
        let past = try appointment(for: olena, hoursFromNow: -48)
        let future = try appointment(for: olena, hoursFromNow: 48)
        let other = try appointment(for: try client("Марія"), hoursFromNow: 24)

        olena.name = "Олена Коваль"
        try ClientManager.syncName(of: olena, context: context)

        XCTAssertEqual(past.clientName, "Олена Коваль")
        XCTAssertEqual(future.clientName, "Олена Коваль")
        XCTAssertEqual(other.clientName, "Марія", "Чужі записи не чіпаємо")
    }

    func testDeleteCancelsOnlyUpcomingAppointments() throws {
        let olena = try client("Олена")
        let past = try appointment(for: olena, hoursFromNow: -48)                // минулий незавершений
        let ongoing = try appointment(for: olena, hoursFromNow: -0.5)            // триває зараз
        let future = try appointment(for: olena, hoursFromNow: 24)
        let done = try appointment(for: olena, hoursFromNow: 2)
        done.status = .completed

        XCTAssertEqual(
            try ClientManager.upcomingAppointments(clientIDs: [olena.id], now: now, context: context).count,
            2,
            "Майбутній і той, що триває; завершений — ні"
        )

        ClientManager.delete(client: olena, now: now, context: context)

        XCTAssertNotNil(olena.deletedAt)
        XCTAssertEqual(future.status, .cancelled)
        XCTAssertEqual(ongoing.status, .cancelled)
        XCTAssertEqual(past.status, .active, "Минулий лишається — майстер може його завершити")
        XCTAssertEqual(done.status, .completed)
    }

    func testDefaultLanguageFollowsIPhone() {
        XCTAssertEqual(LocalizationManager.deviceLanguage(preferred: ["uk-UA", "en-US"]), "uk")
        XCTAssertEqual(LocalizationManager.deviceLanguage(preferred: ["fr-FR", "de-AT"]), "de", "Перша підтримувана з переліку")
        XCTAssertEqual(LocalizationManager.deviceLanguage(preferred: ["fr-FR"]), "en")
        XCTAssertEqual(LocalizationManager.deviceLanguage(preferred: ["cs"]), "cs")
    }
}
