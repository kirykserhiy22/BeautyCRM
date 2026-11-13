//
//  ReminderPlannerTests.swift
//  BeautyCRMTests
//
//  Розклад нагадувань майстру: що й коли iPhone має показати.
//

import XCTest
@testable import BeautyCRM

final class ReminderPlannerTests: XCTestCase {

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return calendar
    }

    private func date(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
    }

    private func appointment(start: Date, minutes: Int = 60, active: Bool = true) -> ReminderAppointment {
        ReminderAppointment(id: UUID(), start: start, end: start.addingTimeInterval(TimeInterval(minutes * 60)), isActive: active)
    }

    func testUpcomingAndFinishTimes() {
        let item = appointment(start: date(14, 14), minutes: 90)

        let plan = ReminderPlanner.plan(appointments: [item], settings: ReminderSettings(), now: date(14, 9), calendar: calendar)

        XCTAssertEqual(plan.map(\.kind), [.upcoming, .finish])
        XCTAssertEqual(plan[0].fireDate, date(14, 13), "За 1 годину до 14:00")
        XCTAssertEqual(plan[1].fireDate, date(14, 15, 35), "Кінець 15:30 + 5 хвилин")
    }

    func testEveningBeforeIsAt20() {
        var settings = ReminderSettings()
        settings.lead = .eveningBefore

        let plan = ReminderPlanner.plan(appointments: [appointment(start: date(14, 10))], settings: settings, now: date(12, 9), calendar: calendar)

        XCTAssertEqual(plan.first?.fireDate, date(13, 20))
    }

    func testPastTimesAndInactiveAppointmentsAreSkipped() {
        let soon = appointment(start: date(14, 10, 30))            // нагадування о 9:30 уже минуло
        let cancelled = appointment(start: date(14, 16), active: false)

        let plan = ReminderPlanner.plan(appointments: [soon, cancelled], settings: ReminderSettings(), now: date(14, 10), calendar: calendar)

        XCTAssertEqual(plan.count, 1)
        XCTAssertEqual(plan.first?.kind, .finish, "Лишається тільки «Завершіть запис»")
        XCTAssertEqual(plan.first?.appointmentID, soon.id)
    }

    func testSwitchesTurnRemindersOff() {
        let item = appointment(start: date(14, 14))
        let settings = ReminderSettings(beforeEnabled: false, lead: .hour1, finishEnabled: false)

        XCTAssertTrue(ReminderPlanner.plan(appointments: [item], settings: settings, now: date(14, 9), calendar: calendar).isEmpty)
    }

    func testOnlyNearestRemindersFitIPhoneLimit() {
        let many = (0..<50).map { appointment(start: date(14, 9).addingTimeInterval(TimeInterval($0 * 3600 * 24))) }

        let plan = ReminderPlanner.plan(appointments: many.reversed(), settings: ReminderSettings(), now: date(13, 9), calendar: calendar)

        XCTAssertEqual(plan.count, ReminderPlanner.maxPending)
        XCTAssertEqual(plan.first?.appointmentID, many[0].id, "Найближчий запис — першим")
        XCTAssertEqual(plan.map(\.fireDate), plan.map(\.fireDate).sorted())
    }

    func testIdentifiersAreUniqueAndPrefixed() {
        let item = appointment(start: date(14, 14))
        let plan = ReminderPlanner.plan(appointments: [item], settings: ReminderSettings(), now: date(14, 9), calendar: calendar)

        XCTAssertEqual(Set(plan.map(\.identifier)).count, 2)
        XCTAssertTrue(plan.allSatisfy { $0.identifier.hasPrefix(ReminderPlanner.identifierPrefix) })
    }

    func testSettingsLoadDefaultsAndSavedValues() {
        let defaults = UserDefaults(suiteName: "ReminderPlannerTests")!
        defaults.removePersistentDomain(forName: "ReminderPlannerTests")

        XCTAssertEqual(ReminderSettings.load(defaults), ReminderSettings(), "За замовчуванням: увімкнено, за 1 годину")

        defaults.set(false, forKey: ReminderSettings.finishEnabledKey)
        defaults.set("min30", forKey: ReminderSettings.leadKey)

        XCTAssertEqual(ReminderSettings.load(defaults), ReminderSettings(beforeEnabled: true, lead: .min30, finishEnabled: false))
    }
}
