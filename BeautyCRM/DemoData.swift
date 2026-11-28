//
//  DemoData.swift
//  BeautyCRM
//
//  «Пісочниця» для нового майстра: демо-клієнтки, записи за пів року, фото й вихідний —
//  окремий набір під кожну спеціалізацію (перукар, нігті, вії й брови). Усі люди вигадані,
//  фото — AI-рендери з BeautyCRM/DemoPhotos.
//
//  Демо-записи запам'ятовуються за id (DemoStore). «Почати роботу» видаляє саме їх,
//  справжні дані майстра не чіпаються. Демо ніколи не синхронізується, тому видаляється
//  повністю (context.delete), а не «м'яко», як справжні записи.
//

import Foundation
import SwiftData
import UIKit


// MARK: - STORE

// Чи ввімкнено демо і які записи — демо (окремо для кожного майстра)
enum DemoStore {

    struct Snapshot: Codable, Equatable {
        var clients: [UUID] = []
        var services: [UUID] = []
        var appointments: [UUID] = []
        var dayOffs: [UUID] = []
    }

    private static func key(_ userID: String) -> String { "demo.data.\(userID)" }

    static func snapshot(userID: String, defaults: UserDefaults = .standard) -> Snapshot? {
        guard let data = defaults.data(forKey: key(userID)) else { return nil }
        return try? JSONDecoder().decode(Snapshot.self, from: data)
    }

    static func isActive(userID: String?, defaults: UserDefaults = .standard) -> Bool {
        guard let userID else { return false }
        return snapshot(userID: userID, defaults: defaults) != nil
    }

    static func save(_ snapshot: Snapshot, userID: String, defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: key(userID))
        }
    }

    static func clear(userID: String, defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key(userID))
    }
}


// MARK: - CONTENT

// Що саме бачить майстер певної спеціалізації
struct DemoContent {

    struct DemoService {
        let name: String
        let price: Decimal?      // nil — змінна ціна
        let minutes: Int
        let typicalPrice: Decimal
    }

    let services: [DemoService]
    let clients: [(name: String, phone: String, instagram: String?, notes: String?)]
    // Нотатки до візитів (формула, що сподобалось)
    let visitNotes: [String]
    // Фото робіт: пари «до/після» або одиночні; references — фото від клієнток
    let workPairs: [(before: String, after: String, caption: String)]
    let workSingles: [(file: String, caption: String)]
    let references: [String]

