//
//  AnalyticsEngineTests.swift
//  BeautyCRMTests
//
//  #36 — розрахунки аналітики поза екраном, #29 — топ клієнтів за clientID.
//

import XCTest
@testable import BeautyCRM

@MainActor
final class AnalyticsEngineTests: XCTestCase {

    private typealias F = AuditFixtures

    private let calendar = AnalyticsEngine.calendar()


    // MARK: - HELPERS

    private func done(
        _ start: Date,
        minutes: Int = 60,
        price: Decimal,
        client: UUID = UUID(),
        clientName: String = "Demo Client",
        services: [(UUID, String, Decimal)] = []
    ) -> Appointment {
        let appointment = Appointment(
            userID: F.userID, clientID: client, clientName: clientName,
            startDate: start, duration: minutes
        )
        appointment.services = services.map {
            AppointmentServiceItem(serviceID: $0.0, serviceName: $0.1, plannedPrice: $0.2)
        }
        AppointmentEngine.complete(appointment: appointment, finalServicePrices: [:])
        appointment.finalPrice = price
        return appointment
    }

    private func summary(
        _ appointments: [Appointment],
        period: AnalyticsPeriod,
        reference: Date = F.date(2026, 11, 4, 12),
        month: Int = 11,
        year: Int = 2026,
        clientNames: [UUID: String] = [:],
        serviceNames: [UUID: String] = [:]
    ) throws -> AnalyticsSummary {
        let interval = try XCTUnwrap(
            AnalyticsEngine.interval(for: period, reference: reference, month: month, year: year, calendar: calendar)
        )
        return AnalyticsEngine.summary(
            appointments: appointments,
            userID: F.userID,
            clientNames: clientNames,
            serviceNames: serviceNames,
            period: period,
            interval: interval,
            calendar: calendar
        )
    }


    // MARK: - PERIODS

    func testWeekRunsMondayToSunday() throws {
        // 04.11.2026 — середа; тиждень 02.11 (пн) — 08.11 (нд)
        let result = try summary([
            done(F.date(2026, 11, 1, 23, 59), price: 1),   // неділя попереднього тижня
            done(F.date(2026, 11, 2, 0, 0), price: 10),    // понеділок 00:00
            done(F.date(2026, 11, 8, 23, 59), price: 20),  // неділя 23:59
            done(F.date(2026, 11, 9, 0, 0), price: 100)    // наступний понеділок
        ], period: .week)

        XCTAssertEqual(result.revenue, 30)
        XCTAssertEqual(result.chart.count, 7)
        XCTAssertEqual(result.chart.first?.date, F.date(2026, 11, 2, 0, 0))
    }

    func testWeekAcrossNewYear() throws {
        // 31.12.2026 (чт) і 01.01.2027 (пт) — один тиждень
        let result = try summary([
            done(F.date(2026, 12, 31, 10), price: 30),
            done(F.date(2027, 1, 1, 10), price: 40)
        ], period: .week, reference: F.date(2027, 1, 1, 12))

        XCTAssertEqual(result.revenue, 70)
    }

    func testMonthBoundaries() throws {
        let result = try summary([
            done(F.date(2026, 10, 31, 23, 59), price: 1),
            done(F.date(2026, 11, 1, 0, 0), price: 10),
            done(F.date(2026, 11, 30, 23, 59), price: 20),
            done(F.date(2026, 12, 1, 0, 0), price: 100)
        ], period: .month, month: 11, year: 2026)

        XCTAssertEqual(result.revenue, 30)
        XCTAssertEqual(result.chart.count, 30, "Листопад — 30 стовпчиків")
    }

    func testYearHasTwelveMonthBars() throws {
        let result = try summary([
            done(F.date(2026, 1, 15, 10), price: 10),
            done(F.date(2026, 1, 20, 10), price: 5),
            done(F.date(2026, 12, 31, 23, 59), price: 20),
            done(F.date(2027, 1, 1, 0, 0), price: 100)
        ], period: .year, year: 2026)

        XCTAssertEqual(result.revenue, 35)
        XCTAssertEqual(result.chart.count, 12)
        XCTAssertEqual(result.chart[0].revenue, 15)
        XCTAssertEqual(result.chart[0].count, 2)
        XCTAssertEqual(result.chart[11].revenue, 20)
    }


    // MARK: - NUMBERS

    func testEmptyPeriodHasNoDivisionByZero() throws {
        let result = try summary([], period: .month)

        XCTAssertEqual(result.revenue, 0)
        XCTAssertEqual(result.averageCheck, 0)
        XCTAssertEqual(result.hourlyIncome, 0)
        XCTAssertTrue(result.topClients.isEmpty)
        XCTAssertEqual(result.chart.count, 30, "Порожні стовпчики все одно є")
        XCTAssertTrue(result.chart.allSatisfy { $0.revenue == 0 })
    }

