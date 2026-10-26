//
//  DayTimeScaleTests.swift
//  BeautyCRMTests
//

import XCTest
@testable import BeautyCRM

final class DayTimeScaleTests: XCTestCase {

    private let calendar = Calendar.current

    private func appointment(day: Int, hour: Int, minute: Int = 0, duration: Int) -> Appointment {
        let date = calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
        return Appointment(userID: "u", clientID: UUID(), clientName: "A", startDate: date, duration: duration)
    }

    private var october: Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 15))!
    }

    func testUsesWorkingHoursWhenAllAppointmentsFit() {
        let scale = DayTimeScale.forMonth(
            october,
            appointments: [appointment(day: 3, hour: 10, duration: 60)],
            workingHours: .defaultWorkingHours
        )
        XCTAssertEqual(scale, .defaultWorkingHours)
    }

    func testEarlyAndLateAppointmentsAddEdgeZonesButKeepWorkingHours() {
        let scale = DayTimeScale.forMonth(
            october,
            appointments: [
                appointment(day: 3, hour: 1, duration: 60),
                appointment(day: 9, hour: 19, minute: 30, duration: 45)
            ],
            workingHours: .defaultWorkingHours
        )
        XCTAssertEqual(scale.startMinute, 9 * 60)
        XCTAssertEqual(scale.endMinute, 19 * 60)
        XCTAssertTrue(scale.showsEarlyZone)
        XCTAssertTrue(scale.showsLateZone)
    }

    func testStartOfWorkingDayIsAlwaysAtStartOfMainPart() {
        var scale = DayTimeScale(startMinute: 8 * 60, endMinute: 20 * 60)
        XCTAssertEqual(scale.progress(atMinute: 8 * 60), 0)
        XCTAssertEqual(scale.progress(atMinute: 14 * 60), 0.5, accuracy: 0.001)

        scale.showsEarlyZone = true
        scale.showsLateZone = true
        XCTAssertEqual(scale.progress(atMinute: 8 * 60), DayTimeScale.edgeZoneShare, accuracy: 0.001)
        XCTAssertEqual(scale.progress(atMinute: 0), 0)
        XCTAssertEqual(scale.progress(atMinute: 24 * 60), 1, accuracy: 0.001)
        XCTAssertLessThan(scale.progress(atMinute: 60), DayTimeScale.edgeZoneShare)
    }

    func testIgnoresCancelledAndOtherMonths() {
        let cancelled = appointment(day: 3, hour: 5, duration: 60)
        cancelled.status = .cancelled
        let otherMonth = Appointment(
            userID: "u", clientID: UUID(), clientName: "A",
            startDate: calendar.date(from: DateComponents(year: 2026, month: 11, day: 2, hour: 5))!,
            duration: 60
        )
        let scale = DayTimeScale.forMonth(
            october,
            appointments: [cancelled, otherMonth],
            workingHours: .defaultWorkingHours
        )
        XCTAssertEqual(scale, .defaultWorkingHours)
    }
}
