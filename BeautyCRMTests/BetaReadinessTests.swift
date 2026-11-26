//
//  BetaReadinessTests.swift
//  BeautyCRMTests
//
//  Підготовка до TestFlight / App Store: маніфест приватності в додатку, позначка шифрування,
//  посилання на політику й підтримку.
//

import XCTest
@testable import BeautyCRM

final class BetaReadinessTests: XCTestCase {

    func testPrivacyManifestIsBundled() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))
        let manifest = try XCTUnwrap(NSDictionary(contentsOf: url) as? [String: Any])
        XCTAssertEqual(manifest["NSPrivacyTracking"] as? Bool, false, "без стеження")
        let apis = try XCTUnwrap(manifest["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        XCTAssertTrue(apis.contains { $0["NSPrivacyAccessedAPIType"] as? String == "NSPrivacyAccessedAPICategoryUserDefaults" })
    }

    // Лише стандартне HTTPS — Apple не питає про експортне шифрування при кожному завантаженні
    func testEncryptionExemptionIsDeclared() {
        XCTAssertEqual(Bundle.main.object(forInfoDictionaryKey: "ITSAppUsesNonExemptEncryption") as? Bool, false)
    }

    func testLinksPointToOwnDomain() {
        XCTAssertEqual(Constants.privacyPolicyURL.host, "getbeautybase.com")
        XCTAssertEqual(Constants.termsURL.host, "getbeautybase.com")
        XCTAssertEqual(Constants.supportURL.scheme, "mailto")
    }

    func testTextsExist() throws {
        for language in ["uk", "en", "de", "pl", "cs"] {
            let path = try XCTUnwrap(Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: language))
            let strings = try XCTUnwrap(NSDictionary(contentsOfFile: path) as? [String: String])
            for key in ["settings.group.about", "settings.privacy", "settings.terms", "settings.support"] {
                XCTAssertFalse((strings[key] ?? "").isEmpty, "\(language): \(key)")
            }
        }
    }
}
