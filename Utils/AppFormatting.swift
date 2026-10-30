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
        // Називний відмінок: «жовтень», а не «жовтня»
        return formatter.standaloneMonthSymbols
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

    // MARK: - Money

    // Ціна з поля вводу. Повертає nil, якщо це не сума — тоді поле
    // підсвічується, а не перетворюється мовчки на 0.
    //   "12,5", "12.50"        → 12,50   (кома або крапка — копійки)
    //   "1 200", "1.200"       → 1200    (3 цифри після роздільника — тисячі)
    //   "1.234,50", "1,234.50" → 1234,50 (останній роздільник — копійки)
    //   "12abc", "12.5.3", "-5", "" → nil
    static func parseMoney(_ text: String) -> Decimal? {
        let compact = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .filter { !$0.isWhitespace }

        guard
            !compact.isEmpty,
            compact.allSatisfy({ $0.isASCII && ($0.isNumber || $0 == "." || $0 == ",") })
        else {
            return nil
        }

        // Позиція останнього роздільника і що після нього
        let separators: Set<Character> = [".", ","]
        var integerPart = compact
        var fraction = ""

        if let last = compact.lastIndex(where: { separators.contains($0) }) {

            let after = String(compact[compact.index(after: last)...])
            let before = String(compact[..<last])
            let separatorKinds = Set(compact.filter { separators.contains($0) })

            if separatorKinds.count == 2 || (after.count <= 2 && !before.contains(compact[last])) {
                // Останній роздільник — копійки ("1.234,50", "12,5")
                guard after.count <= 2 else {
                    return nil
                }
                integerPart = before
                fraction = after
            } else {
                // Лише тисячі ("1.200", "1.234.567")
                integerPart = compact
            }
        }

        // Що лишилось у цілій частині — тільки групи тисяч по 3 цифри
        let groups = integerPart.split(
            omittingEmptySubsequences: false,
            whereSeparator: { separators.contains($0) }
        )

        guard
            let first = groups.first,
            groups.dropFirst().allSatisfy({ $0.count == 3 }),
            !(first.isEmpty && groups.count > 1)
        else {
            return nil
        }

        let digits = groups.joined()
        let normalized = (digits.isEmpty ? "0" : digits) + (fraction.isEmpty ? "" : "." + fraction)

        return Decimal(
            string: normalized,
            locale: Locale(identifier: "en_US_POSIX")
        )
    }

    // Ціна для підстановки в поле вводу (без символу валюти)
    static func moneyInput(_ value: Decimal) -> String {
        NSDecimalNumber(decimal: value).stringValue
    }
}


extension Decimal {

    // Тільки для показу (графіки), не для розрахунків
    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }
}
