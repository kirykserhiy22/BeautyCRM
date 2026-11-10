//
//  AnalyticsEngine.swift
//  BeautyCRM
//
//  Усі розрахунки екрана «Аналітика» — без SwiftUI, тож їх можна
//  перевірити тестами і пізніше повторити у веб-версії.
//

import Foundation


// Готовий «звіт» за період: AnalyticsView лише показує ці числа
struct AnalyticsSummary {

    let interval: DateInterval

    // Дохід — сума фінальних цін завершених записів
    let revenue: Decimal
    // Скільки ще очікується: заплановані ціни активних записів цього періоду
    let expectedRevenue: Decimal
    let appointmentCount: Int
    let clientCount: Int
    let averageCheck: Decimal
    // Дохід за годину роботи (за тривалістю завершених записів)
    let hourlyIncome: Decimal

    let topServices: [AnalyticsServiceItem]
    let topClients: [AnalyticsClientItem]

    // Стовпчик на кожен день (тиждень, місяць) або місяць (рік), навіть порожній
    let chart: [AnalyticsChartItem]

    // Порівняння з попереднім періодом; nil — порівнювати нема з чим
    let comparison: AnalyticsComparison?

    // Нові — перший завершений візит припав на цей період; решта повернулись
    let newClientCount: Int
    let returningClientCount: Int

    // Послуга, що принесла найбільше грошей за період
    let leadingService: AnalyticsServiceShare?
}


struct AnalyticsComparison: Equatable {

    // Зі знаком: +12 — більше, −12 — менше, 0 — стільки ж
    let percent: Int

    // true — період ще триває, тож порівнюємо з тим самим відрізком попереднього
    let isPartial: Bool
}


struct AnalyticsServiceShare: Equatable {

    let name: String
    let percent: Int
}


enum AnalyticsEngine {

    // MARK: - CALENDAR

    // Тиждень починається з понеділка (ринок — Європа)
    static func calendar(base: Calendar = .current) -> Calendar {
        var calendar = base
        calendar.firstWeekday = 2
        return calendar
    }


    // MARK: - PERIOD

    // Межі періоду: тиждень, у який потрапляє `reference`, вибраний місяць або рік
    static func interval(
        for period: AnalyticsPeriod,
        reference: Date,
        month: Int,
        year: Int,
        calendar: Calendar
    ) -> DateInterval? {

        switch period {

        case .week:
            return calendar.dateInterval(of: .weekOfYear, for: reference)

        case .month:
            guard let date = calendar.date(from: DateComponents(year: year, month: month)) else {
                return nil
            }
            return calendar.dateInterval(of: .month, for: date)

        case .year:
            guard let date = calendar.date(from: DateComponents(year: year)) else {
                return nil
            }
            return calendar.dateInterval(of: .year, for: date)
        }
    }


    // MARK: - SUMMARY

    static func summary(
        appointments: [Appointment],
        userID: String,
        clientNames: [UUID: String],
        serviceNames: [UUID: String],
        period: AnalyticsPeriod,
        interval: DateInterval,
        calendar: Calendar,
        now: Date = Date()
    ) -> AnalyticsSummary {

        let allCompleted = appointments.filter {
            $0.userID == userID
                && $0.status == .completed
                && $0.finalPrice != nil
        }

        // Лише завершені записи цього майстра в межах періоду
        // (кінець періоду не входить: 00:00 наступного дня — вже інший період)
        let completed = allCompleted.filter {
            $0.startDate >= interval.start
                && $0.startDate < interval.end
        }

        let revenue = completed.reduce(Decimal(0)) { $0 + ($1.finalPrice ?? 0) }

        // Активні записи ще не завершені, тож у дохід не входять
        let expectedRevenue = appointments
            .filter {
                $0.userID == userID
                    && $0.status == .active
                    && $0.startDate >= interval.start
                    && $0.startDate < interval.end
            }
            .reduce(Decimal(0)) { $0 + $1.totalPlannedPrice }

        let minutes = completed.reduce(0) { $0 + $1.duration }

        let services = topServices(completed, serviceNames: serviceNames)
        let newClients = newClientCount(allCompleted: allCompleted, completed: completed, interval: interval)
        let clientCount = Set(completed.map(\.clientID)).count

        return AnalyticsSummary(
            interval: interval,
            revenue: revenue,
            expectedRevenue: expectedRevenue,
            appointmentCount: completed.count,
            clientCount: clientCount,
            averageCheck: completed.isEmpty ? 0 : revenue / Decimal(completed.count),
            // Через хвилини, щоб не втрачати точність на дробових годинах
            hourlyIncome: minutes > 0 ? revenue * 60 / Decimal(minutes) : 0,
            topServices: services,
            topClients: topClients(completed, clientNames: clientNames),
            chart: chart(completed, period: period, interval: interval, calendar: calendar),
            comparison: comparison(
                revenue: revenue,
                allCompleted: allCompleted,
                period: period,
                interval: interval,
                now: now,
                calendar: calendar
            ),
            newClientCount: newClients,
            returningClientCount: clientCount - newClients,
            leadingService: leadingService(services)
        )
    }


    // MARK: - COMPARISON

