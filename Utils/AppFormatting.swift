//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 21.10.26.
//


import Foundation

enum AppFormatting {

    // MARK: - Date and time

    static func date(
        _ value: Date,
        locale: Locale,
        format: DateFormatter.Style = .long
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateStyle = format
        formatter.timeStyle = .none
        return formatter.string(from: value)
    }

    static func dateTime(
        _ value: Date,
        locale: Locale
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: value)
    }

    static func time(
        _ value: Date,
        locale: Locale
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: value)
    }

    // MARK: - Home header

    static func homeDate(
        _ value: Date,
        locale: Locale
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter.string(from: value)
    }

    // MARK: - Standalone month names

    static func monthNames(locale: Locale) -> [String] {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = Calendar(identifier: .gregorian)
        return formatter.monthSymbols
    }

    // MARK: - Weekday names, Monday first

    static func weekdayNames(
        locale: Locale,
        width: WeekdayWidth = .abbreviated
    ) -> [String] {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = Calendar(identifier: .gregorian)

        let symbols: [String]

        switch width {
        case .wide:
            symbols = formatter.weekdaySymbols
        case .abbreviated:
            symbols = formatter.shortWeekdaySymbols
        case .veryShort:
            symbols = formatter.veryShortWeekdaySymbols
        }

        // DateFormatter weekday symbols start with Sunday.
        // Reorder to Monday through Sunday.
        return Array(symbols.dropFirst()) + [symbols[0]]
    }

    enum WeekdayWidth {
        case wide
        case abbreviated
        case veryShort
    }
}
