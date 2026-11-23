//
//  RescheduleQueueTests.swift
//  BeautyCRMTests
//
//  «Перенести пізніше»: хто потрапляє в список «Чекають перенесення» і коли з нього зникає.
//

import XCTest
import SwiftData
@testable import BeautyCRM

@MainActor
final class RescheduleQueueTests: XCTestCase {

    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let clientA = UUID()
    private let clientB = UUID()

    private func appointment(_ client: UUID, hoursFromNow: Double) -> Appointment {
        Appointment(
            userID: "u1", clientID: client, clientName: "A",
            startDate: now.addingTimeInterval(hoursFromNow * 3600), duration: 60
        )
    }

    func testRescheduleLaterPutsAppointmentInQueue() {
        let later = appointment(clientA, hoursFromNow: 24)
        let plain = appointment(clientA, hoursFromNow: 48)
        let active = appointment(clientA, hoursFromNow: 72)

        AppointmentEngine.cancel(appointment: later, rescheduleLater: true, now: now)
        AppointmentEngine.cancel(appointment: plain)

        XCTAssertEqual(later.status, .cancelled)
        XCTAssertEqual(later.rescheduleRequestedAt, now)
        XCTAssertNil(plain.rescheduleRequestedAt)

        let waiting = RescheduleQueue.waiting([later, plain, active], activeClientIDs: [clientA])
        XCTAssertEqual(waiting.map(\.id), [later.id])
    }

    // Найдавніший скасований — першим; видаленого клієнта не показуємо
    func testQueueOrderAndDeletedClients() {
        let second = appointment(clientA, hoursFromNow: 48)
        let first = appointment(clientA, hoursFromNow: 24)
        let deletedClient = appointment(clientB, hoursFromNow: 12)
        for item in [second, first, deletedClient] {
            AppointmentEngine.cancel(appointment: item, rescheduleLater: true, now: now)
        }

        let waiting = RescheduleQueue.waiting([second, first, deletedClient], activeClientIDs: [clientA])
        XCTAssertEqual(waiting.map(\.id), [first.id, second.id])
    }

    // Відновили, приховали, переписали або прибрали — зі списку зникає
    func testQueueClearsOnRestoreArchiveAndFinish() {
        let restored = appointment(clientA, hoursFromNow: 24)
        let archived = appointment(clientA, hoursFromNow: 48)
        let rebooked = appointment(clientA, hoursFromNow: 72)
        for item in [restored, archived, rebooked] {
            AppointmentEngine.cancel(appointment: item, rescheduleLater: true, now: now)
        }

        AppointmentEngine.restore(appointment: restored, existingAppointments: [])
        AppointmentEngine.archive(appointment: archived)
        AppointmentEngine.finishReschedule(appointment: rebooked)

        XCTAssertEqual(restored.status, .active)
        XCTAssertTrue(RescheduleQueue.waiting([restored, archived, rebooked], activeClientIDs: [clientA]).isEmpty)
    }
}
