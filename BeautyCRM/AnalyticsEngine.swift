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
    let appointmentCount: Int
    let clientCount: Int
    let averageCheck: Decimal
    // Дохід за годину роботи (за тривалістю завершених записів)
    let hourlyIncome: Decimal

    let topServices: [AnalyticsServiceItem]
    let topClients: [AnalyticsClientItem]

    // Стовпчик на кожен день (тиждень, місяць) або місяць (рік), навіть порожній
    let chart: [AnalyticsChartItem]
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
        calendar: Calendar
    ) -> AnalyticsSummary {

        // Лише завершені записи цього майстра в межах періоду
        // (кінець періоду не входить: 00:00 наступного дня — вже інший період)
        let completed = appointments.filter {
            $0.userID == userID
                && $0.status == .completed
                && $0.finalPrice != nil
                && $0.startDate >= interval.start
                && $0.startDate < interval.end
        }

        let revenue = completed.reduce(Decimal(0)) { $0 + ($1.finalPrice ?? 0) }
        let minutes = completed.reduce(0) { $0 + $1.duration }

        return AnalyticsSummary(
            interval: interval,
            revenue: revenue,
            appointmentCount: completed.count,
            clientCount: Set(completed.map(\.clientID)).count,
            averageCheck: completed.isEmpty ? 0 : revenue / Decimal(completed.count),
            // Через хвилини, щоб не втрачати точність на дробових годинах
            hourlyIncome: minutes > 0 ? revenue * 60 / Decimal(minutes) : 0,
            topServices: topServices(completed, serviceNames: serviceNames),
            topClients: topClients(completed, clientNames: clientNames),
            chart: chart(completed, period: period, interval: interval, calendar: calendar)
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
