//
//  HomeInsights.swift
//  BeautyCRM
//
//  «Ритм місяця» для Головної: наскільки заповнений кожен день.
//  Робочі години з профілю (напр. 9:00–19:00) — це 100 %, записи — заповнена частина,
//  решта — «тінь» вільного часу. Без SwiftUI — перевіряється тестами.
//

import Foundation


// Один день для «ритму»
struct DayLoad: Equatable, Identifiable {
    let day: Date
    // Зайнято записами, хвилини в межах робочого часу
    let bookedMinutes: Int
    // Робочих хвилин у цей день (0 — вихідний)
    let workingMinutes: Int
    let isDayOff: Bool
    // Скільки записів (заплановані й завершені)
    let appointmentCount: Int
    var id: Date { day }

    var freeMinutes: Int { max(workingMinutes - bookedMinutes, 0) }

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


    // MARK: - MONTH RHYTHM

    // Усі дні місяця, у який потрапляє `month`
    static func monthLoad(
        appointments: [Appointment],
        dayOffKeys: Set<String>,
        workingHours: DayTimeScale,
        month: Date,
        calendar: Calendar = .current
    ) -> [DayLoad] {

        guard let interval = calendar.dateInterval(of: .month, for: month) else {
            return []
        }

        let busy = occupying(appointments)
        let working = max(workingHours.endMinute - workingHours.startMinute, 0)

        var days: [DayLoad] = []
        var day = interval.start

        while day < interval.end {

            guard
                let dayStart = calendar.date(byAdding: .minute, value: workingHours.startMinute, to: day),
                let dayEnd = calendar.date(byAdding: .minute, value: workingHours.endMinute, to: day),
                let next = calendar.date(byAdding: .day, value: 1, to: day)
            else {
                break
            }

            let isDayOff = dayOffKeys.contains(DayOff.key(for: day, calendar: calendar))
            let ofDay = busy.filter { $0.startDate >= day && $0.startDate < next }

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

            days.append(
                DayLoad(
                    day: day,
                    bookedMinutes: Int(booked / 60),
                    workingMinutes: isDayOff ? 0 : working,
                    isDayOff: isDayOff,
                    appointmentCount: ofDay.count
                )
            )
            day = next
        }

        return days
    }

    // Загальна заповненість, 0…100 (вихідні не рахуються)
    static func percent(_ days: [DayLoad]) -> Int {
        let working = days.reduce(0) { $0 + $1.workingMinutes }
        guard working > 0 else { return 0 }
        let booked = days.reduce(0) { $0 + min($1.bookedMinutes, $1.workingMinutes) }
        return Int((Double(booked) * 100 / Double(working)).rounded())
    }
}
