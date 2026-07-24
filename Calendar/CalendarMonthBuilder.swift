//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 14.05.26.
//

import Foundation

struct CalendarMonthBuilder {

    static func buildMonth(for date: Date) -> [Date?] {

        let calendar = Calendar.current

        guard
            let monthInterval = calendar.dateInterval(of: .month, for: date),
            let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday
        else {
            return []
        }

        // Monday = first day
        let startOffset = (firstWeekday + 5) % 7

        let numberOfDays =
            calendar.range(of: .day, in: .month, for: date)?.count ?? 0

        var result: [Date?] = []

        // Empty cells before the first day
        for _ in 0..<startOffset {
            result.append(nil)
        }

        // Days of month
        for day in 1...numberOfDays {

            if let currentDate = calendar.date(
                byAdding: .day,
                value: day - 1,
                to: monthInterval.start
            ) {
                result.append(currentDate)
            }
        }

        // ALWAYS return exactly 42 cells (6 weeks)
        while result.count < 42 {
            result.append(nil)
        }

        return result
    }
}
