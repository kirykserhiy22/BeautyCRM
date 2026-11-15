//
//  ClientPhotoCaptionTests.swift
//  BeautyCRMTests
//

import XCTest
import SwiftData
@testable import BeautyCRM

@MainActor
final class ClientPhotoCaptionTests: XCTestCase {

    private typealias F = AuditFixtures

    private func makePhoto() throws -> (ClientPhoto, ModelContext) {
        let context = try F.makeContext()
        let photo = ClientPhoto(clientID: UUID(), fileName: "demo.jpg")
        context.insert(photo)
        return (photo, context)
    }

    func testCaptionIsTrimmedAndEmptyBecomesNil() throws {
        let (photo, context) = try makePhoto()

        ClientPhotoService.updateCaption("  Airtouch 8.1 ", photo: photo, context: context)
        XCTAssertEqual(photo.caption, "Airtouch 8.1")

        ClientPhotoService.updateCaption("   ", photo: photo, context: context)
        XCTAssertNil(photo.caption)
    }

    func testCaptionIsLimited() throws {
        let (photo, context) = try makePhoto()

        ClientPhotoService.updateCaption(String(repeating: "a", count: 500), photo: photo, context: context)

        XCTAssertEqual(photo.caption?.count, ClientPhotoService.captionLimit)
    }

    func testUnchangedCaptionDoesNotTouchTheRecord() throws {
        let (photo, context) = try makePhoto()
        ClientPhotoService.updateCaption("Same", photo: photo, context: context)
        let updatedAt = photo.updatedAt

        ClientPhotoService.updateCaption(" Same ", photo: photo, context: context)

        XCTAssertEqual(photo.updatedAt, updatedAt, "Інакше синхронізація бачитиме зміну, якої не було")
    }

    func testStageTogglesAndSwitches() throws {
        let (photo, context) = try makePhoto()

        ClientPhotoService.toggleStage(.before, photo: photo, context: context)
        XCTAssertEqual(photo.stage, .before)

        ClientPhotoService.toggleStage(.after, photo: photo, context: context)
        XCTAssertEqual(photo.stage, .after)

        ClientPhotoService.toggleStage(.after, photo: photo, context: context)
        XCTAssertNil(photo.stage)
        XCTAssertNil(photo.stageRaw)
    }

    func testOnlyNailArtistsHaveNoStages() {
        XCTAssertTrue(Profession.hairStylist.config.showsPhotoStages)
        XCTAssertTrue(Profession.lashBrowArtist.config.showsPhotoStages)
        XCTAssertFalse(Profession.nailArtist.config.showsPhotoStages)
    }

    // Фото з редактора: позначка й підпис зберігаються одразу при додаванні
    func testAddPhotoKeepsStageAndCleanCaption() throws {
        let context = try F.makeContext()
        let client = Client(userID: F.userID, name: "Олена")
        context.insert(client)

        ClientPhotoService.addPhoto(fileName: "a.jpg", stage: .after, caption: "  Блонд 9.1 ", client: client, context: context)
        ClientPhotoService.addPhoto(fileName: "b.jpg", stage: nil, caption: "   ", client: client, context: context)

        let added = client.photos.sorted { $0.fileName < $1.fileName }
        XCTAssertEqual(added.map(\.stage), [.after, nil])
        XCTAssertEqual(added.map(\.caption), ["Блонд 9.1", nil])
    }

    // Меню «⋯» у стрічці: зміна позначки й підпису разом
    func testUpdateChangesStageAndCaption() throws {
        let (photo, context) = try makePhoto()

        ClientPhotoService.update(stage: .before, caption: "До фарбування", photo: photo, context: context)
        XCTAssertEqual(photo.stage, .before)
        XCTAssertEqual(photo.caption, "До фарбування")

        ClientPhotoService.update(stage: nil, caption: "", photo: photo, context: context)
        XCTAssertNil(photo.stage)
        XCTAssertNil(photo.caption)
    }
}