    // Місяць, що ще триває, порівнюємо з тими самими днями попереднього:
    // 10 днів листопада проти всього жовтня завжди виглядали б провалом
    static func comparison(
        revenue: Decimal,
        allCompleted: [Appointment],
        period: AnalyticsPeriod,
        interval: DateInterval,
        now: Date,
        calendar: Calendar
    ) -> AnalyticsComparison? {

        guard revenue > 0 else {
            return nil
        }

        let unit: Calendar.Component

        switch period {
        case .week: unit = .weekOfYear
        case .month: unit = .month
        case .year: unit = .year
        }

        guard let previousStart = calendar.date(byAdding: unit, value: -1, to: interval.start) else {
            return nil
        }

        let isPartial = now >= interval.start && now < interval.end

        var previousEnd = interval.start

        if isPartial, let sameMoment = calendar.date(byAdding: unit, value: -1, to: now) {
            previousEnd = min(sameMoment, interval.start)
        }

        let previous = allCompleted
            .filter { $0.startDate >= previousStart && $0.startDate < previousEnd }
            .reduce(Decimal(0)) { $0 + ($1.finalPrice ?? 0) }

        guard previous > 0 else {
            return nil
        }

        let change = (revenue - previous) * 100 / previous

        return AnalyticsComparison(
            percent: Int(change.doubleValue.rounded()),
            isPartial: isPartial
        )
    }


    // MARK: - NEW CLIENTS

    // Новий — той, чий найперший завершений візит припав на цей період
    static func newClientCount(
        allCompleted: [Appointment],
        completed: [Appointment],
        interval: DateInterval
    ) -> Int {

        var firstVisit: [UUID: Date] = [:]

        for appointment in allCompleted {
            let known = firstVisit[appointment.clientID] ?? appointment.startDate
            firstVisit[appointment.clientID] = min(known, appointment.startDate)
        }

        return Set(completed.map(\.clientID))
            .filter { (firstVisit[$0] ?? interval.start) >= interval.start }
            .count
    }


    // MARK: - SERVICE SHARE

    static func leadingService(_ services: [AnalyticsServiceItem]) -> AnalyticsServiceShare? {

        let total = services.reduce(Decimal(0)) { $0 + $1.revenue }

        guard
            total > 0,
            let leader = services.max(by: { ($0.revenue, $1.name) < ($1.revenue, $0.name) })
        else {
            return nil
        }

        return AnalyticsServiceShare(
            name: leader.name,
            percent: Int((leader.revenue * 100 / total).doubleValue.rounded())
        )
    }


    // MARK: - TOP SERVICES

    // Групуємо за serviceID: перейменована послуга лишається одним рядком.
    // Назва — з прайсу, а якщо послугу видалено — з останнього запису.
    static func topServices(
        _ completed: [Appointment],
        serviceNames: [UUID: String]
    ) -> [AnalyticsServiceItem] {

        var grouped: [UUID: (name: String, revenue: Decimal, count: Int)] = [:]

        for appointment in completed.sorted(by: { $0.startDate < $1.startDate }) {
            for item in appointment.services {
                var entry = grouped[item.serviceID] ?? (item.serviceName, 0, 0)
                entry.name = item.serviceName
                entry.revenue += item.finalPrice ?? item.plannedPrice
                entry.count += 1
                grouped[item.serviceID] = entry
            }
        }

        return grouped
            .map { id, value in
                AnalyticsServiceItem(
                    id: id,
                    name: serviceNames[id] ?? value.name,
                    revenue: value.revenue,
                    count: value.count
                )
            }
            .sorted {
                ($0.count, $0.revenue, $1.name) > ($1.count, $1.revenue, $0.name)
            }
    }


    // MARK: - TOP CLIENTS

    // Групуємо за clientID: однофамільці — різні рядки, перейменований
    // клієнт — один. Ім'я — з картки клієнта, інакше з останнього запису.
    static func topClients(
        _ completed: [Appointment],
        clientNames: [UUID: String]
    ) -> [AnalyticsClientItem] {

        var grouped: [UUID: (name: String, spent: Decimal, visits: Int)] = [:]

        for appointment in completed.sorted(by: { $0.startDate < $1.startDate }) {
            var entry = grouped[appointment.clientID] ?? (appointment.clientName, 0, 0)
            entry.name = appointment.clientName
            entry.spent += appointment.finalPrice ?? 0
            entry.visits += 1
            grouped[appointment.clientID] = entry
        }

        return grouped
            .map { id, value in
                AnalyticsClientItem(
                    id: id,
                    name: clientNames[id] ?? value.name,
                    spent: value.spent,
                    visits: value.visits
                )
            }
            .sorted {
                ($0.visits, $0.spent, $1.name) > ($1.visits, $1.spent, $0.name)
            }
    }


    // MARK: - CHART

    static func chart(
        _ completed: [Appointment],
        period: AnalyticsPeriod,
        interval: DateInterval,
        calendar: Calendar
    ) -> [AnalyticsChartItem] {

        // Один стовпчик = день (тиждень, місяць) або місяць (рік)
        let unit: Calendar.Component = period == .year ? .month : .day

        var buckets: [Date: (revenue: Decimal, count: Int)] = [:]

        for appointment in completed {
            guard let bucket = calendar.dateInterval(of: unit, for: appointment.startDate)?.start else {
                continue
            }
            buckets[bucket, default: (0, 0)].revenue += appointment.finalPrice ?? 0
            buckets[bucket, default: (0, 0)].count += 1
        }

        var items: [AnalyticsChartItem] = []
        var date = interval.start

        while date < interval.end {
            let bucket = buckets[date] ?? (0, 0)
            items.append(AnalyticsChartItem(date: date, revenue: bucket.revenue, count: bucket.count))

            guard let next = calendar.date(byAdding: unit, value: 1, to: date) else {
                break
            }
            date = next
        }

        return items
    }
}
