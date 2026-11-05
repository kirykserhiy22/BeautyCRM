//
//  HomeTimingTests.swift
//  BeautyCRMTests
//

import XCTest
@testable import BeautyCRM

final class HomeTimingTests: XCTestCase {

    private typealias F = AuditFixtures

    func testCountdownInMinutesAndHours() {
        let now = F.date(hour: 10)

        XCTAssertEqual(HomeTiming.countdown(from: now, to: F.date(hour: 10, 40)), .minutes(40))
        XCTAssertEqual(HomeTiming.countdown(from: now, to: F.date(hour: 11)), .hours(1, 0))
        XCTAssertEqual(HomeTiming.countdown(from: now, to: F.date(hour: 12, 10)), .hours(2, 10))
    }

    func testCountdownRoundsUpAndNeverShowsZero() {
        let now = F.date(hour: 10)

        XCTAssertEqual(HomeTiming.countdown(from: now, to: now.addingTimeInterval(30)), .minutes(1))
        XCTAssertEqual(HomeTiming.minutes(from: now, to: now), 1)
    }

    func testOtherDayHasNoCountdown() {
        XCTAssertEqual(
            HomeTiming.countdown(from: F.date(hour: 23), to: F.date(2026, 11, 3, 9)),
            .otherDay
        )
    }

    func testGreetingFollowsTimeOfDay() {
        XCTAssertEqual(HomeTiming.greetingKey(hour: 4), "home.greeting.evening")
        XCTAssertEqual(HomeTiming.greetingKey(hour: 5), "home.greeting.morning")
        XCTAssertEqual(HomeTiming.greetingKey(hour: 12), "home.greeting.afternoon")
        XCTAssertEqual(HomeTiming.greetingKey(hour: 18), "home.greeting.evening")
    }
}
