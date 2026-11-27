//
//  AnalyticsInsights.swift
//  BeautyCRM
//
//  Друга половина аналітики:
//  - частки доходу за послугами для кругової діаграми (дрібні — у «Інші»);
//  - клієнтська база загалом: не залежить від вибраного періоду і не обнуляється 1 січня.
//  Без SwiftUI — перевіряється тестами.
//

import Foundation


// Один сегмент кругової діаграми
struct AnalyticsServiceSlice: Identifiable, Equatable {

    // serviceID або "other" для «Інші»
    let id: String
    let name: String
    let revenue: Decimal
    // Частка від 0 до 1
    let share: Double
    let count: Int
    let isOther: Bool
}


// Клієнтська база загалом
struct AnalyticsClientBase: Equatable {

    // Усі клієнти в базі
    let total: Int
    // З'явились цього календарного місяця (додали в базу або вперше прийшли)
    let newThisMonth: Int
    // Приходили хоч раз
    let visited: Int
    // Приходили двічі й більше
    let returning: Int
    // Останній візит понад `dormantDays` днів тому і нового запису немає
    let dormant: Int
    // Найпостійніші за весь час
    let loyal: [AnalyticsClientItem]

    // Яка частка тих, хто приходив, повернулась ще раз
    var returningPercent: Int {
        visited == 0 ? 0 : Int((Double(returning) * 100 / Double(visited)).rounded())
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.total == rhs.total && lhs.newThisMonth == rhs.newThisMonth && lhs.visited == rhs.visited
            && lhs.returning == rhs.returning && lhs.dormant == rhs.dormant
            && lhs.loyal.map(\.id) == rhs.loyal.map(\.id)
    }
}


enum AnalyticsInsights {

    // MARK: - SERVICE SLICES

    // Сегменти за доходом, від більшого. Послуги з часткою менше `otherBelow` збираються в «Інші»,
    // але щонайменше `minimumNamed` найбільших завжди з назвою, а одна дрібна лишається з назвою
    // (ховати одну послугу під «Інші» немає сенсу).
    static func serviceSlices(
        _ services: [AnalyticsServiceItem],
        otherBelow: Double = 0.10,
        minimumNamed: Int = 3
    ) -> [AnalyticsServiceSlice] {

        let paid = services
            .filter { $0.revenue > 0 }
            .sorted { ($0.revenue, $1.name) > ($1.revenue, $0.name) }

        let total = paid.reduce(Decimal(0)) { $0 + $1.revenue }

        guard total > 0 else {
            return []
        }

        func share(_ value: Decimal) -> Double {
            (value / total).doubleValue
        }

        var named: [AnalyticsServiceItem] = []
        var small: [AnalyticsServiceItem] = []

        for (index, item) in paid.enumerated() {
            if index < minimumNamed || share(item.revenue) >= otherBelow {
                named.append(item)
            } else {
                small.append(item)
            }
        }

        if small.count == 1 {
            named += small
            small = []
        }

        var slices = named.map {
            AnalyticsServiceSlice(
                id: $0.id.uuidString,
                name: $0.name,
                revenue: $0.revenue,
                share: share($0.revenue),
                count: $0.count,
                isOther: false
            )
        }

        if !small.isEmpty {
            let revenue = small.reduce(Decimal(0)) { $0 + $1.revenue }
            slices.append(
                AnalyticsServiceSlice(
                    id: "other",
                    name: "",
                    revenue: revenue,
                    share: share(revenue),
                    count: small.reduce(0) { $0 + $1.count },
                    isOther: true
                )
            )
        }

        return slices
    }


    // MARK: - CLIENT BASE

    static func clientBase(
        clients: [Client],
        appointments: [Appointment],
        now: Date = Date(),
        calendar: Calendar = .current,
        dormantDays: Int = 90
    ) -> AnalyticsClientBase {

        let clientIDs = Set(clients.map(\.id))

        let completed = appointments.filter {
            $0.status == .completed && clientIDs.contains($0.clientID)
        }

        let visitsByClient = Dictionary(grouping: completed, by: \.clientID)

        // Новий цього місяця: раніша з дат «додали в базу» і «перший візит» — у цьому місяці
        let month = calendar.dateInterval(of: .month, for: now)
        let newThisMonth = clients.filter { client in
            let firstVisit = visitsByClient[client.id]?.map(\.startDate).min()
            let since = min(client.createdAt, firstVisit ?? client.createdAt)
            return month?.contains(since) ?? false
        }.count

        let visited = visitsByClient.count
        let returning = visitsByClient.values.filter { $0.count >= 2 }.count

        // Давно не були: останній візит давно і нічого не заплановано наперед
        let upcoming = Set(
            appointments
                .filter { $0.status == .active && $0.startDate >= now }
                .map(\.clientID)
        )
        let border = calendar.date(byAdding: .day, value: -dormantDays, to: now) ?? now
        let dormant = visitsByClient.filter { clientID, visits in
            guard !upcoming.contains(clientID), let last = visits.map(\.startDate).max() else {
                return false
            }
            return last < border
        }.count

        let names = Dictionary(clients.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
        let loyal = AnalyticsEngine.topClients(completed, clientNames: names)
            .filter { $0.visits >= 2 }
            .prefix(3)

        return AnalyticsClientBase(
            total: clients.count,
            newThisMonth: newThisMonth,
            visited: visited,
            returning: returning,
            dormant: dormant,
            loyal: Array(loyal)
        )
    }
}
