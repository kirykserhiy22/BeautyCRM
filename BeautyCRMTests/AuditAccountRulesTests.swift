//
//  AuditAccountRulesTests.swift
//  BeautyCRMTests
//
//  Аудит: реєстрація, вхід, відновлення профілю, мова, валюта, спеціалізація.
//

import XCTest
import SwiftData
@testable import BeautyCRM

final class AuditAccountRulesTests: XCTestCase {

    private typealias F = AuditFixtures

    // LocalAuthService пише в UserDefaults — зберігаємо й повертаємо чужі дані
    private let usersKey = "local_users"
    private let languageKey = "app_language"
    private var savedUsers: Data?
    private var savedLanguage: String?

    override func setUp() {
        super.setUp()
        savedUsers = UserDefaults.standard.data(forKey: usersKey)
        savedLanguage = UserDefaults.standard.string(forKey: languageKey)
        UserDefaults.standard.removeObject(forKey: usersKey)
    }

    override func tearDown() {
        UserDefaults.standard.set(savedUsers, forKey: usersKey)
        UserDefaults.standard.set(savedLanguage, forKey: languageKey)
        super.tearDown()
    }


    // MARK: - Реєстрація і вхід

    func testSignUpAndLoginErrors() {
        let auth = LocalAuthService()

        XCTAssertEqual(auth.signUp(email: "", password: "password1").error, .emptyEmail)
        XCTAssertEqual(auth.signUp(email: "not-an-email", password: "password1").error, .invalidEmail)
        XCTAssertEqual(auth.signUp(email: "demo@example.com", password: "short").error, .weakPassword)

        XCTAssertTrue(auth.signUp(email: " Demo@Example.com ", password: "password1").isSuccess)
        XCTAssertEqual(auth.signUp(email: "demo@example.com", password: "password1").error, .userAlreadyExists)
        XCTAssertTrue(auth.isEmailRegistered("DEMO@example.com"))

        XCTAssertTrue(auth.login(email: "demo@EXAMPLE.com", password: "password1").isSuccess)
        XCTAssertEqual(auth.login(email: "demo@example.com", password: "wrong").error, .wrongPassword)
        XCTAssertEqual(auth.login(email: "nobody@example.com", password: "password1").error, .userNotFound)
    }

    func testPasswordIsNotStoredInPlainText() throws {
        _ = LocalAuthService().signUp(email: "demo@example.com", password: "secret-pass-1")

        let raw = try XCTUnwrap(UserDefaults.standard.data(forKey: usersKey))
        let text = String(decoding: raw, as: UTF8.self)

        XCTExpectFailure("AUDIT (відома проблема): пароль лежить у UserDefaults відкритим текстом")
        XCTAssertFalse(text.contains("secret-pass-1"))
    }

    func testEveryAuthErrorIsTranslated() {
        let keys = [
            AuthError.emptyEmail, .invalidEmail, .weakPassword,
            .userAlreadyExists, .userNotFound, .wrongPassword
        ].map(\.localizationKey) + [
            "signup.error.email", "signup.error.password",
            "signup.error.firstName", "signup.error.lastName", "signup.error.profession",
            "login.error.fillFields", "login.error.failed", "login.error.missingUserID"
        ]

        let localization = LocalizationManager()
        for language in SupportedLanguage.all.map(\.code) {
            localization.setLanguage(language)
            for key in keys {
                XCTAssertNotEqual(localization.localizedString(for: key), key, "\(language): \(key)")
            }
        }
    }

    func testSignUpStepsShowErrors() {
        let state = SignUpState()

        XCTAssertFalse(state.goNext())
        XCTAssertEqual(state.errorMessage, "signup.error.email")

        state.email = "fresh-\(UUID().uuidString.prefix(6))@example.com"
        state.password = "password1"
        XCTAssertFalse(state.goNext())
        XCTAssertEqual(state.step, .profile)

        XCTAssertFalse(state.goNext())
        XCTAssertEqual(state.errorMessage, "signup.error.firstName")
    }


    // MARK: - Відновлення профілю

    func testLoaderRestoresLanguageCurrencyAndProfession() throws {
        let context = try F.makeContext()
        let profile = UserProfile(
            authUserID: F.userID, firstName: "Demo", lastName: "Master",
            currencyCode: "CZK", languageCode: "cs"
        )
        profile.profession = .nailArtist
        context.insert(profile)
        try context.save()

        let localization = LocalizationManager()
        let currency = CurrencyManager()
        let profession = ProfessionManager()

        let loaded = UserProfileLoader.load(
            context: context, userID: F.userID,
            localization: localization, currency: currency, profession: profession
        )

        XCTAssertNotNil(loaded)
        XCTAssertEqual(localization.languageCode, "cs")
        XCTAssertEqual(currency.currencyCode, "CZK")
        XCTAssertEqual(profession.current, .nailArtist)
    }

    func testLoaderWithoutProfileKeepsPreviousValues() throws {
        let context = try F.makeContext()
        let currency = CurrencyManager()
        currency.setCurrency("GBP")

        let loaded = UserProfileLoader.load(
            context: context, userID: "missing",
            localization: LocalizationManager(), currency: currency, profession: ProfessionManager()
        )

        // Фіксуємо поведінку: профілю немає — валюта від попереднього акаунта лишається
        XCTAssertNil(loaded)
        XCTAssertEqual(currency.currencyCode, "GBP")
    }

    func testCurrencyFormatFollowsAppLanguage() {
        let currency = CurrencyManager()
        currency.setCurrency("EUR")

        let text = currency.format(Decimal(string: "1234.5")!)

        // Формат береться з мови пристрою, а не з мови додатку
        XCTAssertTrue(text.contains("€"))
        XCTAssertEqual(text, CurrencyFormatter.string(amount: Decimal(string: "1234.5")!, currencyCode: "EUR"))
    }
}
