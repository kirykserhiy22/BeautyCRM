//
//  ProfessionTests.swift
//  BeautyCRMTests
//

import XCTest
import UIKit
@testable import BeautyCRM

final class ProfessionTests: XCTestCase {

    private let languages = ["uk", "en", "de", "pl", "cs"]

    // Усі ключі, які мають бути в кожній мові
    private var requiredKeys: [String] {
        var keys: [String] = []
        for config in Profession.allCases.map(\.config) + [ProfessionConfig.generic] {
            keys += [config.titleKey, config.descriptionKey, config.examplesKey]
            keys += config.suggestedServiceKeys
        }
        return keys
    }

    func testEveryProfessionHasNonEmptyConfig() {
        for profession in Profession.allCases {
            let config = profession.config
            XCTAssertFalse(config.titleKey.isEmpty, "\(profession)")
            XCTAssertFalse(config.descriptionKey.isEmpty, "\(profession)")
            XCTAssertFalse(config.examplesKey.isEmpty, "\(profession)")
            XCTAssertTrue((4...6).contains(config.suggestedServiceKeys.count), "\(profession)")
            XCTAssertFalse(config.suggestedServiceKeys.contains(where: \.isEmpty), "\(profession)")
        }
    }

    func testRawValueRoundTripAndUnknownValue() {
        for profession in Profession.allCases {
            XCTAssertEqual(Profession(rawValue: profession.rawValue), profession)
        }
        XCTAssertNil(Profession(rawValue: "barber_v2"))
        XCTAssertNil(Profession(rawValue: ""))
    }

    // rawValue іде в базу і на сервер — випадкова зміна має ламати тест
    func testRawValuesNeverChange() {
        XCTAssertEqual(Profession.hairStylist.rawValue, "hair_stylist")
        XCTAssertEqual(Profession.nailArtist.rawValue, "nail_artist")
        XCTAssertEqual(Profession.lashBrowArtist.rawValue, "lash_brow_artist")
    }

    // SF Symbols мають існувати в системі, інакше іконка буде порожньою
    func testSystemIconsExist() {
        for config in Profession.allCases.map(\.config) + [ProfessionConfig.generic] {
            for icon in [config.icon, config.serviceIcon] {
                if case .system(let name) = icon {
                    XCTAssertNotNil(UIImage(systemName: name), "SF Symbol \(name)")
                }
            }
        }
    }

    func testAllKeysExistInAllLanguages() throws {
        for language in languages {
            let path = try XCTUnwrap(
                Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: language),
                "Localizable.strings for \(language)"
            )
            let strings = try XCTUnwrap(NSDictionary(contentsOfFile: path) as? [String: String])
            for key in requiredKeys {
                XCTAssertFalse((strings[key] ?? "").isEmpty, "\(language): missing \(key)")
            }
        }
    }
}
