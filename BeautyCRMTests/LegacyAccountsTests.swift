//
//  LegacyAccountsTests.swift
//  BeautyCRMTests
//
//  Старі локальні акаунти: паролі прибираються, дані переходять до серверного акаунта з тим самим email.
//

import XCTest
import SwiftData
@testable import BeautyCRM

@MainActor
final class LegacyAccountsTests: XCTestCase {

    private var defaults: UserDefaults!
    private var context: ModelContext!

    override func setUpWithError() throws {
        defaults = try XCTUnwrap(UserDefaults(suiteName: "LegacyAccountsTests"))
        defaults.removePersistentDomain(forName: "LegacyAccountsTests")
        context = try AuditFixtures.makeContext()
    }

    private func saveCredentials(_ users: [AuthCredentials]) throws {
        defaults.set(try JSONEncoder().encode(users), forKey: LegacyAccounts.credentialsKey)
    }

    func testPasswordsAreRemovedButAccountIsRemembered() throws {
        try saveCredentials([AuthCredentials(email: "maria@studio.com", password: "secret-pass-1", userID: "old-1")])

        LegacyAccounts.stripPasswords(defaults: defaults)

        XCTAssertNil(defaults.data(forKey: LegacyAccounts.credentialsKey), "паролів більше немає")
        XCTAssertEqual(LegacyAccounts.userID(forEmail: " Maria@Studio.com", defaults: defaults), "old-1")
    }

    // Нового профілю ще немає: старий профіль стає серверним разом із робочим простором і даними
    func testOldProfileAndDataMoveToServerAccount() throws {
        try saveCredentials([AuthCredentials(email: "maria@studio.com", password: "x", userID: "old-1")])
        LegacyAccounts.stripPasswords(defaults: defaults)

        let profile = UserProfile(authUserID: "old-1", firstName: "Марія", lastName: "К", currencyCode: "EUR", languageCode: "uk")
        let client = Client(userID: "old-1", name: "Олена")
        let service = Service(userID: "old-1", name: "Стрижка", pricingType: .fixed, price: 40)
        context.insert(profile)
        context.insert(client)
        context.insert(service)
        let appointment = Appointment(userID: "old-1", clientID: client.id, clientName: "Олена", startDate: Date(), duration: 60)
        context.insert(appointment)
        context.insert(DayOff(userID: "old-1", date: Date()))
        try context.save()

        XCTAssertTrue(LegacyAccounts.migrate(email: "maria@studio.com", to: "SERVER-1", context: context, defaults: defaults))

        XCTAssertEqual(profile.authUserID, "SERVER-1")
        XCTAssertEqual(client.userID, "SERVER-1")
        XCTAssertEqual(service.userID, "SERVER-1")
        XCTAssertEqual(appointment.userID, "SERVER-1")
        XCTAssertEqual(try context.fetch(FetchDescriptor<DayOff>()).first?.userID, "SERVER-1")
        XCTAssertEqual(client.workspaceID, profile.workspaceID)
        XCTAssertNil(LegacyAccounts.userID(forEmail: "maria@studio.com", defaults: defaults), "переносимо один раз")
    }

    // Серверний профіль уже є: дані переходять у його робочий простір, старий профіль — видалений
    func testDataJoinsExistingServerProfile() throws {
        try saveCredentials([AuthCredentials(email: "maria@studio.com", password: "x", userID: "old-1")])
        LegacyAccounts.stripPasswords(defaults: defaults)

        let oldProfile = UserProfile(authUserID: "old-1", firstName: "Стара", lastName: "", currencyCode: "EUR", languageCode: "uk")
        let newProfile = UserProfile(authUserID: "SERVER-1", firstName: "Нова", lastName: "", currencyCode: "EUR", languageCode: "uk")
        let client = Client(userID: "old-1", name: "Олена")
        [oldProfile, newProfile].forEach(context.insert)
        context.insert(client)
        try context.save()

        XCTAssertTrue(LegacyAccounts.migrate(email: "maria@studio.com", to: "SERVER-1", context: context, defaults: defaults))

        XCTAssertNotNil(oldProfile.deletedAt)
        XCTAssertNil(newProfile.deletedAt)
        XCTAssertEqual(client.userID, "SERVER-1")
        XCTAssertEqual(client.workspaceID, newProfile.workspaceID)
    }

    func testOtherEmailIsNotMoved() throws {
        try saveCredentials([AuthCredentials(email: "maria@studio.com", password: "x", userID: "old-1")])
        LegacyAccounts.stripPasswords(defaults: defaults)
        let client = Client(userID: "old-1", name: "Олена")
        context.insert(client)
        try context.save()

        XCTAssertFalse(LegacyAccounts.migrate(email: "anna@studio.com", to: "SERVER-2", context: context, defaults: defaults))
        XCTAssertEqual(client.userID, "old-1")
    }
}
