//
//  HomeTiming.swift
//  BeautyCRM
//
//  Розрахунки часу для Головної: привітання і «через 40 хв». Без SwiftUI, щоб перевірити тестами.
//

import Foundation


enum HomeTiming {

    enum Countdown: Equatable {
        case minutes(Int)
        case hours(Int, Int)
        // Запис не сьогодні: замість відліку показуємо дату
        case otherDay
    }

    // Округлення вгору: за 30 секунд до запису лишається «1 хв», а не «0 хв»
    static func minutes(from start: Date, to end: Date) -> Int {
        max(Int((end.timeIntervalSince(start) / 60).rounded(.up)), 1)
    }

    static func countdown(from now: Date, to start: Date, calendar: Calendar = .current) -> Countdown {

        guard calendar.isDate(now, inSameDayAs: start) else {
            return .otherDay
        }

        let total = minutes(from: now, to: start)

        return total < 60 ? .minutes(total) : .hours(total / 60, total % 60)
    }

    static func greetingKey(hour: Int) -> String {
        switch hour {
        case 5..<12: return "home.greeting.morning"
        case 12..<18: return "home.greeting.afternoon"
        default: return "home.greeting.evening"
        }
    }
}
