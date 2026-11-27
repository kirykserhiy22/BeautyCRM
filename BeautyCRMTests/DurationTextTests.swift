import XCTest
@testable import BeautyCRM

final class DurationTextTests: XCTestCase {

    private let uk: (String) -> String = {
        ["duration.minutes": "%d хв", "duration.hours": "%d год", "duration.hoursMinutes": "%d год %d хв"][$0] ?? $0
    }

    func testFormats() {
        let locale = Locale(identifier: "uk")
        XCTAssertEqual(DurationText.text(45, locale: locale, localized: uk), "45 хв")
        XCTAssertEqual(DurationText.text(60, locale: locale, localized: uk), "1 год")
        XCTAssertEqual(DurationText.text(75, locale: locale, localized: uk), "1 год 15 хв")
        XCTAssertEqual(DurationText.text(150, locale: locale, localized: uk), "2 год 30 хв")
        XCTAssertEqual(DurationText.text(-5, locale: locale, localized: uk), "0 хв")
    }
}
