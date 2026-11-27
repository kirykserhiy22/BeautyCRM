//
//  TimelineFreeGapsTests.swift
//  BeautyCRMTests
//
//  Шкала дня стискає порожні проміжки від 2 годин у рядок «Вільно 10:00–18:00».
//

import XCTest
@testable import BeautyCRM

final class TimelineFreeGapsTests: XCTestCase {

    private func item(_ start: Int, _ end: Int) -> TimelineItem {
        TimelineItem(id: UUID(), startMinute: start, endMinute: end)
    }

    func testLongEmptyMiddleAndEveningAreGaps() {
        // 9:00–10:00 і 18:00–20:00, робочий день до 20:00
        let items = [item(9 * 60, 10 * 60), item(18 * 60, 20 * 60)]
        XCTAssertEqual(DayTimelineLayout.freeGaps(items: items, hours: 9...20), [10..<18])

        // Після останнього запису о 15:00 — вільно до кінця дня
        XCTAssertEqual(DayTimelineLayout.freeGaps(items: [item(10 * 60, 15 * 60)], hours: 10...20), [15..<20])
    }

    func testShortGapsStayAndPartialHoursAreBusy() {
        // Перерва 11:00–12:30 — лише одна повністю вільна година, не стискаємо
        let items = [item(10 * 60, 11 * 60), item(12 * 60 + 30, 13 * 60)]
        XCTAssertEqual(DayTimelineLayout.freeGaps(items: items, hours: 10...13), [])
    }

    func testOffsetCompressesGap() {
        let gaps = [10..<18]
        func y(_ minute: Int) -> CGFloat {
            DayTimelineLayout.offset(minute: minute, lowerHour: 9, gaps: gaps, hourHeight: 60, gapHeight: 44)
        }
        XCTAssertEqual(y(9 * 60), 0)
        XCTAssertEqual(y(10 * 60), 60)
        XCTAssertEqual(y(18 * 60), 104, "8 порожніх годин — 44 пункти")
        XCTAssertEqual(y(19 * 60), 164)
        XCTAssertEqual(y(14 * 60), 82, "Посередині проміжку — посередині рядка")
        XCTAssertEqual(DayTimelineLayout.offset(minute: 14 * 60, lowerHour: 9, gaps: [], hourHeight: 60, gapHeight: 44), 300)
    }
}
