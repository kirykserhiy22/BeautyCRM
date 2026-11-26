//
//  ClientReferencesTests.swift
//  BeautyCRMTests
//
//  Референси від клієнта: окремо від робіт майстра, прив'язані до запису.
//

import XCTest
import SwiftData
@testable import BeautyCRM

@MainActor
final class ClientReferencesTests: XCTestCase {

    func testWorksAndReferencesAreSeparate() throws {
        let context = try AuditFixtures.makeContext()
        let client = Client(userID: "u", name: "Олена")
        context.insert(client)
        let visit = UUID()

        ClientPhotoService.addPhoto(fileName: "work.jpg", stage: .after, client: client, context: context)
        ClientPhotoService.addPhoto(fileName: "ref1.jpg", stage: .before, kind: .reference, appointmentID: visit, client: client, context: context)
        ClientPhotoService.addPhoto(fileName: "ref2.jpg", kind: .reference, client: client, context: context)

        XCTAssertEqual(ClientPhotoPost.group(client.photos).map(\.cover.fileName), ["work.jpg"], "основна галерея — лише роботи")
        XCTAssertEqual(Set(ClientPhotoPost.group(client.photos, kind: .reference).map(\.cover.fileName)), ["ref1.jpg", "ref2.jpg"])
        XCTAssertEqual(ClientPhotoService.references(for: visit, in: client.photos).map(\.fileName), ["ref1.jpg"])

        let reference = try XCTUnwrap(client.photos.first { $0.fileName == "ref1.jpg" })
        XCTAssertNil(reference.stage, "у референсів немає «До / Після»")
    }

    // Старі фото (без виду) — це роботи
    func testOldPhotosAreWork() {
        let photo = ClientPhoto(clientID: UUID(), fileName: "old.jpg")
        XCTAssertNil(photo.kindRaw)
        XCTAssertEqual(photo.kind, .work)
        photo.kind = .reference
        XCTAssertEqual(photo.kindRaw, "reference")
    }

    func testTextsExist() throws {
        for language in ["uk", "en", "de", "pl", "cs"] {
            let path = try XCTUnwrap(Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: language))
            let strings = try XCTUnwrap(NSDictionary(contentsOfFile: path) as? [String: String])
            for key in ["photos.kind.work", "photos.kind.reference", "photos.references.empty", "photos.references.forVisit",
                        "appointment.references", "appointment.references.hint", "appointment.references.short"] {
                XCTAssertFalse((strings[key] ?? "").isEmpty, "\(language): \(key)")
            }
        }
    }
}
