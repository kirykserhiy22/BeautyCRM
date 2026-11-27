//
//  FlexibleScheduleTests.swift
//  BeautyCRMTests
//
//  Вільний графік: години — лише рамка (8:00–20:00 за замовчуванням); старі профілі з годинами — фіксований.
//

import XCTest
@testable import BeautyCRM

@MainActor
final class FlexibleScheduleTests: XCTestCase {

    private func profile() -> UserProfile {
        UserProfile(authUserID: "u", firstName: "A", lastName: "B", currencyCode: "EUR", languageCode: "uk")
    }

    func testNewProfileIsFlexibleWithEightToEightFrame() {
        let hours = DayTimeScale.workingHours(profile())
        XCTAssertTrue(hours.isFlexible)
        XCTAssertEqual(hours.startMinute, 8 * 60)
        XCTAssertEqual(hours.endMinute, 20 * 60)
    }

    func testOldProfileWithHoursStaysFixed() {
        let old = profile()
        old.workStartMinute = 10 * 60
        old.workEndMinute = 18 * 60
        let hours = DayTimeScale.workingHours(old)
        XCTAssertFalse(hours.isFlexible)
        XCTAssertEqual(hours.startMinute, 10 * 60)
    }

    func testFlexibleWithOwnFrame() {
        let flexible = profile()
        flexible.workStartMinute = 7 * 60
        flexible.workEndMinute = 21 * 60
        flexible.flexibleSchedule = true
        let hours = DayTimeScale.workingHours(flexible)
        XCTAssertTrue(hours.isFlexible)
        XCTAssertEqual(hours.endMinute, 21 * 60)
    }
}
