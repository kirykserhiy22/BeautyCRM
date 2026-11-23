//
//  PostponePlanTests.swift
//  BeautyCRMTests
//
//  «Відкласти записи з … по …»: які записи беремо, які дні стають вихідними.
//

import XCTest
@testable import BeautyCRM

@MainActor
final class PostponePlanTests: XCTestCase {

    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return calendar
    }()

    private func date(_ day: Int, _ hour: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour))!
    }

    private func appointment(_ day: Int, _ hour: Int) -> Appointment {
        Appointment(userID: "u1", clientID: UUID(), clientName: "A", startDate: date(day, hour), duration: 60)
    }

    func testDaysIncludeBothEndsAndAnyOrder() {
        let days = PostponePlan.days(from: date(25, 18), to: date(24, 9), calendar: calendar)
        XCTAssertEqual(days.map { DayOff.key(for: $0, calendar: calendar) }, ["2026-11-24", "2026-11-25"])
    }

    func testDaysAreCapped() {
        let days = PostponePlan.days(from: date(1, 9), to: date(1, 9).addingTimeInterval(400 * 86_400), calendar: calendar)
        XCTAssertEqual(days.count, PostponePlan.maxDays)
    }

    // Лише заплановані в ці дні, які ще не закінчились; від ранніх до пізніх
    func testPicksActiveAppointmentsInRange() {
        let late = appointment(25, 15)
        let early = appointment(24, 10)
        let finishedToday = appointment(24, 8)
        let outside = appointment(26, 10)
        let completed = appointment(25, 9)
        completed.status = .completed

        let picked = PostponePlan.appointments(
            [late, early, finishedToday, outside, completed],
            from: date(24, 0), to: date(25, 0),
            now: date(24, 9),
            calendar: calendar
        )
        XCTAssertEqual(picked.map(\.id), [early.id, late.id])
    }

    func testPostponeMovesToRescheduleQueue() {
        let items = [appointment(24, 10), appointment(25, 11)]
        PostponePlan.postpone(items, now: date(23, 12))
        XCTAssertTrue(items.allSatisfy { $0.status == .cancelled && $0.rescheduleRequestedAt != nil })
    }

    func testNewDaysOffSkipExisting() {
        let days = PostponePlan.days(from: date(24, 0), to: date(26, 0), calendar: calendar)
        let new = PostponePlan.newDaysOff(days: days, existingKeys: ["2026-11-25"], calendar: calendar)
        XCTAssertEqual(new.map { DayOff.key(for: $0, calendar: calendar) }, ["2026-11-24", "2026-11-26"])
    }
}
