//
//  ProfileSettingsTests.swift
//  BeautyCRMTests
//
//  #34 — екран «Профіль»: ім'я, назва салону, валюта.
//

import XCTest
import SwiftData
@testable import BeautyCRM

@MainActor
final class ProfileSettingsTests: XCTestCase {

    private func makeProfile(in context: ModelContext) throws -> UserProfile {
        let profile = UserProfile(
            authUserID: AuditFixtures.userID,
            firstName: "Demo",
            lastName: "Master",
            businessName: "Demo Studio",
            currencyCode: "EUR",
            languageCode: "uk"
        )
        context.insert(profile)
        try context.save()
        return profile
    }


    func testUpdateSavesTrimmedValuesAndCurrency() throws {
        let context = try AuditFixtures.makeContext()
        let profile = try makeProfile(in: context)

        let saved = UserProfileManager.update(
            profile: profile,
            firstName: "  Olena ",
            lastName: " Koval",
            businessName: " Nail Room  ",
            currencyCode: "PLN",
            context: context
        )

        XCTAssertTrue(saved)
        XCTAssertFalse(context.hasChanges)
        XCTAssertEqual(profile.firstName, "Olena")
        XCTAssertEqual(profile.lastName, "Koval")
        XCTAssertEqual(profile.businessName, "Nail Room")
        XCTAssertEqual(profile.currencyCode, "PLN")
        XCTAssertEqual(profile.languageCode, "uk", "Мова змінюється окремим екраном")
    }

    func testEmptyBusinessNameBecomesNil() throws {
        let context = try AuditFixtures.makeContext()
        let profile = try makeProfile(in: context)

        UserProfileManager.update(
            profile: profile,
            firstName: "Demo",
            lastName: "Master",
            businessName: "   ",
            currencyCode: "EUR",
            context: context
        )

        XCTAssertNil(profile.businessName)
    }

    func testNamesAreRequired() {
        XCTAssertEqual(
            UserProfileManager.validationErrorKey(firstName: " ", lastName: "Master"),
            "signup.error.firstName"
        )
        XCTAssertEqual(
            UserProfileManager.validationErrorKey(firstName: "Demo", lastName: ""),
            "signup.error.lastName"
        )
        XCTAssertNil(UserProfileManager.validationErrorKey(firstName: "Demo", lastName: "Master"))
    }

    func testProfileTextsAndCurrencyNamesAreTranslated() {
        let keys = ["settings.profile", "settings.profile.currencyNote"]
            + SupportedCurrency.all.map { "currency.\($0.code)" }

        for language in SupportedLanguage.all.map(\.code) {
            let path = Bundle.main.path(forResource: language, ofType: "lproj")
            let bundle = path.flatMap(Bundle.init(path:))
            for key in keys {
                let text = bundle?.localizedString(forKey: key, value: nil, table: "Localizable")
                XCTAssertNotEqual(text, key, "\(language): \(key)")
            }
        }
    }
}