    func testOnlyCompletedOwnAppointmentsCount() throws {
        let active = Appointment(userID: F.userID, clientID: UUID(), clientName: "A", startDate: F.date(2026, 11, 3, 10), duration: 60)
        let cancelled = done(F.date(2026, 11, 3, 12), price: 50)
        cancelled.status = .cancelled
        let foreign = done(F.date(2026, 11, 3, 14), price: 70)
        foreign.userID = "someone-else"

        let result = try summary([active, cancelled, foreign, done(F.date(2026, 11, 3, 16), price: 25)], period: .month)

        XCTAssertEqual(result.revenue, 25)
        XCTAssertEqual(result.appointmentCount, 1)
    }

    func testAverageCheckAndHourlyIncome() throws {
        let result = try summary([
            done(F.date(2026, 11, 3, 10), minutes: 90, price: Decimal(string: "45.50")!),
            done(F.date(2026, 11, 4, 10), minutes: 30, price: 30)
        ], period: .month)

        XCTAssertEqual(result.revenue, Decimal(string: "75.5"))
        XCTAssertEqual(result.averageCheck, Decimal(string: "37.75"))
        // 75,50 за 2 години
        XCTAssertEqual(result.hourlyIncome, Decimal(string: "37.75"))
    }

    func testClientCountIsUnique() throws {
        let anna = UUID()
        let result = try summary([
            done(F.date(2026, 11, 3, 10), price: 10, client: anna),
            done(F.date(2026, 11, 5, 10), price: 10, client: anna),
            done(F.date(2026, 11, 6, 10), price: 10)
        ], period: .month)

        XCTAssertEqual(result.clientCount, 2)
    }


    // MARK: - TOP CLIENTS (#29)

    func testNamesakesStaySeparate() throws {
        let anna1 = UUID(), anna2 = UUID()
        let result = try summary([
            done(F.date(2026, 11, 3, 10), price: 40, client: anna1, clientName: "Anna"),
            done(F.date(2026, 11, 4, 10), price: 60, client: anna2, clientName: "Anna")
        ], period: .month)

        XCTAssertEqual(result.topClients.count, 2, "Дві різні Анни — два рядки")
    }

    func testRenamedClientIsOneRowWithCurrentName() throws {
        let olena = UUID()
        let result = try summary([
            done(F.date(2026, 11, 3, 10), price: 40, client: olena, clientName: "Olena"),
            done(F.date(2026, 11, 4, 10), price: 60, client: olena, clientName: "Olena K.")
        ], period: .month, clientNames: [olena: "Olena Koval"])

        XCTAssertEqual(result.topClients.count, 1)
        XCTAssertEqual(result.topClients.first?.name, "Olena Koval")
        XCTAssertEqual(result.topClients.first?.visits, 2)
        XCTAssertEqual(result.topClients.first?.spent, 100)
    }

    func testDeletedClientUsesLatestNameFromAppointments() throws {
        let gone = UUID()
        let result = try summary([
            done(F.date(2026, 11, 3, 10), price: 40, client: gone, clientName: "Old name"),
            done(F.date(2026, 11, 4, 10), price: 60, client: gone, clientName: "New name")
        ], period: .month)

        XCTAssertEqual(result.topClients.first?.name, "New name")
    }

    func testTopClientsSortedByVisitsThenSpent() throws {
        let a = UUID(), b = UUID(), c = UUID()
        let result = try summary([
            done(F.date(2026, 11, 3, 10), price: 10, client: a, clientName: "A"),
            done(F.date(2026, 11, 4, 10), price: 10, client: a, clientName: "A"),
            done(F.date(2026, 11, 5, 10), price: 500, client: b, clientName: "B"),
            done(F.date(2026, 11, 6, 10), price: 100, client: c, clientName: "C")
        ], period: .month)

        XCTAssertEqual(result.topClients.map(\.name), ["A", "B", "C"])
    }


    // MARK: - TOP SERVICES

    func testRenamedServiceIsOneRow() throws {
        let cut = UUID()
        let result = try summary([
            done(F.date(2026, 11, 3, 10), price: 30, services: [(cut, "Cut", 30)]),
            done(F.date(2026, 11, 4, 10), price: 35, services: [(cut, "Haircut", 35)])
        ], period: .month, serviceNames: [cut: "Haircut"])

        XCTAssertEqual(result.topServices.count, 1)
        XCTAssertEqual(result.topServices.first?.name, "Haircut")
        XCTAssertEqual(result.topServices.first?.count, 2)
        XCTAssertEqual(result.topServices.first?.revenue, 65)
    }
}
