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
        // Форма тримає таку послугу в retainedItems, і вона лишається в записі.
        let cut = Service(userID: F.userID, name: "Cut", pricingType: .fixed, price: 30)
        let color = Service(userID: F.userID, name: "Color", pricingType: .fixed, price: 70)
        let client = Client(userID: F.userID, name: "Demo Client")
        let appointment = F.appointment(start: F.date(hour: 10), minutes: 90)
        appointment.services = [
            AppointmentServiceItem(serviceID: cut.id, serviceName: "Cut", plannedPrice: 30),
            AppointmentServiceItem(serviceID: color.id, serviceName: "Color", plannedPrice: 70)
        ]
        color.markDeleted()

        let visibleServices = [cut, color].filter { $0.deletedAt == nil }
        let state = formState(for: appointment, visibleServices: visibleServices)

        let result = update(appointment, client: client, services: visibleServices, state: state)

        XCTAssertNoThrow(try result.get())
        XCTAssertEqual(appointment.services.map(\.serviceName).sorted(), ["Color", "Cut"])
        XCTAssertEqual(appointment.totalPlannedPrice, 100)
    }

    func testUpdateKeepsAgreedPrice() {
        // Ціну стрижки підняли з 30 до 35 вже після запису.
        // Перенесення запису на іншу годину не змінює погоджену ціну.
        let cut = Service(userID: F.userID, name: "Cut", pricingType: .fixed, price: 30)
        let client = Client(userID: F.userID, name: "Demo Client")
        let appointment = F.appointment(start: F.date(hour: 10), minutes: 60)
        appointment.services = [AppointmentServiceItem(serviceID: cut.id, serviceName: "Cut", plannedPrice: 30)]

        cut.price = 35

        var state = formState(for: appointment, visibleServices: [cut])
        state.startDate = F.date(hour: 11)

        _ = update(appointment, client: client, services: [cut], state: state)

        XCTAssertEqual(appointment.startDate, F.date(hour: 11))
        XCTAssertEqual(appointment.totalPlannedPrice, 30)
        XCTAssertEqual(state.computedPlannedTotal, 30, "Форма показує погоджену ціну, а не новий прайс")
    }

    func testUpdateAddsNewServiceAtCurrentPrice() {
        let cut = Service(userID: F.userID, name: "Cut", pricingType: .fixed, price: 35)
        let styling = Service(userID: F.userID, name: "Styling", pricingType: .fixed, price: 25)
        let client = Client(userID: F.userID, name: "Demo Client")
        let appointment = F.appointment(start: F.date(hour: 10), minutes: 60)
        appointment.services = [AppointmentServiceItem(serviceID: cut.id, serviceName: "Cut", plannedPrice: 30)]

        var state = formState(for: appointment, visibleServices: [cut, styling])
        state.selectedServices.append(styling)

        _ = update(appointment, client: client, services: [cut, styling], state: state)

        XCTAssertEqual(appointment.services.first { $0.serviceID == cut.id }?.plannedPrice, 30)
        XCTAssertEqual(appointment.services.first { $0.serviceID == styling.id }?.plannedPrice, 25)
        XCTAssertEqual(appointment.totalPlannedPrice, 55)
        XCTAssertEqual(state.computedPlannedTotal, 55)
    }

    func testUpdateRemovesDeselectedServices() {
        let cut = Service(userID: F.userID, name: "Cut", pricingType: .fixed, price: 30)
        let color = Service(userID: F.userID, name: "Color", pricingType: .fixed, price: 70)
        let client = Client(userID: F.userID, name: "Demo Client")
        let appointment = F.appointment(start: F.date(hour: 10), minutes: 90)
        appointment.services = [
            AppointmentServiceItem(serviceID: cut.id, serviceName: "Cut", plannedPrice: 30),
            AppointmentServiceItem(serviceID: color.id, serviceName: "Color", plannedPrice: 70)
        ]
        color.markDeleted()

        // Майстер прибрав і видалену з прайсу послугу (хрестиком), і звичайну — лишилось порожньо
        var state = formState(for: appointment, visibleServices: [cut])
        state.retainedItems = []
        XCTAssertEqual(state.selectedServiceIDs, [cut.id])

        _ = update(appointment, client: client, services: [cut], state: state)
        XCTAssertEqual(appointment.services.map(\.serviceName), ["Cut"])

        state.selectedServices = []
        let result = update(appointment, client: client, services: [cut], state: state)

        if case .failure(let error) = result {
            XCTAssertEqual(error, .noServices)
        } else {
            XCTFail("Запис без послуг не можна зберегти")
        }
        XCTAssertEqual(appointment.services.count, 1, "Невдале збереження нічого не змінює")
    }

    func testUpdateAppliesChangedVariablePrice() {
        let color = Service(userID: F.userID, name: "Color", pricingType: .variable)
        let client = Client(userID: F.userID, name: "Demo Client")
        let appointment = F.appointment(start: F.date(hour: 10), minutes: 120)
        appointment.services = [AppointmentServiceItem(serviceID: color.id, serviceName: "Color", plannedPrice: 80)]

        var state = formState(for: appointment, visibleServices: [color])
        XCTAssertEqual(state.computedPlannedTotal, 80)

        state.customPrices[color.id] = Decimal(string: "95.50")!
        _ = update(appointment, client: client, services: [color], state: state)

        XCTAssertEqual(appointment.totalPlannedPrice, Decimal(string: "95.50"))
    }


    // Стан форми так, як його заповнює AppointmentFormView.loadAppointmentIfNeeded
    private func formState(for appointment: Appointment, visibleServices: [Service]) -> AppointmentCreateState {
        var state = AppointmentCreateState(
            client: nil,
            selectedServices: appointment.services.compactMap { item in
                visibleServices.first { $0.id == item.serviceID }
            },
            customPrices: [:],
            startDate: appointment.startDate,
            duration: appointment.duration,
            notes: ""
        )
        state.retainedItems = appointment.services.filter { item in
            !visibleServices.contains { $0.id == item.serviceID }
        }
        let prices = Dictionary(
            appointment.services.map { ($0.serviceID, $0.plannedPrice) },
            uniquingKeysWith: { first, _ in first }
        )
        state.agreedPrices = prices
        state.customPrices = prices
        return state
    }

    private func update(
        _ appointment: Appointment,
        client: Client,
        services: [Service],
        state: AppointmentCreateState
    ) -> Result<Void, AppointmentError> {
        AppointmentEngine.updateAppointment(
            appointment: appointment,
            client: client,
            services: services,
            selectedServiceIDs: state.selectedServiceIDs,
            customPrices: state.customPrices,
            startDate: state.startDate,
            duration: state.duration,
            notes: "",
            existingAppointments: []
        )
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

        let result = AppointmentEngine.complete(appointment: appointment, finalServicePrices: [:])

        XCTAssertEqual(failure(of: result), .invalidStatus)
        XCTAssertEqual(appointment.status, .cancelled)
        XCTAssertNil(appointment.finalPrice)
    }

    func testCannotCancelCompletedAppointment() {
        let appointment = F.appointment(start: F.date(hour: 10), minutes: 60, status: .completed)

        let result = AppointmentEngine.cancel(appointment: appointment)

        XCTAssertEqual(failure(of: result), .invalidStatus)
        XCTAssertEqual(appointment.status, .completed)
    }

    func testEditingCompletedAppointmentIsRejected() {
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
            startDate: F.date(hour: 12),
            duration: 60,
            notes: "",
            existingAppointments: []
        )

        XCTAssertEqual(failure(of: result), .invalidStatus)
        XCTAssertEqual(appointment.startDate, F.date(hour: 10), "Завершений запис не змінився")
        XCTAssertEqual(appointment.totalFinalPrice, 45)
        XCTAssertEqual(appointment.finalPrice, 45)
    }

    func testAllowedStatusTransitions() {
        let all: [AppointmentStatus] = [.active, .completed, .cancelled, .archived]
        let allowed: Set<String> = ["active→completed", "active→cancelled", "cancelled→active", "cancelled→archived"]

        for from in all {
            for to in all {
                XCTAssertEqual(
                    from.canChange(to: to),
                    allowed.contains("\(from.rawValue)→\(to.rawValue)"),
                    "\(from) → \(to)"
                )
            }
        }
    }

    func testRestoreCancelledAppointment() {
        let appointment = F.appointment(start: F.date(hour: 10), minutes: 60)
        AppointmentEngine.cancel(appointment: appointment)

        let result = AppointmentEngine.restore(appointment: appointment, existingAppointments: [appointment])

        XCTAssertNoThrow(try result.get())
        XCTAssertEqual(appointment.status, .active)
    }

    func testRestoreFailsWhenTimeIsTaken() {
        // Поки запис був скасований, на його час записали іншого клієнта
        let cancelled = F.appointment(start: F.date(hour: 10), minutes: 60, status: .cancelled)
        let newOne = F.appointment(start: F.date(hour: 10, 30), minutes: 60)

        let result = AppointmentEngine.restore(appointment: cancelled, existingAppointments: [cancelled, newOne])

        XCTAssertEqual(failure(of: result), .timeConflict)
        XCTAssertEqual(cancelled.status, .cancelled)
    }

    func testOnlyCancelledCanBeArchived() {
        let active = F.appointment(start: F.date(hour: 10), minutes: 60)
        XCTAssertEqual(failure(of: AppointmentEngine.archive(appointment: active)), .invalidStatus)
        XCTAssertEqual(active.status, .active)

        AppointmentEngine.cancel(appointment: active)
        XCTAssertNoThrow(try AppointmentEngine.archive(appointment: active).get())
        XCTAssertEqual(active.status, .archived)
        XCTAssertEqual(failure(of: AppointmentEngine.restore(appointment: active, existingAppointments: [])), .invalidStatus)
    }


    func testCancelAndRestoreTextsAreTranslated() {
        let keys = [
            "appointment.cancelConfirm.title", "appointment.cancelConfirm.message",
            "appointment.cancelConfirm.confirm", "appointment.cancelConfirm.keep",
            "appointment.restore", "appointment.restoreConflict.title",
            "appointment.restoreConflict.message", "common.ok"
        ]

        for language in SupportedLanguage.all.map(\.code) {
            let path = Bundle.main.path(forResource: language, ofType: "lproj")
            let bundle = path.flatMap(Bundle.init(path:))
            for key in keys {
                let text = bundle?.localizedString(forKey: key, value: nil, table: "Localizable")
                XCTAssertNotEqual(text, key, "\(language): \(key)")
            }
        }
    }


    private func failure(of result: Result<Void, AppointmentError>) -> AppointmentError? {
        if case .failure(let error) = result {
            return error
        }
        return nil
    }
}