    static func forProfession(_ profession: Profession?) -> DemoContent {
        switch profession ?? .hairStylist {

        case .hairStylist:
            return DemoContent(
                services: [
                    .init(name: "Жіноча стрижка", price: 45, minutes: 60, typicalPrice: 45),
                    .init(name: "Фарбування корінь", price: nil, minutes: 120, typicalPrice: 75),
                    .init(name: "AirTouch", price: nil, minutes: 240, typicalPrice: 190),
                    .init(name: "Тотал блонд", price: nil, minutes: 300, typicalPrice: 220),
                    .init(name: "Тонування", price: 35, minutes: 60, typicalPrice: 35),
                    .init(name: "Укладка", price: 25, minutes: 45, typicalPrice: 25)
                ],
                clients: [
                    ("Олена Коваль", "+380 67 123 45 01", "olena.koval", "Холодні відтінки. Чутлива шкіра голови."),
                    ("Марина Шевчук", "+380 50 123 45 02", "maryna.sh", nil),
                    ("Ірина Бондар", "+49 151 2345 0103", nil, "Завжди приходить на 10 хв раніше."),
                    ("Анна Ткаченко", "+380 93 123 45 04", "anna.tk", nil),
                    ("Софія Мельник", "+48 501 234 105", nil, nil),
                    ("Катерина Литвин", "+380 66 123 45 06", "kate.lytvyn", "Любить мідні відтінки."),
                    ("Дарина Кравець", "+380 97 123 45 07", nil, nil),
                    ("Юлія Мороз", "+420 601 234 108", nil, nil)
                ],
                visitNotes: [
                    "Фарба 6.1 + 30 г освітлювача, витримка 35 хв",
                    "Тонування 9.1, без жовтизни",
                    "Наступного разу — на 1 см коротше",
                    "Мідь 7.44, корінь у тон"
                ],
                workPairs: [
                    ("demo-hair-before-blond", "demo-hair-after-blond", "Корінь 6.1 + тонування 9.1"),
                    ("demo-hair-before-copper", "demo-hair-after-copper", "Мідь 7.44"),
                    ("demo-hair-before-dark", "demo-hair-after-dark", "Освітлення з темної бази")
                ],
                workSingles: [
                    ("demo-hair-airtouch-1", "AirTouch, холодний блонд"),
                    ("demo-hair-airtouch-2", "AirTouch"),
                    ("demo-hair-blond-1", "Тотал блонд"),
                    ("demo-hair-blond-2", "Тотал блонд 10.1")
                ],
                references: ["demo-hair-airtouch-3", "demo-hair-airtouch-4", "demo-hair-blond-3"]
            )

        case .nailArtist:
            return DemoContent(
                services: [
                    .init(name: "Манікюр з покриттям", price: 35, minutes: 90, typicalPrice: 35),
                    .init(name: "Манікюр без покриття", price: 20, minutes: 45, typicalPrice: 20),
                    .init(name: "Педикюр", price: 40, minutes: 90, typicalPrice: 40),
                    .init(name: "Нарощення нігтів", price: nil, minutes: 150, typicalPrice: 55),
                    .init(name: "Дизайн", price: nil, minutes: 30, typicalPrice: 10),
                    .init(name: "Зняття покриття", price: 10, minutes: 30, typicalPrice: 10)
                ],
                clients: [
                    ("Олена Коваль", "+380 67 123 45 01", "olena.koval", "Лише нюдові відтінки."),
                    ("Марина Шевчук", "+380 50 123 45 02", "maryna.sh", nil),
                    ("Ірина Бондар", "+49 151 2345 0103", nil, "Тонкі нігті — без агресивного запилу."),
                    ("Анна Ткаченко", "+380 93 123 45 04", "anna.tk", nil),
                    ("Софія Мельник", "+48 501 234 105", nil, nil),
                    ("Катерина Литвин", "+380 66 123 45 06", "kate.lytvyn", "Любить френч."),
                    ("Дарина Кравець", "+380 97 123 45 07", nil, nil),
                    ("Юлія Мороз", "+420 601 234 108", nil, nil)
                ],
                visitNotes: [
                    "Форма мигдаль, база камуфлююча 03",
                    "Френч, біла смужка тонша",
                    "Бордо + золото на безіменному",
                    "Подовжили на 2 мм"
                ],
                workPairs: [],
                workSingles: [
                    ("demo-nails-manicure-1", "Нюд, мигдаль"),
                    ("demo-nails-manicure-2", "Дизайн з блиском"),
                    ("demo-nails-manicure-7", "Нюд із золотом"),
                    ("demo-nails-manicure-8", "Френч"),
                    ("demo-nails-manicure-9", "Бордо"),
                    ("demo-nails-pedicure-1", "Педикюр, світле покриття"),
                    ("demo-nails-pedicure-2", "Педикюр, бордо")
                ],
                references: ["demo-nails-manicure-3", "demo-nails-manicure-4", "demo-nails-manicure-5", "demo-nails-manicure-6"]
            )

        case .lashBrowArtist:
            return DemoContent(
                services: [
                    .init(name: "Нарощення вій 2D", price: 40, minutes: 120, typicalPrice: 40),
                    .init(name: "Корекція нарощення", price: 30, minutes: 90, typicalPrice: 30),
                    .init(name: "Ламінування вій", price: 35, minutes: 60, typicalPrice: 35),
                    .init(name: "Корекція брів", price: 15, minutes: 30, typicalPrice: 15),
                    .init(name: "Фарбування брів", price: 15, minutes: 30, typicalPrice: 15),
                    .init(name: "Ламінування брів", price: nil, minutes: 60, typicalPrice: 35)
                ],
                clients: [
                    ("Олена Коваль", "+380 67 123 45 01", "olena.koval", "Ефект «лисичка», вигин C."),
                    ("Марина Шевчук", "+380 50 123 45 02", "maryna.sh", nil),
                    ("Ірина Бондар", "+49 151 2345 0103", nil, "Чутливі очі — клей без запаху."),
                    ("Анна Ткаченко", "+380 93 123 45 04", "anna.tk", nil),
                    ("Софія Мельник", "+48 501 234 105", nil, nil),
                    ("Катерина Литвин", "+380 66 123 45 06", "kate.lytvyn", "Брови — натуральна форма."),
                    ("Дарина Кравець", "+380 97 123 45 07", nil, nil),
                    ("Юлія Мороз", "+420 601 234 108", nil, nil)
                ],
                visitNotes: [
                    "2D, вигин C, 9–12 мм",
                    "Ламінування: склад 1 — 8 хв, склад 2 — 6 хв",
                    "Фарба для брів: коричнева 2 + графіт 1",
                    "Наступна корекція через 3 тижні"
                ],
                workPairs: [],
                workSingles: [
                    ("demo-lash-1", "2D, вигин C"),
                    ("demo-lash-2", "Ламінування вій"),
                    ("demo-lash-3", "Брови після ламінування"),
                    ("demo-lash-4", "Ефект «лисичка»")
                ],
                references: ["demo-lash-5", "demo-lash-6"]
            )
        }
    }
}


