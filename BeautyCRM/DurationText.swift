//
//  DurationText.swift
//  BeautyCRM
//
//  Тривалість по-людськи: «45 хв», «1 год», «1 год 15 хв» замість «75 хв».
//

import Foundation


nonisolated enum DurationText {

    enum Parts: Equatable {
        case minutes(Int)
        case hours(Int)
        case hoursMinutes(Int, Int)
    }

    static func parts(_ totalMinutes: Int) -> Parts {
        let total = max(totalMinutes, 0)
        let hours = total / 60
        let minutes = total % 60
        if hours == 0 { return .minutes(minutes) }
        return minutes == 0 ? .hours(hours) : .hoursMinutes(hours, minutes)
    }

    // localized — функція, що повертає рядок за ключем (LocalizationManager)
    static func text(_ totalMinutes: Int, locale: Locale, localized: (String) -> String) -> String {
        switch parts(totalMinutes) {
        case .minutes(let m):
            return String(format: localized("duration.minutes"), locale: locale, m)
        case .hours(let h):
            return String(format: localized("duration.hours"), locale: locale, h)
        case .hoursMinutes(let h, let m):
            return String(format: localized("duration.hoursMinutes"), locale: locale, h, m)
        }
    }
}
