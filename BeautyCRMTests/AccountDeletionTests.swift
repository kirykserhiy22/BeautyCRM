//
//  AccountDeletionTests.swift
//  BeautyCRMTests
//
//  «Видалити акаунт»: на телефоні стирається все, що належить акаунту, і тільки воно.
//

import XCTest
import SwiftData
@testable import BeautyCRM

@MainActor
final class AccountDeletionTests: XCTestCase {

    func testWipesOnlyThisAccountsData() throws {
        let context = try AuditFixtures.makeContext()

        for userID in ["me", "other"] {
            let client = Client(userID: userID, name: "Олена")
            context.insert(UserProfile(authUserID: userID, firstName: "A", lastName: "B", currencyCode: "EUR", languageCode: "uk"))
            context.insert(client)
            context.insert(Service(userID: userID, name: "Стрижка", pricingType: .fixed, price: 40))
            let appointment = Appointment(userID: userID, clientID: client.id, clientName: "Олена", startDate: Date(), duration: 60)
            appointment.services = [AppointmentServiceItem(serviceID: UUID(), serviceName: "Стрижка", plannedPrice: 40)]
            context.insert(appointment)
            context.insert(DayOff(userID: userID, date: Date()))
        }
        try context.save()

        XCTAssertTrue(AccountDeletion.wipeLocalData(userID: "me", context: context))

        XCTAssertEqual(try context.fetch(FetchDescriptor<UserProfile>()).map(\.authUserID), ["other"])
        XCTAssertEqual(try context.fetch(FetchDescriptor<Client>()).map(\.userID), ["other"])
        XCTAssertEqual(try context.fetch(FetchDescriptor<Service>()).map(\.userID), ["other"])
        XCTAssertEqual(try context.fetch(FetchDescriptor<Appointment>()).map(\.userID), ["other"])
        XCTAssertEqual(try context.fetch(FetchDescriptor<DayOff>()).map(\.userID), ["other"])
        XCTAssertEqual(try context.fetch(FetchDescriptor<AppointmentServiceItem>()).count, 1)
    }

    func testTextsExist() throws {
        for language in ["uk", "en", "de", "pl", "cs"] {
            let path = try XCTUnwrap(Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: language))
            let strings = try XCTUnwrap(NSDictionary(contentsOfFile: path) as? [String: String])
            for key in ["settings.deleteAccount", "deleteAccount.title", "deleteAccount.warning", "deleteAccount.typeEmail", "deleteAccount.confirm"] {
                XCTAssertFalse((strings[key] ?? "").isEmpty, "\(language): \(key)")
            }
        }
    }
}