// MARK: - SEED / CLEAR

enum DemoData {

    // Заповнити демо: послуги, клієнтки, записи за пів року і цей тиждень, фото, вихідний
    @discardableResult
    static func load(
        userID: String,
        profession: Profession?,
        context: ModelContext,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> DemoStore.Snapshot {

        let content = DemoContent.forProfession(profession)
        var snapshot = DemoStore.Snapshot()

        // Послуги
        let services: [(Service, DemoContent.DemoService)] = content.services.map { item in
            let service = Service(
                userID: userID,
                name: item.name,
                pricingType: item.price == nil ? .variable : .fixed,
                price: item.price
            )
            context.insert(service)
            snapshot.services.append(service.id)
            return (service, item)
        }

        // Клієнтки: «з нами» від 1 до 8 місяців
        let clients: [Client] = content.clients.enumerated().map { index, item in
            let client = Client(userID: userID, name: item.name, phone: item.phone, instagram: item.instagram, notes: item.notes)
            client.createdAt = calendar.date(byAdding: .month, value: -(8 - index), to: now) ?? now
            context.insert(client)
            snapshot.clients.append(client.id)
            return client
        }

        let today = calendar.startOfDay(for: now)

        func at(_ dayOffset: Int, _ hour: Int, _ minute: Int = 0) -> Date {
            let day = calendar.date(byAdding: .day, value: dayOffset, to: today) ?? today
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
        }

        @discardableResult
        func book(
            _ client: Client,
            _ start: Date,
            _ picked: [(Service, DemoContent.DemoService)],
            paidExtra: Decimal = 0,
            notes: String? = nil,
            status: AppointmentStatus = .active
        ) -> Appointment {
            let minutes = picked.reduce(0) { $0 + $1.1.minutes }
            let appointment = Appointment(
                userID: userID, clientID: client.id, clientName: client.name,
                startDate: start, duration: minutes, notes: notes
            )
            appointment.services = picked.map {
                AppointmentServiceItem(serviceID: $0.0.id, serviceName: $0.0.name, plannedPrice: $0.1.price ?? $0.1.typicalPrice)
            }
            context.insert(appointment)
            snapshot.appointments.append(appointment.id)

            switch status {
            case .completed:
                var prices: [UUID: Decimal] = [:]
                for item in appointment.services { prices[item.serviceID] = item.plannedPrice }
                if let first = appointment.services.first {
                    prices[first.serviceID] = first.plannedPrice + paidExtra
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

        let s = services
        func pick(_ indexes: Int...) -> [(Service, DemoContent.DemoService)] {
            indexes.compactMap { s.indices.contains($0) ? s[$0] : nil }
        }

        // Постійна клієнтка: та сама послуга кожні ~5 тижнів — для «Записати так само» й історії
        for (round, weeksAgo) in [5, 10, 15, 20, 25].enumerated() {
            book(clients[0], at(-weeksAgo * 7, 10), pick(1), paidExtra: Decimal(round % 2 * 5),
                 notes: content.visitNotes[round % content.visitNotes.count], status: .completed)
        }

        // Решта — різні послуги за пів року (для аналітики)
        let rotations: [[Int]] = [[0, 5], [2], [0], [3], [1, 4], [4]]
        for monthsAgo in 1...6 {
            for (index, client) in clients.dropFirst().enumerated() where (index + monthsAgo) % 3 != 0 {
                let base = calendar.date(byAdding: .month, value: -monthsAgo, to: today) ?? today
                let day = calendar.date(byAdding: .day, value: index * 3 - 9, to: base) ?? base
                let start = calendar.date(bySettingHour: 9 + index % 8, minute: 0, second: 0, of: day) ?? day
                let picked = rotations[(index + monthsAgo) % rotations.count].compactMap { s.indices.contains($0) ? s[$0] : nil }
                book(client, start, picked, paidExtra: Decimal(index % 3 * 5),
                     notes: index % 2 == 0 ? content.visitNotes[index % content.visitNotes.count] : nil,
                     status: .completed)
            }
        }

        // Цей тиждень: минуле завершене, попереду заплановане, одне скасоване
        book(clients[1], at(-2, 10), pick(0, 5), status: .completed)
        book(clients[2], at(-1, 12), pick(2), paidExtra: 10, status: .completed)
        book(clients[4], at(-1, 17), pick(0), status: .cancelled)
        let upcoming = book(clients[3], at(1, 10), pick(1, 4), notes: content.visitNotes[1])
        book(clients[5], at(1, 15), pick(0))
        book(clients[6], at(2, 11), pick(3))
        book(clients[7], at(2, 16), pick(5))
        book(clients[0], at(4, 10), pick(1), notes: content.visitNotes[0])

        // Вихідний через три дні
        let dayOff = DayOff(userID: userID, date: at(3, 0))
        context.insert(dayOff)
        snapshot.dayOffs.append(dayOff.id)

        context.saveReportingErrors()

        // Фото: роботи «до/після», одиночні, референси до найближчого запису
        func file(_ name: String) -> String? {
            guard let url = Bundle.main.url(forResource: name, withExtension: "jpg"),
                  let image = UIImage(contentsOfFile: url.path) else { return nil }
            return ClientPhotoService.storeFiles(for: image)
        }

        for (index, pair) in content.workPairs.enumerated() {
            let client = clients[index % clients.count]
            let post = UUID()
            if let before = file(pair.before) {
                ClientPhotoService.addPhoto(fileName: before, stage: .before, caption: pair.caption, postID: post, client: client, context: context)
            }
            if let after = file(pair.after) {
                ClientPhotoService.addPhoto(fileName: after, stage: .after, postID: post, client: client, context: context)
            }
        }
        for (index, single) in content.workSingles.enumerated() {
            let client = clients[(index + content.workPairs.count) % clients.count]
            if let name = file(single.file) {
                ClientPhotoService.addPhoto(fileName: name, caption: single.caption, client: client, context: context)
            }
        }
        if let referenceClient = clients.first(where: { $0.id == upcoming.clientID }) {
            for reference in content.references {
                if let name = file(reference) {
                    ClientPhotoService.addPhoto(fileName: name, kind: .reference, appointmentID: upcoming.id, client: referenceClient, context: context)
                }
            }
        }

        DemoStore.save(snapshot, userID: userID)
        return snapshot
    }


    // «Почати роботу»: видалити все демо (і файли фото). Справжні записи майстра не чіпаються
    static func clear(userID: String, context: ModelContext) {

        guard let snapshot = DemoStore.snapshot(userID: userID) else {
            return
        }

        let clientIDs = Set(snapshot.clients)
        let serviceIDs = Set(snapshot.services)
        let appointmentIDs = Set(snapshot.appointments)
        let dayOffIDs = Set(snapshot.dayOffs)

        let clients = (try? context.fetch(FetchDescriptor<Client>())) ?? []
        for client in clients where clientIDs.contains(client.id) {
            for photo in client.photos {
                ClientPhotoStorage.deleteImage(at: photo.fileName)
                context.delete(photo)
            }
            context.delete(client)
        }

        for appointment in (try? context.fetch(FetchDescriptor<Appointment>())) ?? [] where appointmentIDs.contains(appointment.id) {
            context.delete(appointment)
        }
        for service in (try? context.fetch(FetchDescriptor<Service>())) ?? [] where serviceIDs.contains(service.id) {
            context.delete(service)
        }
        for dayOff in (try? context.fetch(FetchDescriptor<DayOff>())) ?? [] where dayOffIDs.contains(dayOff.id) {
            context.delete(dayOff)
        }

        context.saveReportingErrors()
        DemoStore.clear(userID: userID)
    }
}
