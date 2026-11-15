//
//  OnboardingStoreTests.swift
//  BeautyCRMTests
//
//  Гід по додатку показується один раз і лише новому майстрові.
//

import XCTest
@testable import BeautyCRM

final class OnboardingStoreTests: XCTestCase {

    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "OnboardingStoreTests")
        defaults.removePersistentDomain(forName: "OnboardingStoreTests")
    }

    func testGuideWaitsOnlyForNewMasterAndOnlyOnce() {
        XCTAssertFalse(OnboardingStore.isPending(userID: "old", defaults: defaults), "Звичайний вхід — без гіда")

        OnboardingStore.markPending(userID: "new", defaults: defaults)
        XCTAssertTrue(OnboardingStore.isPending(userID: "new", defaults: defaults))
        XCTAssertFalse(OnboardingStore.isPending(userID: "old", defaults: defaults), "Інший акаунт гід не чекає")

        OnboardingStore.markSeen(userID: "new", defaults: defaults)
        XCTAssertFalse(OnboardingStore.isPending(userID: "new", defaults: defaults), "Вдруге гід не показується")
    }

    func testSevenSlidesWithTextsInEveryLanguage() throws {
        XCTAssertEqual(OnboardingSlide.allCases.count, 7)

        for language in ["uk", "en", "de", "pl", "cs"] {
            let path = try XCTUnwrap(Bundle(for: LocalizationManager.self).path(forResource: language, ofType: "lproj")
                ?? Bundle.main.path(forResource: language, ofType: "lproj"))
            let bundle = try XCTUnwrap(Bundle(path: path))

            for slide in OnboardingSlide.allCases {
                for key in [slide.titleKey, slide.textKey] {
                    XCTAssertNotEqual(bundle.localizedString(forKey: key, value: nil, table: nil), key, "\(language): \(key)")
                }
            }
        }
    }
}

// Тексти, ключі яких складаються в коді («settings.appearance.\(rawValue)»),
// пошук невикористаних ключів не бачить — тому перевіряємо їх окремо в усіх мовах
final class DynamicLocalizationKeysTests: XCTestCase {

    func testAppearanceAndReminderTitlesExistInEveryLanguage() throws {
        let keys = AppearanceMode.allCases.map(\.titleKey)
            + ReminderLead.allCases.flatMap { [$0.titleKey, $0.notificationTitleKey] }
            + ClientMessageToken.allCases.map(\.titleKey)
            + ClientVisitFilter.allCases.map(\.titleKey)

        for language in ["uk", "en", "de", "pl", "cs"] {
            let path = try XCTUnwrap(Bundle.main.path(forResource: language, ofType: "lproj"))
            let bundle = try XCTUnwrap(Bundle(path: path))
            for key in keys {
                XCTAssertNotEqual(bundle.localizedString(forKey: key, value: nil, table: nil), key, "\(language): \(key)")
            }
        }
    }
}
