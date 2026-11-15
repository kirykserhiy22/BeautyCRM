//
//  MarketingDemoDataSeeder.swift
//  BeautyCRMTests
//
//  Українські демо-дані для контенту Instagram (скріни, записи екрана).
//  Працює ТІЛЬКИ з MARKETING_SEED=1 (TEST_RUNNER_MARKETING_SEED=1 у xcodebuild) —
//  у звичайному прогоні тестів пропускається і нічого не чіпає.
//
//  Запуск — скриптом docs/marketing/prepare-simulator.sh на окремому симуляторі:
//  реєстрація майстра через UI (ScreenshotTourTests.test01_RegisterMaster) → цей «тест».
//  Усі люди вигадані.
//

import XCTest
import UIKit
import SwiftData
@testable import BeautyCRM

final class MarketingDemoDataSeeder: XCTestCase {

    static let email = "demo.master@example.com"

    func testSeedMarketingData() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["MARKETING_SEED"] == "1",
            "Демо-дані для контенту заливаються лише скриптом docs/marketing/prepare-simulator.sh"
        )

        let container = try ModelContainer(
            for: UserProfile.self, Client.self, Appointment.self, Service.self, DayOff.self
        )
        let context = ModelContext(container)
        SyncTracking.start()

        let userID = try XCTUnwrap(registeredUserID(), "Спершу зареєструйте майстра (test01_RegisterMaster)")
        let profile = try XCTUnwrap(UserProfileManager.profile(context: context, userID: userID))
        SyncTracking.currentWorkspaceID = profile.workspaceID

        // Майстер без особистого імені: на Головній «Доброго дня, Майстер» —
        // кожен глядач бачить себе, а не конкретну людину
        let language = ProcessInfo.processInfo.environment["MARKETING_LANG"] ?? "uk"
        let neutralNames = ["uk": "Майстер", "en": "Master", "de": "Meister", "pl": "Mistrz", "cs": "Mistr"]
        profile.firstName = neutralNames[language] ?? "Майстер"
        profile.lastName = ""
        profile.businessName = "Beauty Studio"
        profile.reminderSignature = "Beauty Studio"
        profile.workStartMinute = 9 * 60
        profile.workEndMinute = 19 * 60
        profile.reminderAddress = "вул. Шевченка 12, каб. 4"
        // Мова додатку береться з профілю при кожному запуску
        profile.languageCode = language

        // Гід уже бачили — не перекриває екрани
        OnboardingStore.markSeen(userID: userID)

        let existing = try context.fetch(FetchDescriptor<Client>(predicate: #Predicate { $0.userID == userID }))
        guard existing.isEmpty else {
            try context.save()
            return // уже заповнено
        }

        // MARK: Послуги

        let haircut = Service(userID: userID, name: "Жіноча стрижка", pricingType: .fixed, price: 45)
        let roots = Service(userID: userID, name: "Фарбування корінь", pricingType: .variable)
        let toning = Service(userID: userID, name: "Тонування", pricingType: .fixed, price: 35)
        let styling = Service(userID: userID, name: "Укладка", pricingType: .fixed, price: 25)
        let airtouch = Service(userID: userID, name: "AirTouch", pricingType: .variable)
        let keratin = Service(userID: userID, name: "Кератин", pricingType: .fixed, price: 120)
        [haircut, roots, toning, styling, airtouch, keratin].forEach(context.insert)

        // MARK: Клієнтки (вигадані)

        func client(_ name: String, phone: String?, instagram: String? = nil, telegram: String? = nil, notes: String? = nil) -> Client {
            let item = Client(userID: userID, name: name, phone: phone, instagram: instagram, telegram: telegram, notes: notes)
            context.insert(item)
            return item
        }

        let olena = client("Олена Коваль", phone: "+380 67 123 45 01", instagram: "olena.koval", telegram: "@olena_k",
                           notes: "Холодні відтінки. Чутлива шкіра голови.")
        let maryna = client("Марина Шевчук", phone: "+380 50 123 45 02", instagram: "maryna.sh")
        let iryna = client("Ірина Бондар", phone: "+49 151 2345 0103", telegram: "@iryna_b", notes: "Завжди приходить на 10 хв раніше.")
        let anna = client("Анна Ткаченко", phone: "+380 93 123 45 04", instagram: "anna.tk")
        let sofia = client("Софія Мельник", phone: "+48 501 234 105")
        let kateryna = client("Катерина Литвин", phone: "+380 66 123 45 06", instagram: "kate.lytvyn")
        let daryna = client("Дарина Кравець", phone: "+380 97 123 45 07", telegram: "@daryna_k")
        let yulia = client("Юлія Мороз", phone: "+420 601 234 108")
        let clients = [olena, maryna, iryna, anna, sofia, kateryna, daryna, yulia]
        try context.save()

        // Фото «до / після» — допис-карусель у Олени
        let post = UUID()
        ClientPhotoService.addPhoto(fileName: try store(Self.demoImage(hue: 0.08)), stage: .before,
                                    caption: "Корінь 6.1 + тонування 9.1, без жовтизни", postID: post,
                                    client: olena, context: context)
        ClientPhotoService.addPhoto(fileName: try store(Self.demoImage(hue: 0.12, light: true)), stage: .after,
                                    postID: post, client: olena, context: context)

        // MARK: Записи

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        func at(_ dayOffset: Int, _ hour: Int, _ minute: Int = 0) -> Date {
            let day = calendar.date(byAdding: .day, value: dayOffset, to: today)!
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)!
        }

        @discardableResult
        func book(
            _ client: Client, _ start: Date, _ minutes: Int, _ picked: [Service],
            variable: Decimal = 80, paid: Decimal? = nil, notes: String? = nil,
            status: AppointmentStatus = .active
        ) -> Appointment {
            let appointment = Appointment(
                userID: userID, clientID: client.id, clientName: client.name,
                startDate: start, duration: minutes, notes: notes
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
                // Перша послуга — фактична ціна (буває більша за план: більше фарби)
                var prices: [UUID: Decimal] = [:]
                for item in appointment.services { prices[item.serviceID] = item.plannedPrice }
                if let paid, let first = appointment.services.first {
                    prices[first.serviceID] = paid - appointment.services.dropFirst().reduce(0) { $0 + $1.plannedPrice }
                }
                AppointmentEngine.complete(appointment: appointment, finalServicePrices: prices)
                appointment.completedAt = start.addingTimeInterval(Double(minutes) * 60)
            case .cancelled:
                AppointmentEngine.cancel(appointment: appointment)
            default:
                break
            }
            return appointment
        }

        // Олена: фарбує корінь кожні ~6 тижнів — ідеально для «Записати так само»
        for (weeksAgo, paid) in [(6, 115), (12, 110), (18, 110), (24, 105), (30, 105)] {
            book(olena, at(-weeksAgo * 7, 10), 120, [roots, toning], variable: 75, paid: Decimal(paid),
                 notes: "Фарба 6.1 + 30 г освітлювача, витримка 35 хв", status: .completed)
        }

        // Решта — різні послуги за останні пів року (для Аналітики)
        let rotations: [[Service]] = [[haircut, styling], [airtouch], [haircut], [keratin], [roots], [haircut, toning]]
        for monthsAgo in 1...6 {
            for (index, client) in clients.dropFirst().enumerated() where (index + monthsAgo) % 3 != 0 {
                let base = calendar.date(byAdding: .month, value: -monthsAgo, to: today)!
                let day = calendar.date(byAdding: .day, value: index * 3 - 9, to: base)!
                let start = calendar.date(bySettingHour: 10 + index % 7, minute: 0, second: 0, of: day)!
                let picked = rotations[(index + monthsAgo) % rotations.count]
                book(client, start, picked.count * 60 + 30, picked, variable: 140 + Decimal(index * 10), status: .completed)
            }
        }

        // Цей тиждень
        book(maryna, at(-2, 10), 90, [haircut, styling], status: .completed)
        book(iryna, at(-1, 12), 180, [airtouch], variable: 180, paid: 190, status: .completed)
        book(sofia, at(-1, 16), 60, [haircut], status: .cancelled)
        book(anna, at(0, 9, 30), 90, [haircut, styling], status: .completed)
        book(olena, at(0, 12), 120, [roots, toning], variable: 75, notes: "Фарба 6.1 + 30 г освітлювача")
        book(kateryna, at(0, 15), 60, [haircut])
        book(daryna, at(0, 16, 30), 120, [keratin])
        book(yulia, at(1, 10), 60, [haircut, styling])
        book(maryna, at(1, 13), 180, [airtouch], variable: 180)
        book(iryna, at(2, 11), 60, [toning])

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

    private func store(_ image: UIImage) throws -> String {
        try XCTUnwrap(ClientPhotoService.storeFiles(for: image))
    }

    // Абстрактна картинка-заглушка (тепло-русяві тони) замість реального фото
    private static func demoImage(hue: CGFloat, light: Bool = false) -> UIImage {
        let size = CGSize(width: 1080, height: 1350)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            let colors = [
                UIColor(hue: hue, saturation: light ? 0.25 : 0.45, brightness: light ? 0.98 : 0.8, alpha: 1).cgColor,
                UIColor(hue: hue, saturation: light ? 0.4 : 0.65, brightness: light ? 0.85 : 0.55, alpha: 1).cgColor
            ] as CFArray
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
            ctx.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
            UIColor.white.withAlphaComponent(0.3).setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 290, y: 330, width: 500, height: 640))
        }
    }
}
