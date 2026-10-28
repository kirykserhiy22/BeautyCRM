//
//  AuditDemoDataSeeder.swift
//  BeautyCRMTests
//
//  Заповнює додаток вигаданими демо-даними для скріншотів аудиту.
//  Працює ТІЛЬКИ коли запущено з AUDIT_SEED=1 (через TEST_RUNNER_AUDIT_SEED=1
//  у xcodebuild) — у звичайному прогоні тестів пропускається і нічого не чіпає.
//
//  Порядок: ScreenshotTourTests.test01_RegisterMaster реєструє майстра через UI →
//  цей «тест» дописує клієнтів, послуги, записи → ScreenshotTourTests.test02… знімає екрани.
//

import XCTest
import UIKit
import SwiftData
@testable import BeautyCRM

final class AuditDemoDataSeeder: XCTestCase {

    static let email = "demo.master@example.com"

    func testSeedDemoData() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["AUDIT_SEED"] == "1",
            "Демо-дані заливаються лише для скріншотів аудиту"
        )

        // Той самий файл бази, що й у додатку (конфігурація за замовчуванням)
        let container = try ModelContainer(
            for: UserProfile.self, Client.self, Appointment.self, Service.self, DayOff.self
        )
        let context = ModelContext(container)
        SyncTracking.start()

        let userID = try XCTUnwrap(registeredUserID(), "Спершу зареєструйте майстра (test01_RegisterMaster)")
        let profile = try XCTUnwrap(UserProfileManager.profile(context: context, userID: userID))
        SyncTracking.currentWorkspaceID = profile.workspaceID

        let existing = try context.fetch(FetchDescriptor<Client>(predicate: #Predicate { $0.userID == userID }))
        guard existing.isEmpty else {
            return // уже заповнено
        }

        // MARK: Послуги

        let haircut = Service(userID: userID, name: "Haircut", pricingType: .fixed, price: 35)
        let coloring = Service(userID: userID, name: "Coloring", pricingType: .variable)
        let styling = Service(userID: userID, name: "Styling", pricingType: .fixed, price: Decimal(string: "25.50")!)
        let keratin = Service(userID: userID, name: "Keratin treatment", pricingType: .fixed, price: 120)
        let services = [haircut, coloring, styling, keratin]
        services.forEach(context.insert)

        // MARK: Клієнти (вигадані)

        let people: [(String, String?, String?, String?)] = [
            ("Olivia Hart", "+49 151 0000 0101", "olivia.demo", "Prefers cool blonde tones."),
            ("Mia Novak", "+420 600 000 102", nil, nil),
            ("Sofia Brandt", "+49 151 0000 0103", "sofia.demo", "Sensitive scalp."),
            ("Emma Kowal", "+48 500 000 104", nil, nil),
            ("Lena Fischer", nil, "lena.demo", nil),
            ("Nora Petrenko", "+380 67 000 01 06", nil, "Always 10 min early."),
            ("Ivy Lindholm", "+44 7700 900107", nil, nil)
        ]
        let clients = people.map { name, phone, instagram, notes in
            Client(userID: userID, name: name, phone: phone, instagram: instagram, notes: notes)
        }
        clients.forEach(context.insert)
        try context.save()

        // Кілька фото першому клієнту
        for hue in [0.92, 0.08, 0.55] {
            ClientPhotoService.addPhoto(image: Self.demoImage(hue: hue), client: clients[0], context: context)
        }

        // MARK: Записи

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        func at(_ dayOffset: Int, _ hour: Int, _ minute: Int = 0) -> Date {
            let day = calendar.date(byAdding: .day, value: dayOffset, to: today)!
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)!
        }

        func book(
            _ client: Client,
            _ start: Date,
            _ minutes: Int,
            _ picked: [Service],
            variable: Decimal = 80,
            status: AppointmentStatus = .active,
            tip: Decimal = 0
        ) {
            let appointment = Appointment(
                userID: userID, clientID: client.id, clientName: client.name,
                startDate: start, duration: minutes
            )
            appointment.services = picked.map {
                AppointmentServiceItem(
                    serviceID: $0.id, serviceName: $0.name,
                    plannedPrice: $0.pricingType == .fixed ? ($0.price ?? 0) : variable
                )
            }
            context.insert(appointment)

            switch status {
            case .completed:
                let first = picked[0].id
                let planned = appointment.services[0].plannedPrice
                AppointmentEngine.complete(appointment: appointment, finalServicePrices: [first: planned + tip])
                appointment.completedAt = start.addingTimeInterval(Double(minutes) * 60)
            case .cancelled:
                AppointmentEngine.cancel(appointment: appointment)
            default:
                break
            }
        }

        // Минулі місяці — для аналітики місяця й року
        for monthsAgo in 1...9 {
            for (index, client) in clients.enumerated() where (index + monthsAgo) % 3 != 0 {
                let base = calendar.date(byAdding: .month, value: -monthsAgo, to: today)!
                let day = calendar.date(byAdding: .day, value: index * 3 - 10, to: base)!
                let start = calendar.date(bySettingHour: 10 + index % 6, minute: 0, second: 0, of: day)!
                let picked = index % 2 == 0 ? [haircut, styling] : [coloring]
                book(client, start, picked.count * 60, picked, variable: 70 + Decimal(index * 5),
                     status: .completed, tip: Decimal(index))
            }
        }

        // Цей тиждень: позавчора, вчора, сьогодні, завтра, післязавтра
        book(clients[1], at(-2, 10), 60, [haircut], status: .completed, tip: 5)
        book(clients[2], at(-2, 14), 120, [coloring], variable: 95, status: .completed)
        book(clients[3], at(-1, 11), 60, [haircut], status: .completed)
        book(clients[4], at(-1, 15), 90, [keratin], status: .cancelled)
        book(clients[0], at(0, 9), 90, [haircut, styling], status: .completed, tip: 10)
        book(clients[5], at(0, 12), 120, [coloring], variable: 90)
        book(clients[6], at(0, 17), 60, [haircut])
        book(clients[2], at(1, 10), 60, [styling])
        book(clients[3], at(1, 13), 150, [keratin])
        book(clients[1], at(2, 11), 60, [haircut, styling])

        // Вихідний через три дні
        context.insert(DayOff(userID: userID, date: at(3, 0)))

        try context.save()
    }


    // MARK: - HELPERS

    private func registeredUserID() -> String? {
        guard
            let data = UserDefaults.standard.data(forKey: "local_users"),
            let users = try? JSONDecoder().decode([AuthCredentials].self, from: data)
        else {
            return nil
        }
        return users.first { $0.email == Self.email }?.userID
    }

    // Абстрактна картинка-заглушка замість реального фото
    private static func demoImage(hue: CGFloat) -> UIImage {
        let size = CGSize(width: 900, height: 1200)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            let colors = [
                UIColor(hue: hue, saturation: 0.35, brightness: 0.95, alpha: 1).cgColor,
                UIColor(hue: hue, saturation: 0.6, brightness: 0.7, alpha: 1).cgColor
            ] as CFArray
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
            ctx.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
            UIColor.white.withAlphaComponent(0.35).setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 250, y: 300, width: 400, height: 520))
        }
    }
}
