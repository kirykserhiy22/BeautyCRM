//
//  ServerAuthTests.swift
//  BeautyCRMTests
//
//  Вхід через сервер: помилки бібліотеки → зрозумілі тексти; дані реєстрації до підтвердження пошти.
//

import XCTest
import Supabase
@testable import BeautyCRM

final class ServerAuthTests: XCTestCase {

    private func apiError(_ code: ErrorCode) -> Supabase.AuthError {
        .api(
            message: "raw server text",
            errorCode: code,
            underlyingData: Data(),
            underlyingResponse: HTTPURLResponse(url: URL(string: "https://x.supabase.co")!, statusCode: 400, httpVersion: nil, headerFields: nil)!
        )
    }

    func testMapsServerErrors() {
        XCTAssertEqual(ServerAuth.map(apiError(.invalidCredentials)), .wrongPassword)
        XCTAssertEqual(ServerAuth.map(apiError(.emailNotConfirmed)), .emailNotConfirmed)
        XCTAssertEqual(ServerAuth.map(apiError(.otpExpired)), .invalidCode)
        XCTAssertEqual(ServerAuth.map(apiError(.overEmailSendRateLimit)), .tooManyRequests)
        XCTAssertEqual(ServerAuth.map(apiError(.userAlreadyExists)), .userAlreadyExists)
        XCTAssertEqual(ServerAuth.map(apiError(ErrorCode("something_new"))), .serverError)
    }

    func testMapsNetworkErrors() {
        XCTAssertEqual(ServerAuth.map(URLError(.notConnectedToInternet)), .noConnection)
        XCTAssertEqual(ServerAuth.map(URLError(.timedOut)), .noConnection)
        XCTAssertEqual(ServerAuth.map(URLError(.badServerResponse)), .serverError)
    }

    // Кожна помилка має текст усіма мовами
    func testErrorTextsExist() throws {
        let errors: [BeautyCRM.AuthError] = [.emailNotConfirmed, .invalidCode, .tooManyRequests, .noConnection, .serverError, .samePassword, .passwordsDontMatch]
        for language in ["uk", "en", "de", "pl", "cs"] {
            let path = try XCTUnwrap(Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: language))
            let strings = try XCTUnwrap(NSDictionary(contentsOfFile: path) as? [String: String])
            for error in errors {
                XCTAssertFalse((strings[error.localizationKey] ?? "").isEmpty, "\(language): \(error.localizationKey)")
            }
            for key in ["auth.code.title", "auth.code.resendIn", "auth.code.changeEmail", "auth.forgot.link", "auth.forgot.send", "auth.reset.codeTo", "auth.reset.save"] {
                XCTAssertFalse((strings[key] ?? "").isEmpty, "\(language): \(key)")
            }
        }
    }

    func testPendingSignUpKeptPerEmail() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "ServerAuthTests"))
        defaults.removePersistentDomain(forName: "ServerAuthTests")

        let pending = PendingSignUp(
            email: "maria@studio.com", firstName: "Марія", lastName: "К", businessName: nil,
            currencyCode: "EUR", languageCode: "uk", professionRaw: "hair_stylist"
        )
        pending.save(defaults: defaults)

        XCTAssertEqual(PendingSignUp.load(email: " Maria@Studio.com ", defaults: defaults), pending)
        XCTAssertNil(PendingSignUp.load(email: "other@studio.com", defaults: defaults))

        PendingSignUp.clear(defaults: defaults)
        XCTAssertNil(PendingSignUp.load(email: "maria@studio.com", defaults: defaults))
    }
}
