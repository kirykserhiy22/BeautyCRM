//
//  MonthRhythmTests.swift
//  BeautyCRMTests
//
//  «Ритм місяця»: робочий день = 100 %, записи — зайнята частина, вихідні окремо.
//

import XCTest
@testable import BeautyCRM

@MainActor
final class MonthRhythmTests: XCTestCase {

    private typealias F = AuditFixtures

    private let hours = DayTimeScale(startMinute: 9 * 60, endMinute: 19 * 60)

    private func appointment(_ start: Date, minutes: Int, status: AppointmentStatus = .active) -> Appointment {
        F.appointment(start: start, minutes: minutes, status: status)
    }

    func testDaysOfMonthWithBookedTimeInsideWorkingHours() {
        let calendar = Calendar.current
        let appointments = [
            appointment(F.date(2026, 11, 5, 10), minutes: 90),
            appointment(F.date(2026, 11, 5, 11), minutes: 60, status: .completed),   // накладка — не двічі
            appointment(F.date(2026, 11, 5, 18), minutes: 120),                       // до 19:00 лише година
            appointment(F.date(2026, 11, 6, 10), minutes: 60, status: .cancelled),    // не займає часу
            appointment(F.date(2026, 11, 6, 12), minutes: 60, status: .archived)
        ]
        let days = HomeInsights.monthLoad(
            appointments: appointments,
            dayOffKeys: [DayOff.key(for: F.date(2026, 11, 8, 12))],
            workingHours: hours,
            month: F.date(2026, 11, 15, 12),
            calendar: calendar
        )

        XCTAssertEqual(days.count, 30)
        let fifth = days[4]
        XCTAssertEqual(fifth.bookedMinutes, 180, "10:00–12:00 (накладка рахується раз) + 18:00–19:00")
        XCTAssertEqual(fifth.workingMinutes, 600)
        XCTAssertEqual(fifth.freeMinutes, 420)
        XCTAssertEqual(fifth.appointmentCount, 3)
        XCTAssertEqual(days[5].bookedMinutes, 0, "Скасовані й приховані не займають часу")
        XCTAssertTrue(days[7].isDayOff)
        XCTAssertEqual(days[7].workingMinutes, 0)
    }

    func testPercentIgnoresDaysOff() {
        let days = [
            DayLoad(day: F.date(2026, 11, 1, 0), bookedMinutes: 300, workingMinutes: 600, isDayOff: false, appointmentCount: 3),
            DayLoad(day: F.date(2026, 11, 2, 0), bookedMinutes: 0, workingMinutes: 0, isDayOff: true, appointmentCount: 0),
            DayLoad(day: F.date(2026, 11, 3, 0), bookedMinutes: 900, workingMinutes: 600, isDayOff: false, appointmentCount: 5)
        ]
        XCTAssertEqual(HomeInsights.percent(days), 75, "(300 + 600) / 1200; понад робочий день — не більше 100 %")
        XCTAssertEqual(days[2].share, 1)
        XCTAssertEqual(HomeInsights.percent([]), 0)
    }
}
