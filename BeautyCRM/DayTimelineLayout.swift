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

    // Робочі години, розширені до цілих годин і до записів поза ними
    static func hourRange(
        items: [TimelineItem],
        workStartMinute: Int,
        workEndMinute: Int
    ) -> ClosedRange<Int> {

        let first = min(items.map(\.startMinute).min() ?? workStartMinute, workStartMinute)
        let last = max(items.map(\.endMinute).max() ?? workEndMinute, workEndMinute)

        let lower = first / 60
        let upper = min(max(Int((Double(last) / 60).rounded(.up)), lower + 1), 24)

        return lower...upper
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
