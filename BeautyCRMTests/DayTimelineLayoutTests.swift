//
//  DayTimelineLayoutTests.swift
//  BeautyCRMTests
//

import XCTest
@testable import BeautyCRM

final class DayTimelineLayoutTests: XCTestCase {

    private func item(_ start: Int, _ end: Int) -> TimelineItem {
        TimelineItem(id: UUID(), startMinute: start, endMinute: end)
    }

    private func hours(_ items: [TimelineItem], startsAtFirstItem: Bool = true) -> ClosedRange<Int> {
        DayTimelineLayout.hourRange(
            items: items,
            workStartMinute: 9 * 60,
            workEndMinute: 19 * 60,
            startsAtFirstItem: startsAtFirstItem
        )
    }

    func testEmptyDayShowsWorkingHours() {
        XCTAssertEqual(hours([]), 9...19)
    }

    func testAppointmentsOutsideWorkingHoursExtendTheScale() {
        XCTAssertEqual(hours([item(7 * 60 + 30, 8 * 60 + 30), item(20 * 60, 21 * 60 + 10)]), 7...22)
    }

    func testScaleStartsAtTheHourOfFirstAppointment() {
        XCTAssertEqual(hours([item(13 * 60 + 30, 14 * 60 + 30), item(16 * 60, 17 * 60)]), 13...19)
    }

    func testFullDayKeepsWorkingHoursBeforeFirstAppointment() {
        XCTAssertEqual(hours([item(13 * 60, 14 * 60)], startsAtFirstItem: false), 9...19)
    }

    func testScaleNeverGoesPastMidnight() {
        XCTAssertEqual(hours([item(23 * 60, 24 * 60)]), 23...24)
    }

    func testPartialWorkingHoursRoundOutward() {
        let range = DayTimelineLayout.hourRange(items: [], workStartMinute: 9 * 60 + 30, workEndMinute: 17 * 60 + 15)
        XCTAssertEqual(range, 9...18)
    }

    // MARK: - Перетягування

    private func snapped(_ original: Int, points: CGFloat, duration: Int = 60) -> Int {
        DayTimelineLayout.snappedStart(
            original: original,
            dragPoints: points,
            pointsPerHour: 60,
            duration: duration,
            hours: 9...19
        )
    }

    func testDragSnapsToQuarterHours() {
        XCTAssertEqual(snapped(900, points: 60), 960)
        XCTAssertEqual(snapped(900, points: 20), 915)
        XCTAssertEqual(snapped(900, points: -40), 855)
    }

    func testSmallMovementKeepsOriginalTime() {
        XCTAssertEqual(snapped(907, points: 3), 907)
        XCTAssertEqual(snapped(900, points: -7), 900)
    }

    func testDragStaysInsideTheScale() {
        XCTAssertEqual(snapped(600, points: -600), 540)
        XCTAssertEqual(snapped(1000, points: 600, duration: 90), 19 * 60 - 90)
    }

    func testDraggingPastTheScaleIsDetected() {
        func beyond(_ start: Int, _ points: CGFloat) -> Bool {
            DayTimelineLayout.isBeyondScale(
                original: start, dragPoints: points, pointsPerHour: 60, duration: 60, hours: 9...19
            )
        }

        XCTAssertFalse(beyond(600, -60), "Рівно до 9:00")
        XCTAssertFalse(beyond(600, -70), "Трохи за край — це ще 9:00")
        XCTAssertTrue(beyond(600, -80))
        XCTAssertTrue(beyond(1000, 200))
    }

    func testSeparateAppointmentsTakeFullWidth() {
        let first = item(600, 660), second = item(660, 720)

        let result = DayTimelineLayout.placements(for: [first, second])

        XCTAssertEqual(result[first.id], TimelinePlacement(column: 0, columnCount: 1))
        XCTAssertEqual(result[second.id], TimelinePlacement(column: 0, columnCount: 1))
    }

    func testOverlappingAppointmentsStandSideBySide() {
        let first = item(600, 720), second = item(630, 690)

        let result = DayTimelineLayout.placements(for: [second, first])

        XCTAssertEqual(result[first.id], TimelinePlacement(column: 0, columnCount: 2))
        XCTAssertEqual(result[second.id], TimelinePlacement(column: 1, columnCount: 2))
    }

    func testFreedColumnIsReusedInsideOneGroup() {
        let long = item(600, 780), early = item(600, 660), late = item(660, 720)

        let result = DayTimelineLayout.placements(for: [long, early, late])

        XCTAssertEqual(result[long.id]?.columnCount, 2)
        XCTAssertEqual(result[late.id]?.columnCount, 2)
        XCTAssertEqual(result[early.id]?.column, result[late.id]?.column)
    }

    func testLaterGroupIsNotNarrowedByEarlierOverlap() {
        let first = item(600, 660), second = item(620, 680), later = item(800, 860)

        XCTAssertEqual(
            DayTimelineLayout.placements(for: [first, second, later])[later.id],
            TimelinePlacement(column: 0, columnCount: 1)
        )
    }

    func testShortAppointmentsDoNotCoverEachOther() {
        // По 15 хвилин, але на шкалі кожен займає 30
        let first = item(600, 615), second = item(615, 630)

        XCTAssertEqual(DayTimelineLayout.placements(for: [first, second])[second.id]?.columnCount, 2)
    }
}
