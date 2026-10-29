//
//  AuditAppointmentRulesTests.swift
//  BeautyCRMTests
//
//  Аудит: накладки часу, найближчий вільний слот, статуси, вихідні.
//

import XCTest
import SwiftData
@testable import BeautyCRM

@MainActor
final class AuditAppointmentRulesTests: XCTestCase {

    private typealias F = AuditFixtures


    // MARK: - Накладки

    func testBackToBackAppointmentsDoNotConflict() {
        let existing = [F.appointment(start: F.date(hour: 10), minutes: 60)]

        XCTAssertFalse(
            AppointmentEngine.hasConflict(newStart: F.date(hour: 11), newEnd: F.date(hour: 12), existing: existing),
            "Кінець одного запису = початок іншого — це не накладка"
        )
        XCTAssertFalse(
            AppointmentEngine.hasConflict(newStart: F.date(hour: 9), newEnd: F.date(hour: 10), existing: existing)
        )
    }

    func testOneMinuteOverlapConflicts() {
        let existing = [F.appointment(start: F.date(hour: 10), minutes: 60)]

        XCTAssertTrue(
            AppointmentEngine.hasConflict(newStart: F.date(hour: 10, 59), newEnd: F.date(hour: 12), existing: existing)
        )
        XCTAssertTrue(
            AppointmentEngine.hasConflict(newStart: F.date(hour: 9), newEnd: F.date(hour: 10, 1), existing: existing)
        )
    }

    func testAppointmentOverMidnightConflictsWithNextDay() {
        // 23:00 + 2 год → до 01:00 наступного дня
        let existing = [F.appointment(start: F.date(hour: 23), minutes: 120)]

        XCTAssertTrue(
            AppointmentEngine.hasConflict(
                newStart: F.date(2026, 11, 3, 0, 30),
                newEnd: F.date(2026, 11, 3, 1, 30),
                existing: existing
            )
        )
    }

    func testCancelledCompletedArchivedDoNotBlock() {
        for status in [AppointmentStatus.cancelled, .completed, .archived] {
            let existing = [F.appointment(start: F.date(hour: 10), minutes: 60, status: status)]
            XCTAssertFalse(
                AppointmentEngine.hasConflict(newStart: F.date(hour: 10), newEnd: F.date(hour: 11), existing: existing),
                "\(status)"
            )
        }
    }

    func testEditingIgnoresItself() {
        let appointment = F.appointment(start: F.date(hour: 10), minutes: 60)

        XCTAssertFalse(
            AppointmentEngine.hasConflict(
                newStart: F.date(hour: 10, 30),
                newEnd: F.date(hour: 11, 30),
                existing: [appointment],
                ignoring: appointment.id
            )
        )
    }


    // MARK: - Найближчий вільний слот

    func testSuggestsSlotRightAfterConflictingAppointment() {
        let existing = [F.appointment(start: F.date(hour: 10), minutes: 60)]

        let result = AppointmentEngine.conflictResult(newStart: F.date(hour: 10, 30), duration: 60, existing: existing)

        XCTAssertTrue(result.hasConflict)
        XCTAssertEqual(result.suggestedStart, F.date(hour: 11))
        XCTAssertEqual(result.suggestedEnd, F.date(hour: 12))
    }

    func testSkipsTooSmallGap() {
        let existing = [
            F.appointment(start: F.date(hour: 10), minutes: 60),
            F.appointment(start: F.date(hour: 11, 30), minutes: 60)
        ]

        // Між 11:00 і 11:30 лише 30 хв — годинний запис туди не влазить
        let result = AppointmentEngine.conflictResult(newStart: F.date(hour: 10, 30), duration: 60, existing: existing)

        XCTAssertEqual(result.suggestedStart, F.date(hour: 12, 30))
    }

    func testSuggestionUsesFreeTimeBeforeFirstAppointment() {
        // Майстер хоче 10:30–11:30, а 11:00–12:00 зайнято. Вільно і 10:00–11:00 (раніше),
        // і 12:00 (пізніше). Рушій шукає тільки ПІСЛЯ записів, тож «раніше» не пропонує ніколи.
        let existing = [F.appointment(start: F.date(hour: 11), minutes: 60)]

        let result = AppointmentEngine.conflictResult(newStart: F.date(hour: 10, 30), duration: 60, existing: existing)

        XCTAssertEqual(result.suggestedStart, F.date(hour: 12))
    }

    func testSuggestionStaysWithinWorkingHours() {
        // Робочий день за замовчуванням 9:00–19:00; останній запис 18:00–19:00
        let existing = [F.appointment(start: F.date(hour: 18), minutes: 60)]

        let result = AppointmentEngine.conflictResult(newStart: F.date(hour: 18, 30), duration: 60, existing: existing)

        XCTExpectFailure("AUDIT: найближчий слот не враховує робочі години й вихідні — пропонує 19:00, після кінця дня")
        if let start = result.suggestedStart {
            XCTAssertLessThan(Calendar.current.component(.hour, from: start), 19)
        } else {
            XCTFail("Слот не запропоновано")
        }
    }


    // MARK: - Створення й редагування

    func testCreateOnDayOffIsRejected() throws {
        let context = try F.makeContext()
        let dayOff = DayOff(userID: F.userID, date: F.date(hour: 0))
        context.insert(dayOff)

        let client = Client(userID: F.userID, name: "Demo Client")
        let service = Service(userID: F.userID, name: "Cut", pricingType: .fixed, price: 30)

        let result = AppointmentEngine.createAppointment(
            context: context,
            userID: F.userID,
            client: client,
            services: [service],
            selectedServiceIDs: [service.id],
            customPrices: [:],
            startDate: F.date(hour: 12),
            duration: 60,
            notes: "",
            existingAppointments: []
        )

        XCTExpectFailure("AUDIT: запис на вихідний день створюється без попередження")
        if case .success = result {
            XCTFail("Запис на вихідний створено")
        }
    }

