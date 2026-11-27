//
//  FixCompletedAppointmentTests.swift
//  BeautyCRMTests
//
//  Виправлення завершених записів: змінити суму, повернення, «Повернути в заплановані»,
//  аналітика після повернення і пошук в «Усіх записах».
//

import XCTest
@testable import BeautyCRM

@MainActor
final class FixCompletedAppointmentTests: XCTestCase {

    private typealias F = AuditFixtures

    private let cut = UUID()
    private let color = UUID()

    private func completed(cutPrice: Decimal = 1000, colorPrice: Decimal = 60, start: Date = F.date(2026, 11, 4, 10)) -> Appointment {
        let appointment = F.appointment(start: start, minutes: 60)
        appointment.services = [
            AppointmentServiceItem(serviceID: cut, serviceName: "Cut", plannedPrice: 40),
            AppointmentServiceItem(serviceID: color, serviceName: "Colour", plannedPrice: 60)
        ]
        AppointmentEngine.complete(appointment: appointment, finalServicePrices: [cut: cutPrice, color: colorPrice])
        return appointment
    }

    // MARK: - CHANGE AMOUNT

    func testEditCompletedFixesTypo() throws {
        let appointment = completed()
        let completedAt = appointment.completedAt
        XCTAssertEqual(appointment.finalPrice, 1060)

        try AppointmentEngine.editCompleted(appointment: appointment, finalServicePrices: [cut: 100]).get()

        XCTAssertEqual(appointment.finalPrice, 160)
        XCTAssertEqual(appointment.services.first { $0.serviceID == cut }?.finalPrice, 100)
        XCTAssertEqual(appointment.services.first { $0.serviceID == color }?.finalPrice, 60, "Інша послуга не змінилась")
        XCTAssertEqual(appointment.status, .completed)
        XCTAssertEqual(appointment.completedAt, completedAt, "Запис лишається в тому самому періоді")
    }

    func testEditCompletedOnlyForCompleted() {
        let active = F.appointment(start: F.date(hour: 10), minutes: 60)
        guard case .failure(.invalidStatus) = AppointmentEngine.editCompleted(appointment: active, finalServicePrices: [:]) else {
            return XCTFail("Незавершений запис так не змінюють")
        }
    }

    func testLoweringAmountCapsRefund() throws {
        let appointment = completed(cutPrice: 40)
        try AppointmentEngine.refund(appointment: appointment, amount: 90, reason: nil).get()

        try AppointmentEngine.editCompleted(appointment: appointment, finalServicePrices: [cut: 10, color: 20]).get()

        XCTAssertEqual(appointment.refundAmount, 30, "Повернення не більше за нову суму")
        XCTAssertEqual(appointment.netPrice, 0)
    }

    // MARK: - REFUND

    func testRefundReducesNetPrice() throws {
        let appointment = completed(cutPrice: 40)
        let now = F.date(2026, 11, 5, 9)

        try AppointmentEngine.refund(appointment: appointment, amount: 30, reason: "  скарга на тон ", now: now).get()

        XCTAssertEqual(appointment.finalPrice, 100, "Оплата лишається як була")
        XCTAssertEqual(appointment.netPrice, 70)
        XCTAssertEqual(appointment.refundReason, "скарга на тон")
        XCTAssertEqual(appointment.refundedAt, now)
    }

    func testRefundCannotExceedPayment() {
        let appointment = completed(cutPrice: 40)
        guard case .failure(.refundTooLarge) = AppointmentEngine.refund(appointment: appointment, amount: 101, reason: nil) else {
            return XCTFail("Повернення більше за оплату")
        }
        XCTAssertNil(appointment.refundAmount)
    }

    func testZeroRemovesRefund() throws {
        let appointment = completed(cutPrice: 40)
        try AppointmentEngine.refund(appointment: appointment, amount: 30, reason: "x").get()
        try AppointmentEngine.refund(appointment: appointment, amount: 0, reason: nil).get()

        XCTAssertNil(appointment.refundAmount)
        XCTAssertNil(appointment.refundReason)
        XCTAssertNil(appointment.refundedAt)
        XCTAssertEqual(appointment.netPrice, 100)
    }

    // MARK: - REOPEN

    func testReopenMakesAppointmentPlannedAgain() throws {
        let appointment = completed(cutPrice: 40)
        try AppointmentEngine.refund(appointment: appointment, amount: 10, reason: nil).get()

        try AppointmentEngine.reopen(appointment: appointment, existingAppointments: [appointment]).get()

        XCTAssertEqual(appointment.status, .active)
        XCTAssertNil(appointment.finalPrice)
        XCTAssertNil(appointment.completedAt)
        XCTAssertNil(appointment.refundAmount)
        XCTAssertTrue(appointment.services.allSatisfy { $0.finalPrice == nil })
        XCTAssertEqual(appointment.totalPlannedPrice, 100, "Планові ціни на місці")
    }

