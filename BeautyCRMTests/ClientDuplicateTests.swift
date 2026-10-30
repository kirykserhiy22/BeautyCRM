//
//  ClientDuplicateTests.swift
//  BeautyCRMTests
//
//  #28 — дублікати клієнтів: ім'я + телефон, попередження замість заборони.
//

import XCTest
import SwiftData
@testable import BeautyCRM

@MainActor
final class ClientDuplicateTests: XCTestCase {

    private typealias F = AuditFixtures

    private var context: ModelContext!

    override func setUpWithError() throws {
        context = try F.makeContext()
    }

    @discardableResult
    private func add(
        _ name: String,
        phone: String? = nil,
        instagram: String? = nil,
        telegram: String? = nil,
        userID: String = F.userID
    ) throws -> Client {
        let client = Client(userID: userID, name: name, phone: phone, instagram: instagram, telegram: telegram)
        context.insert(client)
        try context.save()
        return client
    }

    private func duplicate(
        _ name: String,
        phone: String? = nil,
        instagram: String? = nil,
        telegram: String? = nil,
        excluding id: UUID? = nil
    ) throws -> Client? {
        try ClientManager.possibleDuplicate(
            name: name, phone: phone, instagram: instagram, telegram: telegram,
            userID: F.userID, excluding: id, context: context
        )
    }


    func testSameNameDifferentPhonesIsNotDuplicate() throws {
        try add("Anna", phone: "+49 151 0000 0001")

        XCTAssertNil(try duplicate("Anna", phone: "+49 151 0000 0002"), "Дві різні Анни")
    }

    func testSameNameAndSamePhoneIsDuplicate() throws {
        let anna = try add("Anna", phone: "+49 151 0000 0001")

        XCTAssertEqual(try duplicate("Anna", phone: "+4915100000001")?.id, anna.id, "Телефон порівнюється за цифрами")
    }

    func testNameComparisonIgnoresCaseSpacesAndAccents() throws {
        let olena = try add("Olena  Kovál", phone: "0501234567")

        XCTAssertEqual(try duplicate("  olena kOval ", phone: "050 123 45 67")?.id, olena.id)
    }

    func testMissingPhoneMeansPossibleDuplicate() throws {
        try add("Mia Novak")

        XCTAssertNotNil(try duplicate("Mia Novak", phone: "+420 600 000 102"), "У наявного немає телефону")
        XCTAssertNotNil(try duplicate("mia novak"), "Ні в кого немає телефону")
    }

    func testSameNameDifferentInstagramIsNotDuplicate() throws {
        try add("Anna", instagram: "@anna.nails")

        XCTAssertNil(try duplicate("Anna", instagram: "anna_beauty"), "Різні Instagram — різні люди")
    }

    func testSameNameDifferentTelegramIsNotDuplicate() throws {
        try add("Anna", telegram: "anna_k")

        XCTAssertNil(try duplicate("Anna", telegram: "@anna_m"))
    }

    func testSameInstagramIsDuplicateInAnyForm() throws {
        let anna = try add("Anna", instagram: "@Anna.Nails")

        for handle in ["anna.nails", "https://instagram.com/anna.nails/", " @ANNA.NAILS "] {
            XCTAssertEqual(try duplicate("Anna", instagram: handle)?.id, anna.id, handle)
        }
    }

    func testOneMatchingContactWinsOverOtherDifferences() throws {
        // Той самий телефон, але інший Instagram — все одно схоже на ту саму людину
        let anna = try add("Anna", phone: "123", instagram: "anna_old")

        XCTAssertEqual(try duplicate("Anna", phone: "123", instagram: "anna_new")?.id, anna.id)
    }

    func testContactsOfDifferentTypesDoNotDistinguish() throws {
        // В однієї лише телефон, в іншої лише Instagram — порівняти нічого
        try add("Anna", phone: "123")

        XCTAssertNotNil(try duplicate("Anna", instagram: "anna.nails"))
    }

    func testDifferentNameIsNotDuplicate() throws {
        try add("Anna", phone: "123")

        XCTAssertNil(try duplicate("Hanna", phone: "123"))
    }

    func testEditingClientDoesNotMatchItself() throws {
        let anna = try add("Anna", phone: "123")

        XCTAssertNil(try duplicate("Anna", phone: "123", excluding: anna.id))
    }

    func testDeletedAndOtherUsersClientsAreIgnored() throws {
        let deleted = try add("Anna", phone: "123")
        deleted.markDeleted()
        try context.save()
        try add("Anna", phone: "123", userID: "someone-else")

        XCTAssertNil(try duplicate("Anna", phone: "123"))
    }

    func testNoLimitOnClientCount() throws {
        // Раніше перевірялися лише перші 500 клієнтів
        for index in 0..<520 {
            context.insert(Client(userID: F.userID, name: "Client \(index)"))
        }
        try context.save()

        XCTAssertNotNil(try duplicate("Client 519"))
    }

    func testDuplicateTextsAreTranslated() {
        let keys = ["clients.possibleDuplicate.title", "clients.possibleDuplicate.message", "clients.possibleDuplicate.save"]

        for language in SupportedLanguage.all.map(\.code) {
            let path = Bundle.main.path(forResource: language, ofType: "lproj")
            let bundle = path.flatMap(Bundle.init(path:))
            for key in keys {
                let text = bundle?.localizedString(forKey: key, value: nil, table: "Localizable")
                XCTAssertNotEqual(text, key, "\(language): \(key)")
            }
            let message = bundle?.localizedString(forKey: "clients.possibleDuplicate.message", value: nil, table: "Localizable") ?? ""
            XCTAssertTrue(message.contains("%@"), "\(language): у тексті має бути місце для імені")
        }
    }
}
