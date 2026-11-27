//
//  AnalyticsInsightsTests.swift
//  BeautyCRMTests
//
//  Кругова діаграма послуг («Інші» для дрібних) і клієнтська база без прив'язки до періоду.
//

import XCTest
@testable import BeautyCRM

@MainActor
final class AnalyticsInsightsTests: XCTestCase {

    private typealias F = AuditFixtures

    private func service(_ name: String, _ revenue: Decimal, count: Int = 1) -> AnalyticsServiceItem {
        AnalyticsServiceItem(id: UUID(), name: name, revenue: revenue, count: count)
    }

    // MARK: - SLICES

    func testSmallServicesGoToOther() {
        let slices = AnalyticsInsights.serviceSlices([
            service("Стрижка", 50), service("AirTouch", 357), service("Кератин", 234),
            service("Укладка", 200), service("Брови", 60), service("Догляд", 99)
        ])
        // Разом 1000: AirTouch 35,7 %, Кератин 23,4 %, Укладка 20 %, Догляд 9,9 %, Брови 6 %, Стрижка 5 %

        XCTAssertEqual(slices.map(\.name), ["AirTouch", "Кератин", "Укладка", ""])
        XCTAssertEqual(slices.first?.share ?? 0, 0.357, accuracy: 0.0001)
        let other = slices.last
        XCTAssertEqual(other?.isOther, true)
        XCTAssertEqual(other?.revenue, 209)
        XCTAssertEqual(other?.count, 3)
        XCTAssertEqual(slices.reduce(0) { $0 + $1.share }, 1, accuracy: 0.0001)
    }

    func testSingleSmallServiceKeepsItsName() {
        let slices = AnalyticsInsights.serviceSlices([
            service("A", 50), service("B", 30), service("C", 15), service("D", 5)
        ])
        XCTAssertEqual(slices.map(\.name), ["A", "B", "C", "D"], "Одну дрібну не ховаємо під «Інші»")
        XCTAssertFalse(slices.contains { $0.isOther })
    }

    func testTopThreeAlwaysNamedAndEmptyRevenueSkipped() {
        // Багато дрібних послуг по 8 %: три найбільші все одно з назвою
        var items = (0..<12).map { service("S\($0)", Decimal(10 + $0)) }
        items.append(service("Безкоштовна", 0))
        let slices = AnalyticsInsights.serviceSlices(items)

        XCTAssertEqual(slices.prefix(3).map(\.name), ["S11", "S10", "S9"])
        XCTAssertEqual(slices.last?.isOther, true)
        XCTAssertFalse(slices.contains { $0.name == "Безкоштовна" })
        XCTAssertTrue(AnalyticsInsights.serviceSlices([service("0", 0)]).isEmpty)
    }

    // MARK: - CLIENT BASE

    private func client(_ name: String, createdAt: Date) -> Client {
        let client = Client(userID: F.userID, name: name)
        client.createdAt = createdAt
        return client
    }

    private func visit(_ client: Client, _ date: Date, status: AppointmentStatus = .completed) -> Appointment {
        let appointment = Appointment(userID: F.userID, clientID: client.id, clientName: client.name, startDate: date, duration: 60)
        appointment.status = status
        appointment.finalPrice = status == .completed ? 50 : nil
        return appointment
    }

    func testClientBaseIgnoresPeriodAndCountsReturningNewAndDormant() {
        let now = F.date(2027, 1, 15, 12)   // уже новий рік — база не обнуляється
        let olena = client("Олена", createdAt: F.date(2026, 3, 1, 10))
        let iryna = client("Ірина", createdAt: F.date(2026, 5, 1, 10))
        let maria = client("Марія", createdAt: F.date(2026, 6, 1, 10))
        let newOne = client("Нова", createdAt: F.date(2027, 1, 3, 10))
        let oldNote = client("Стара картка", createdAt: F.date(2027, 1, 10, 10))   // внесли зараз, але ходить давно

        let appointments = [
            visit(olena, F.date(2026, 4, 1, 10)), visit(olena, F.date(2026, 12, 20, 10)), visit(olena, F.date(2027, 1, 5, 10)),
            visit(iryna, F.date(2026, 5, 2, 10)), visit(iryna, F.date(2026, 8, 2, 10)),     // давно не була
            visit(maria, F.date(2026, 6, 2, 10)),                                            // одна, давно, але записана наперед
            visit(maria, F.date(2027, 2, 1, 10), status: .active),
            visit(newOne, F.date(2027, 1, 4, 10)),
            visit(oldNote, F.date(2026, 9, 1, 10)),
            visit(olena, F.date(2026, 7, 1, 10), status: .cancelled)
        ]

        let base = AnalyticsInsights.clientBase(clients: [olena, iryna, maria, newOne, oldNote], appointments: appointments, now: now)

        XCTAssertEqual(base.total, 5)
        XCTAssertEqual(base.newThisMonth, 1, "Нова — так; «Стара картка» прийшла ще у вересні")
        XCTAssertEqual(base.visited, 5)
        XCTAssertEqual(base.returning, 2)
        XCTAssertEqual(base.returningPercent, 40)
        XCTAssertEqual(base.dormant, 2, "Ірина й «Стара картка»; Марія записана наперед")
        XCTAssertEqual(base.loyal.map(\.name), ["Олена", "Ірина"], "Найпостійніші — від двох візитів")
    }

    func testEmptyBase() {
        let base = AnalyticsInsights.clientBase(clients: [], appointments: [])
        XCTAssertEqual(base.total, 0)
        XCTAssertEqual(base.returningPercent, 0)
    }
}
