//
//  SyncTrackingTests.swift
//  BeautyCRMTests
//

import XCTest
import SwiftData
@testable import BeautyCRM

final class SyncTrackingTests: XCTestCase {

    private var context: ModelContext!

    override func setUpWithError() throws {
        let container = try ModelContainer(
            for: UserProfile.self, Client.self, Appointment.self, Service.self, DayOff.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
        SyncTracking.start()
        SyncTracking.currentWorkspaceID = nil
    }

    func testSaveStampsUpdatedAtAndWorkspace() throws {
        let workspaceID = UUID()
        SyncTracking.currentWorkspaceID = workspaceID

        let client = Client(userID: "user-1", name: "Anna")
        context.insert(client)
        try context.save()

        XCTAssertEqual(client.workspaceID, workspaceID)
        let firstUpdate = try XCTUnwrap(client.updatedAt)

        client.name = "Anna K."
        try context.save()

        XCTAssertGreaterThan(try XCTUnwrap(client.updatedAt), firstUpdate)
        XCTAssertNil(client.deletedAt)
    }

    func testPrepareWorkspaceFillsOldRecords() throws {
        let profile = UserProfile(
            authUserID: "user-1",
            firstName: "Olena",
            lastName: "K",
            currencyCode: "EUR",
            languageCode: "uk"
        )
        profile.workspaceID = nil
        context.insert(profile)

        let ownService = Service(userID: "user-1", name: "Cut", pricingType: .fixed, price: 20)
        let otherService = Service(userID: "user-2", name: "Color", pricingType: .fixed, price: 50)
        context.insert(ownService)
        context.insert(otherService)
        try context.save()

        SyncTracking.prepareWorkspace(context: context, userID: "user-1")

        let workspaceID = try XCTUnwrap(profile.workspaceID)
        XCTAssertEqual(SyncTracking.currentWorkspaceID, workspaceID)
        XCTAssertEqual(ownService.workspaceID, workspaceID)
        XCTAssertNotEqual(otherService.workspaceID, workspaceID)
    }
}
