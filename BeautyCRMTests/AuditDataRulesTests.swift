//
//  AuditDataRulesTests.swift
//  BeautyCRMTests
//
//  Аудит: гроші, клієнти й фото, аналітика, межі періодів.
//

import XCTest
import UIKit
import SwiftData
@testable import BeautyCRM

final class AuditDataRulesTests: XCTestCase {

    private typealias F = AuditFixtures


    // MARK: - Гроші

    func testParseMoneyAcceptsCommaAndDot() {
        XCTAssertEqual(AppFormatting.parseMoney("12,50"), Decimal(string: "12.5"))
        XCTAssertEqual(AppFormatting.parseMoney(" 12.5 "), Decimal(string: "12.5"))
        XCTAssertEqual(AppFormatting.parseMoney("1 200"), 1200)
        XCTAssertNil(AppFormatting.parseMoney(""))
        XCTAssertNil(AppFormatting.parseMoney("abc"))
    }

    func testParseMoneyRejectsGarbage() {
        for text in ["12.5.3", "12abc", "abc12", "-5", "1,23,45", "1.2345", "1,234.567", "12 €", "1,5.00"] {
            XCTAssertNil(AppFormatting.parseMoney(text), text)
        }
    }

    func testParseMoneyThousandsSeparators() {
        // Німецький/чеський «1.234,50» і англійський «1,234.50» — тисяча двісті тридцять чотири
        XCTAssertEqual(AppFormatting.parseMoney("1.234,50"), Decimal(string: "1234.5"))
        XCTAssertEqual(AppFormatting.parseMoney("1,234.50"), Decimal(string: "1234.5"))
        XCTAssertEqual(AppFormatting.parseMoney("1.200"), 1200)
        XCTAssertEqual(AppFormatting.parseMoney("1.234.567"), 1234567)
        XCTAssertEqual(AppFormatting.parseMoney("1 234,5"), Decimal(string: "1234.5"))
    }

    func testParseMoneyEdgeCases() {
        XCTAssertEqual(AppFormatting.parseMoney("0"), 0)
        XCTAssertEqual(AppFormatting.parseMoney(",5"), Decimal(string: "0.5"))
        XCTAssertEqual(AppFormatting.parseMoney("12,"), 12)
        XCTAssertEqual(AppFormatting.parseMoney("25,05"), Decimal(string: "25.05"))
        XCTAssertNil(AppFormatting.parseMoney("   "))
    }

    func testDecimalSumsAreExact() {
        let items = (0..<10).map { _ in
            AppointmentServiceItem(serviceID: UUID(), serviceName: "X", plannedPrice: Decimal(string: "0.1")!)
        }
        let appointment = F.appointment(start: F.date(hour: 10), minutes: 60)
        appointment.services = items

        XCTAssertEqual(appointment.totalPlannedPrice, 1)
    }

    func testVariablePriceWithoutValueIsRejected() throws {
        let context = try F.makeContext()
        let service = Service(userID: F.userID, name: "Color", pricingType: .variable)
        let client = Client(userID: F.userID, name: "Demo Client")

        let result = AppointmentEngine.createAppointment(
            context: context,
            userID: F.userID,
            client: client,
            services: [service],
            selectedServiceIDs: [service.id],
            customPrices: [:],
            startDate: F.date(hour: 10),
            duration: 60,
            notes: "",
            existingAppointments: []
        )

        if case .failure(let error) = result {
            XCTAssertEqual(error, .missingPrice)
        } else {
            XCTFail("Запис з порожньою змінною ціною створено")
        }
        XCTAssertTrue(try context.fetch(FetchDescriptor<Appointment>()).isEmpty)
    }

    func testVariablePriceZeroTypedOnPurposeIsAllowed() throws {
        let context = try F.makeContext()
        let service = Service(userID: F.userID, name: "Consultation", pricingType: .variable)
        let client = Client(userID: F.userID, name: "Demo Client")

        let result = AppointmentEngine.createAppointment(
            context: context,
            userID: F.userID,
            client: client,
            services: [service],
            selectedServiceIDs: [service.id],
            customPrices: [service.id: 0],
            startDate: F.date(hour: 10),
            duration: 30,
            notes: "",
            existingAppointments: []
        )

        XCTAssertEqual(try result.get().totalPlannedPrice, 0)
    }


    // MARK: - Клієнти

    func testDeletingClientKeepsAppointmentsAndRevenue() throws {
        let context = try F.makeContext()
        let client = Client(userID: F.userID, name: "Demo Client")
        context.insert(client)

        let appointment = Appointment(
            userID: F.userID,
            clientID: client.id,
            clientName: client.name,
            startDate: F.date(hour: 10),
            duration: 60
        )
        appointment.services = [AppointmentServiceItem(serviceID: UUID(), serviceName: "Cut", plannedPrice: 40)]
        AppointmentEngine.complete(appointment: appointment, finalServicePrices: [:])
        context.insert(appointment)
        try context.save()

        ClientManager.delete(client: client, context: context)
        try context.save()

        XCTAssertNotNil(client.deletedAt)
        XCTAssertEqual(appointment.clientID, client.id)
        XCTAssertEqual(appointment.clientName, "Demo Client")
        XCTAssertEqual(appointment.finalPrice, 40, "Дохід за видаленим клієнтом лишається в аналітиці")
    }

