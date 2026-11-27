//
//  ClientVisitHistoryTests.swift
//  BeautyCRMTests
//
//  Історія візитів клієнта і «Записати так само».
//

import XCTest
import SwiftData
@testable import BeautyCRM

@MainActor
final class ClientVisitHistoryTests: XCTestCase {

    private typealias F = AuditFixtures

    private var context: ModelContext!
    private let olena = UUID()

    override func setUpWithError() throws {
        context = try F.makeContext()
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: 10))!
    }

    @discardableResult
    private func visit(_ start: Date, client: UUID? = nil, status: AppointmentStatus = .completed,
                       items: [(UUID, String, Decimal, Decimal?)] = [], paid: Decimal? = nil) -> Appointment {
        let appointment = Appointment(userID: F.userID, clientID: client ?? olena, clientName: "Олена", startDate: start, duration: 90)
        for item in items {
            let service = AppointmentServiceItem(serviceID: item.0, serviceName: item.1, plannedPrice: item.2)
            service.finalPrice = item.3
            appointment.services.append(service)
        }
        appointment.status = status
        appointment.finalPrice = paid
        context.insert(appointment)
        return appointment
    }

    func testHistoryIsClientOnlyNewestFirstAndFiltered() throws {
        let old = visit(date(2025, 12, 20))
        let recent = visit(date(2026, 9, 12))
        let cancelled = visit(date(2026, 6, 2), status: .cancelled)
        let hidden = visit(date(2026, 5, 1), status: .archived)
        visit(date(2026, 8, 1), client: UUID())    // інший клієнт
        try context.save()
        let all = try context.fetch(FetchDescriptor<Appointment>())

        XCTAssertEqual(ClientVisitHistory.visits(clientID: olena, appointments: all, filter: .all).map(\.id),
                       [recent.id, cancelled.id, old.id], "Прихованого немає")
        XCTAssertEqual(ClientVisitHistory.visits(clientID: olena, appointments: all, filter: .completed).map(\.id),
                       [recent.id, old.id])
        XCTAssertEqual(ClientVisitHistory.visits(clientID: olena, appointments: all, filter: .cancelled).map(\.id),
                       [cancelled.id], "Приховані не показуються й серед скасованих")
        XCTAssertFalse(ClientVisitHistory.visits(clientID: olena, appointments: all, filter: .all).contains { $0.id == hidden.id })

        let groups = ClientVisitHistory.byYear(ClientVisitHistory.visits(clientID: olena, appointments: all, filter: .all))
        XCTAssertEqual(groups.map(\.year), [2026, 2025])
    }

    func testPaidOnlyForCompletedAndUsesFinalPrices() {
        let color = UUID()
        let done = visit(date(2026, 9, 12), items: [(color, "Фарбування", 95, 105)])
        let planned = visit(date(2026, 12, 1), status: .active, items: [(color, "Фарбування", 95, nil)])

        XCTAssertEqual(ClientVisitHistory.paid(done), 105)
        XCTAssertNil(ClientVisitHistory.paid(planned))
        XCTAssertEqual(ClientVisitHistory.price(of: done.services[0], in: done), 105)
        XCTAssertEqual(ClientVisitHistory.price(of: planned.services[0], in: planned), 95)
    }

    func testRepeatTakesSameServicesCurrentFixedAndLastVariablePrice() throws {
        let haircut = Service(userID: F.userID, name: "Стрижка", pricingType: .fixed, price: 40)
        let coloring = Service(userID: F.userID, name: "Фарбування", pricingType: .variable, price: nil)
        let removed = Service(userID: F.userID, name: "Стара послуга", pricingType: .fixed, price: 10)
        removed.markDeleted()
        [haircut, coloring, removed].forEach(context.insert)

        let last = visit(date(2026, 9, 12), items: [
            (haircut.id, "Стрижка", 35, 35),
            (coloring.id, "Фарбування", 95, 105),
            (removed.id, "Стара послуга", 10, 10)
        ])

        let plan = ClientVisitHistory.repeatPlan(of: last, services: [haircut, coloring, removed])

        XCTAssertEqual(plan.services.map(\.id), [haircut.id, coloring.id], "Видаленої з прайсу послуги немає")
        XCTAssertEqual(plan.customPrices[coloring.id], 105, "Змінна ціна — як заплатили минулого разу")
        XCTAssertNil(plan.customPrices[haircut.id], "Фіксована — з теперішнього прайсу")
    }
}
