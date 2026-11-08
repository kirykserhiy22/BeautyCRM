//
//  DayTimelineLayout.swift
//  BeautyCRM
//
//  Розрахунки шкали дня: які години показати і як поставити записи,
//  що накладаються, поруч. Без SwiftUI, щоб перевірити тестами.
//

import Foundation


struct TimelineItem: Equatable {
    let id: UUID
    let startMinute: Int
    let endMinute: Int
}


struct TimelinePlacement: Equatable {
    let column: Int
    let columnCount: Int
}


enum DayTimelineLayout {

    // Коротший запис на шкалі однаково займає стільки хвилин, інакше текст не влізе
    static let minimumVisualMinutes = 30

    static func item(
        id: UUID,
        start: Date,
        durationMinutes: Int,
        calendar: Calendar = .current
    ) -> TimelineItem {
        let parts = calendar.dateComponents([.hour, .minute], from: start)
        let startMinute = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        return TimelineItem(
            id: id,
            startMinute: startMinute,
            endMinute: min(startMinute + durationMinutes, 24 * 60)
        )
    }

    // Від першого запису дня (порожні ранкові години не потрібні) до кінця робочого дня.
    // startsAtFirstItem: false — увесь робочий день, для перенесення записів.
    static func hourRange(
        items: [TimelineItem],
        workStartMinute: Int,
        workEndMinute: Int,
        startsAtFirstItem: Bool = true
    ) -> ClosedRange<Int> {

        let earliest = items.map(\.startMinute).min() ?? workStartMinute
        let first = startsAtFirstItem ? earliest : min(earliest, workStartMinute)
        let last = max(items.map(\.endMinute).max() ?? workEndMinute, workEndMinute)

        let lower = first / 60
        let upper = min(max(Int((Double(last) / 60).rounded(.up)), lower + 1), 24)

        return lower...upper
    }

    // Куди стане запис, якщо його потягнути: крок 15 хвилин, у межах шкали.
    // Ледь зрушений запис лишається на своєму місці, навіть якщо час «некруглий».
    static func snappedStart(
        original: Int,
        dragPoints: CGFloat,
        pointsPerHour: CGFloat,
        duration: Int,
        hours: ClosedRange<Int>,
        step: Int = 15
    ) -> Int {

        let delta = Double(dragPoints / pointsPerHour * 60)

        guard abs(delta) >= Double(step) / 2 else {
            return original
        }

        let snapped = Int(((Double(original) + delta) / Double(step)).rounded()) * step
        let latest = max(hours.upperBound * 60 - duration, hours.lowerBound * 60)

        return min(max(snapped, hours.lowerBound * 60), latest)
    }

    // Запис тягнуть за межу шкали (раніше початку чи пізніше кінця робочого дня)
    static func isBeyondScale(
        original: Int,
        dragPoints: CGFloat,
        pointsPerHour: CGFloat,
        duration: Int,
        hours: ClosedRange<Int>,
        tolerance: Int = 15
    ) -> Bool {

        let start = Double(original) + Double(dragPoints / pointsPerHour * 60)

        return start < Double(hours.lowerBound * 60 - tolerance)
            || start + Double(duration) > Double(hours.upperBound * 60 + tolerance)
    }

    // Записи, що накладаються, стають поруч; решта займає всю ширину
    static func placements(for items: [TimelineItem]) -> [UUID: TimelinePlacement] {

        let sorted = items.sorted {
            ($0.startMinute, $0.endMinute) < ($1.startMinute, $1.endMinute)
        }

        var result: [UUID: TimelinePlacement] = [:]
        var group: [(item: TimelineItem, column: Int)] = []
        var columnEnds: [Int] = []
        var groupEnd = Int.min

        func closeGroup() {
            for entry in group {
                result[entry.item.id] = TimelinePlacement(
                    column: entry.column,
                    columnCount: columnEnds.count
                )
            }
            group = []
            columnEnds = []
        }

        for item in sorted {

            let visualEnd = max(item.endMinute, item.startMinute + minimumVisualMinutes)

            if item.startMinute >= groupEnd {
                closeGroup()
                groupEnd = visualEnd
            }

            if let free = columnEnds.firstIndex(where: { $0 <= item.startMinute }) {
                columnEnds[free] = visualEnd
                group.append((item, free))
            } else {
                columnEnds.append(visualEnd)
                group.append((item, columnEnds.count - 1))
            }

            groupEnd = max(groupEnd, visualEnd)
        }

        closeGroup()

        return result
    }
}