    func testPhotoDeletionRemovesThumbnailToo() throws {
        let context = try F.makeContext()
        let client = Client(userID: F.userID, name: "Demo Client")
        context.insert(client)

        let image = UIGraphicsImageRenderer(size: CGSize(width: 600, height: 400)).image { ctx in
            UIColor.systemPink.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 600, height: 400))
        }

        ClientPhotoService.addPhoto(image: image, client: client, context: context)
        let photo = try XCTUnwrap(client.photos.first)
        XCTAssertNotNil(ClientPhotoStorage.loadThumbnail(from: photo.fileName))

        ClientPhotoService.deletePhoto(photo: photo, client: client, context: context)
        PhotoThumbnailCache.remove(for: photo.fileName)

        XCTAssertNil(ClientPhotoStorage.loadImage(from: photo.fileName), "Повне фото видалено")

        XCTExpectFailure("AUDIT: мініатюра в client_photos_thumbs лишається на диску після видалення фото")
        XCTAssertNil(ClientPhotoStorage.loadThumbnail(from: photo.fileName))
    }

    func testContactLinksDoNotCrashOnTypicalInput() {
        // ClientContactSection будує посилання через URL(string:)! — перевіряємо типові введення
        let phones = ["+380 67 123 45 67", "(050) 123-45-67", "+49 151 2345678"]
        for phone in phones {
            XCTAssertNotNil(URL(string: "tel://\(phone)"), phone)
        }
        // Нік з «@» дає неправильне посилання instagram.com/@nick
        XCTAssertEqual(URL(string: "https://instagram.com/@demo.nick")?.lastPathComponent, "@demo.nick")
    }


    // MARK: - Аналітика клієнта

    func testClientAnalyticsWithoutVisitsHasNoDivisionByZero() {
        let client = Client(userID: F.userID, name: "Demo Client")

        let result = ClientAnalyticsCalculator.calculate(client: client, appointments: [])

        XCTAssertEqual(result.averageCheck, 0)
        XCTAssertEqual(result.revenue, 0)
        XCTAssertNil(result.lastVisitDate)
    }

    func testClientAnalyticsCountsOnlyCompletedRevenue() {
        let client = Client(userID: F.userID, name: "Demo Client")

        func visit(_ day: Int, _ status: AppointmentStatus, _ price: Decimal) -> Appointment {
            let appointment = Appointment(
                userID: F.userID, clientID: client.id, clientName: client.name,
                startDate: F.date(2026, 11, day, 10), duration: 60
            )
            appointment.status = status
            appointment.finalPrice = status == .completed ? price : nil
            return appointment
        }

        let result = ClientAnalyticsCalculator.calculate(
            client: client,
            appointments: [
                visit(2, .completed, 30),
                visit(3, .completed, Decimal(string: "45.50")!),
                visit(4, .cancelled, 0),
                visit(5, .archived, 0),
                visit(6, .active, 0)
            ]
        )

        XCTAssertEqual(result.totalVisits, 5)
        XCTAssertEqual(result.completedVisits, 2)
        XCTAssertEqual(result.cancelledVisits, 2)
        XCTAssertEqual(result.revenue, Decimal(string: "75.50"))
        XCTAssertEqual(result.averageCheck, Decimal(string: "37.75"))
        XCTAssertEqual(result.lastVisitDate, F.date(2026, 11, 3, 10))
    }


    // MARK: - Межі періодів (так само, як рахує AnalyticsView)

    private var europeanCalendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
    }

    func testSundayBelongsToWeekStartingMonday() {
        let monday = F.date(2026, 11, 2, 9)
        let sunday = F.date(2026, 11, 8, 22)
        let nextMonday = F.date(2026, 11, 9, 0, 1)

        XCTAssertTrue(europeanCalendar.isDate(sunday, equalTo: monday, toGranularity: .weekOfYear))
        XCTAssertFalse(europeanCalendar.isDate(nextMonday, equalTo: monday, toGranularity: .weekOfYear))
    }

    func testWeekAcrossNewYearIsOneWeek() {
        // 31.12.2026 — четвер, 01.01.2027 — п'ятниця: один тиждень
        let thursday = F.date(2026, 12, 31, 12)
        let friday = F.date(2027, 1, 1, 12)

        XCTAssertTrue(europeanCalendar.isDate(thursday, equalTo: friday, toGranularity: .weekOfYear))
    }

    func testMonthBoundaryLastMinute() {
        let lastMinute = F.date(2026, 11, 30, 23, 59)
        let components = europeanCalendar.dateComponents([.year, .month], from: lastMinute)

        XCTAssertEqual(components.month, 11)
        XCTAssertEqual(europeanCalendar.dateComponents([.month], from: F.date(2026, 12, 1, 0)).month, 12)
    }
}