    func testReopenFailsWhenTimeIsTaken() {
        let appointment = completed(start: F.date(hour: 10))
        let newOne = F.appointment(start: F.date(hour: 10, 30), minutes: 60)

        guard case .failure(.timeConflict) = AppointmentEngine.reopen(appointment: appointment, existingAppointments: [appointment, newOne]) else {
            return XCTFail("Час уже зайняли")
        }
        XCTAssertEqual(appointment.status, .completed)
        XCTAssertEqual(appointment.finalPrice, 1060)
    }

    func testRestoreDoesNotReopenCompleted() {
        let appointment = completed()
        guard case .failure(.invalidStatus) = AppointmentEngine.restore(appointment: appointment, existingAppointments: []) else {
            return XCTFail("«Відновити» — лише для скасованих")
        }
        XCTAssertEqual(appointment.status, .completed)
    }

    // MARK: - ANALYTICS

    func testAnalyticsCountsMoneyAfterRefund() throws {
        let refunded = completed(cutPrice: 40)                       // 100
        try AppointmentEngine.refund(appointment: refunded, amount: 50, reason: nil).get()
        let other = completed(cutPrice: 40, colorPrice: 0, start: F.date(2026, 11, 6, 10))   // 40

        let calendar = AnalyticsEngine.calendar()
        let interval = try XCTUnwrap(
            AnalyticsEngine.interval(for: .month, reference: F.date(2026, 11, 4, 12), month: 11, year: 2026, calendar: calendar)
        )
        let summary = AnalyticsEngine.summary(
            appointments: [refunded, other],
            userID: F.userID,
            clientNames: [:],
            serviceNames: [:],
            period: .month,
            interval: interval,
            calendar: calendar,
            now: F.date(2030, 1, 1, 12)
        )

        XCTAssertEqual(summary.revenue, 90)
        XCTAssertEqual(summary.averageCheck, 45)
        // Повернення ділиться між послугами пропорційно: у першому записі лишилась половина
        XCTAssertEqual(summary.topServices.first { $0.id == cut }?.revenue, 60)     // 20 + 40
        XCTAssertEqual(summary.topServices.first { $0.id == color }?.revenue, 30)   // 30 + 0
    }

    // MARK: - HISTORY

    func testHistoryFiltersSearchesAndGroupsByMonth() {
        let november = completed(start: F.date(2026, 11, 4, 10))
        let october = F.appointment(start: F.date(2026, 10, 20, 10), minutes: 60, client: "Olena")
        october.services = [AppointmentServiceItem(serviceID: UUID(), serviceName: "Keratin", plannedPrice: 80)]
        let cancelled = F.appointment(start: F.date(2026, 11, 8, 10), minutes: 60, status: .cancelled)
        let hidden = F.appointment(start: F.date(2026, 11, 9, 10), minutes: 60, status: .archived)
        let all = [november, october, cancelled, hidden]

        let months = AppointmentHistory.months(all, filter: .all, search: "")
        XCTAssertEqual(months.count, 2)
        XCTAssertEqual(months.first?.appointments.map(\.id), [cancelled.id, november.id], "Новіші зверху, прихованих немає")

        XCTAssertEqual(AppointmentHistory.months(all, filter: .completed, search: "").flatMap(\.appointments).map(\.id), [november.id])
        XCTAssertEqual(AppointmentHistory.months(all, filter: .cancelled, search: "").flatMap(\.appointments).map(\.id), [cancelled.id])
        XCTAssertEqual(AppointmentHistory.months(all, filter: .planned, search: "").flatMap(\.appointments).map(\.id), [october.id])

        XCTAssertEqual(AppointmentHistory.months(all, filter: .all, search: "kera").flatMap(\.appointments).map(\.id), [october.id], "Пошук за послугою")

        let counts = AppointmentHistory.counts(all, search: "")
        XCTAssertEqual(counts[.all], 3, "Приховані не рахуються")
        XCTAssertEqual(counts[.planned], 1)
        XCTAssertEqual(counts[.completed], 1)
        XCTAssertEqual(counts[.cancelled], 1)
        XCTAssertEqual(AppointmentHistory.counts(all, search: "olena")[.all], 1, "Лічильники враховують пошук")
        XCTAssertEqual(AppointmentHistory.months(all, filter: .all, search: " olena ").flatMap(\.appointments).map(\.id), [october.id], "Пошук за клієнтом")
    }
}
