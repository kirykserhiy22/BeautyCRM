//
//  DemoDataTests.swift
//  BeautyCRMTests
//
//  Демо під кожну спеціалізацію; «Почати роботу» видаляє лише демо, справжні дані лишаються.
//

import XCTest
import SwiftData
@testable import BeautyCRM

@MainActor
final class DemoDataTests: XCTestCase {

    private func context() throws -> ModelContext {
        let container = try ModelContainer(
            for: UserProfile.self, Client.self, ClientPhoto.self, Appointment.self, AppointmentServiceItem.self, Service.self, DayOff.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    override func tearDown() {
        DemoStore.clear(userID: "demo-test")
        super.tearDown()
    }

    func testEachProfessionHasItsOwnServices() {
        let hair = Set(DemoContent.forProfession(.hairStylist).services.map(\.name))
        let nails = Set(DemoContent.forProfession(.nailArtist).services.map(\.name))
        let lash = Set(DemoContent.forProfession(.lashBrowArtist).services.map(\.name))
        XCTAssertTrue(hair.isDisjoint(with: nails))
        XCTAssertTrue(nails.isDisjoint(with: lash))
        XCTAssertTrue(hair.isDisjoint(with: lash))
    }

    func testLoadAndClearKeepsRealData() throws {
        let context = try context()
        let real = Client(userID: "demo-test", name: "Справжня клієнтка")
        context.insert(real)
        try context.save()

        let snapshot = DemoData.load(userID: "demo-test", profession: .nailArtist, context: context)
        XCTAssertTrue(DemoStore.isActive(userID: "demo-test"))
        XCTAssertEqual(snapshot.clients.count, 8)
        XCTAssertGreaterThan(snapshot.appointments.count, 20)

        let appointments = try context.fetch(FetchDescriptor<Appointment>())
        XCTAssertTrue(appointments.contains { $0.status == .completed })
        XCTAssertTrue(appointments.contains { $0.status == .active && $0.startDate > Date() })

        DemoData.clear(userID: "demo-test", context: context)

        XCTAssertFalse(DemoStore.isActive(userID: "demo-test"))
        XCTAssertEqual(try context.fetch(FetchDescriptor<Client>()).map(\.name), ["Справжня клієнтка"])
        XCTAssertTrue(try context.fetch(FetchDescriptor<Appointment>()).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<Service>()).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<DayOff>()).isEmpty)
    }
}
