//
//  HomeInsights.swift
//  BeautyCRM
//
//  «Ритм» для Головної: наскільки заповнений кожен день (робочі години = 100 %).
//  ЧЕРНЕТКА: зараз рахує тиждень; наступна сесія розширює на місяць і малює віджет
//  (завдання — BACKLOG.md, «Найближча черга»). Без SwiftUI — перевіряється тестами.
//

import Foundation


// Один день тижня для «ритму»
struct WeekDayLoad: Equatable, Identifiable {
    let day: Date
    // Зайнято записами, хвилини в межах робочого часу
    let bookedMinutes: Int
    // Робочих хвилин у цей день (0 — вихідний)
    let workingMinutes: Int
    let isDayOff: Bool
    var id: Date { day }

    // 0…1
    var share: Double {
        workingMinutes == 0 ? 0 : min(Double(bookedMinutes) / Double(workingMinutes), 1)
    }
}


enum HomeInsights {

    // Записи, що займають час: заплановані й завершені (скасовані та приховані — ні)
    private static func occupying(_ appointments: [Appointment]) -> [Appointment] {
        appointments
            .filter { $0.status == .active || $0.status == .completed }
            .sorted { $0.startDate < $1.startDate }
    }


    // MARK: - WEEK RHYTHM

    // Сім днів тижня (з понеділка), у який потрапляє `now`
    static func weekLoad(
        appointments: [Appointment],
        dayOffKeys: Set<String>,
        workingHours: DayTimeScale,
        now: Date = Date(),
        calendar: Calendar = AnalyticsEngine.calendar()
    ) -> [WeekDayLoad] {

        guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else {
            return []
        }

        let busy = occupying(appointments)
        let working = max(workingHours.endMinute - workingHours.startMinute, 0)

        return (0..<7).compactMap { offset in

            guard
                let day = calendar.date(byAdding: .day, value: offset, to: week.start),
                let dayStart = calendar.date(byAdding: .minute, value: workingHours.startMinute, to: day),
                let dayEnd = calendar.date(byAdding: .minute, value: workingHours.endMinute, to: day)
            else {
                return nil
            }

            let isDayOff = dayOffKeys.contains(DayOff.key(for: day, calendar: calendar))

            // Лише частина запису в робочих годинах; накладки не рахуємо двічі
            var booked: TimeInterval = 0
            var cursor = dayStart
            for appointment in busy where appointment.endDate > cursor && appointment.startDate < dayEnd {
                let start = max(appointment.startDate, cursor)
                let end = min(appointment.endDate, dayEnd)
                if end > start {
                    booked += end.timeIntervalSince(start)
                    cursor = end
                }
            }

            return WeekDayLoad(
                day: day,
                bookedMinutes: Int(booked / 60),
                workingMinutes: isDayOff ? 0 : working,
                isDayOff: isDayOff
            )
        }
    }

    // Загальна заповненість тижня, 0…100 (вихідні не рахуються)
    static func weekPercent(_ days: [WeekDayLoad]) -> Int {
        let working = days.reduce(0) { $0 + $1.workingMinutes }
        guard working > 0 else { return 0 }
        let booked = days.filter { !$0.isDayOff }.reduce(0) { $0 + min($1.bookedMinutes, $1.workingMinutes) }
        return Int((Double(booked) * 100 / Double(working)).rounded())
    }

    // Найвільніший робочий день, що ще попереду (разом із сьогодні)
    static func quietestUpcoming(_ days: [WeekDayLoad], now: Date = Date(), calendar: Calendar = .current) -> WeekDayLoad? {
        let today = calendar.startOfDay(for: now)
        return days
            .filter { !$0.isDayOff && $0.day >= today }
            .min { ($0.share, $0.day) < ($1.share, $1.day) }
    }
}
