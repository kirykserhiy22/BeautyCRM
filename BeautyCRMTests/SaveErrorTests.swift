//
//  SaveErrorTests.swift
//  BeautyCRMTests
//
//  #30 — збереження з показом помилки, #31 — зрозумілі помилки форми запису.
//

import XCTest
import SwiftData
@testable import BeautyCRM

@MainActor
final class SaveErrorTests: XCTestCase {

    private var reported: [Error] = []
    private var originalHandler: ((Error) -> Void)!

    override func setUp() {
        super.setUp()
        reported = []
        originalHandler = SaveErrorReporter.handler
        SaveErrorReporter.handler = { [weak self] in self?.reported.append($0) }
    }

    override func tearDown() {
        SaveErrorReporter.handler = originalHandler
        super.tearDown()
    }


    // MARK: - SAVE

    func testSuccessfulSaveReturnsTrueAndReportsNothing() throws {
        let context = try AuditFixtures.makeContext()
        context.insert(Client(userID: AuditFixtures.userID, name: "Demo Client"))

        XCTAssertTrue(context.saveReportingErrors())
        XCTAssertFalse(context.hasChanges)
        XCTAssertTrue(reported.isEmpty)
    }

    func testNothingToSaveIsSuccess() throws {
        let context = try AuditFixtures.makeContext()

        XCTAssertTrue(context.saveReportingErrors())
        XCTAssertTrue(reported.isEmpty)
    }

    func testReportGoesToHandler() {
        struct Failure: Error {}

        SaveErrorReporter.report(Failure())

        XCTAssertEqual(reported.count, 1)
        XCTAssertTrue(reported.first is Failure)
    }


    // MARK: - TEXTS

    func testAppointmentErrorsAndSaveErrorAreTranslated() {
        let errors: [AppointmentError] = [.timeConflict, .noClient, .noServices, .invalidStatus]
        let keys = errors.map(\.localizationKey) + ["error.save.title", "error.save.message", "common.ok"]

        XCTAssertEqual(Set(keys).count, keys.count, "Кожна помилка має свій текст")

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