    func testUpdateKeepsServiceDeletedFromPriceList() throws {
        // Запис з двома послугами; одну потім видалили з прайсу.
        // Форма редагування бере послуги лише з НЕвидалених, тож видалена зникає з запису.
        let cut = Service(userID: F.userID, name: "Cut", pricingType: .fixed, price: 30)
        let color = Service(userID: F.userID, name: "Color", pricingType: .fixed, price: 70)
        let client = Client(userID: F.userID, name: "Demo Client")
        let appointment = F.appointment(start: F.date(hour: 10), minutes: 90)
        appointment.services = [
            AppointmentServiceItem(serviceID: cut.id, serviceName: "Cut", plannedPrice: 30),
            AppointmentServiceItem(serviceID: color.id, serviceName: "Color", plannedPrice: 70)
        ]
        color.markDeleted()

        // Так, як це робить AppointmentFormView: лише невидалені послуги
        let visibleServices = [cut, color].filter { $0.deletedAt == nil }
        let selectedIDs = Set(appointment.services.compactMap { item in
            visibleServices.first { $0.id == item.serviceID }?.id
        })

        _ = AppointmentEngine.updateAppointment(
            appointment: appointment,
            client: client,
            services: visibleServices,
            selectedServiceIDs: selectedIDs,
            customPrices: [:],
            startDate: appointment.startDate,
            duration: appointment.duration,
            notes: "",
            existingAppointments: []
        )

        XCTExpectFailure("AUDIT: редагування запису мовчки прибирає послугу, яку видалили з прайсу")
        XCTAssertEqual(appointment.services.count, 2)
    }

    func testUpdateRepricesFromCurrentPriceList() {
        // Ціну стрижки підняли з 30 до 35 вже після запису. Редагування часу запису
        // перераховує ціну за новим прайсом.
        let cut = Service(userID: F.userID, name: "Cut", pricingType: .fixed, price: 30)
        let client = Client(userID: F.userID, name: "Demo Client")
        let appointment = F.appointment(start: F.date(hour: 10), minutes: 60)
        appointment.services = [AppointmentServiceItem(serviceID: cut.id, serviceName: "Cut", plannedPrice: 30)]

        cut.price = 35

        _ = AppointmentEngine.updateAppointment(
            appointment: appointment,
            client: client,
            services: [cut],
            selectedServiceIDs: [cut.id],
            customPrices: [cut.id: 30],
            startDate: F.date(hour: 11),
            duration: 60,
            notes: "",
            existingAppointments: []
        )

        // Фіксуємо поточну поведінку: ціна оновилася до нового прайсу
        XCTAssertEqual(appointment.totalPlannedPrice, 35)
    }


    // MARK: - Статуси

    func testCompleteSetsStatusDateAndTotal() {
        let appointment = F.appointment(start: F.date(hour: 10), minutes: 60)
        let id1 = UUID(), id2 = UUID()
        appointment.services = [
            AppointmentServiceItem(serviceID: id1, serviceName: "A", plannedPrice: Decimal(string: "10.10")!),
            AppointmentServiceItem(serviceID: id2, serviceName: "B", plannedPrice: Decimal(string: "20.20")!)
        ]

        AppointmentEngine.complete(appointment: appointment, finalServicePrices: [id1: Decimal(string: "12.35")!])

        XCTAssertEqual(appointment.status, .completed)
        XCTAssertNotNil(appointment.completedAt)
        XCTAssertEqual(appointment.finalPrice, Decimal(string: "32.55"))
        XCTAssertEqual(appointment.totalFinalPrice, appointment.finalPrice)
    }

    func testCannotCompleteCancelledAppointment() {
        let appointment = F.appointment(start: F.date(hour: 10), minutes: 60, status: .cancelled)

        AppointmentEngine.complete(appointment: appointment, finalServicePrices: [:])

        XCTExpectFailure("AUDIT: рушій не перевіряє статус — скасований запис можна «завершити» (захист лише в UI)")
        XCTAssertEqual(appointment.status, .cancelled)
    }

    func testCannotCancelCompletedAppointment() {
        let appointment = F.appointment(start: F.date(hour: 10), minutes: 60, status: .completed)

        AppointmentEngine.cancel(appointment: appointment)

        XCTExpectFailure("AUDIT: рушій дозволяє скасувати вже завершений запис (захист лише в UI)")
        XCTAssertEqual(appointment.status, .completed)
    }

    func testEditingCompletedAppointmentKeepsTotalsConsistent() {
        let cut = Service(userID: F.userID, name: "Cut", pricingType: .fixed, price: 30)
        let client = Client(userID: F.userID, name: "Demo Client")
        let appointment = F.appointment(start: F.date(hour: 10), minutes: 60)
        appointment.services = [AppointmentServiceItem(serviceID: cut.id, serviceName: "Cut", plannedPrice: 30)]
        AppointmentEngine.complete(appointment: appointment, finalServicePrices: [cut.id: 45])

        let result = AppointmentEngine.updateAppointment(
            appointment: appointment,
            client: client,
            services: [cut],
            selectedServiceIDs: [cut.id],
            customPrices: [:],
            startDate: appointment.startDate,
            duration: 60,
            notes: "",
            existingAppointments: []
        )

        XCTExpectFailure("AUDIT: завершений запис можна змінити через рушій; фінальні ціни послуг губляться, а finalPrice лишається старим")
        if case .success = result {
            XCTAssertEqual(appointment.totalFinalPrice, appointment.finalPrice)
            XCTFail("Завершений запис змінено")
        }
    }
}
