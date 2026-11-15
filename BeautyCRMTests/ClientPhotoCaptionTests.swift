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

    // «Одним дописом»: фото зі спільним postID — один допис у порядку вибору;
    // окремі фото — кожне своїм дописом; нові дописи першими
    func testPhotosGroupIntoPosts() throws {
        let context = try F.makeContext()
        let client = Client(userID: F.userID, name: "Олена")
        context.insert(client)

        ClientPhotoService.addPhoto(fileName: "old.jpg", client: client, context: context)
        let post = UUID()
        ClientPhotoService.addPhoto(fileName: "before.jpg", stage: .before, postID: post, client: client, context: context)
        ClientPhotoService.addPhoto(fileName: "after.jpg", stage: .after, postID: post, client: client, context: context)
        ClientPhotoService.addPhoto(fileName: "newest.jpg", client: client, context: context)

        let posts = ClientPhotoPost.group(client.photos)

        XCTAssertEqual(posts.map { $0.photos.map(\.fileName) }, [["newest.jpg"], ["before.jpg", "after.jpg"], ["old.jpg"]])
        XCTAssertEqual(posts.map(\.isCarousel), [false, true, false])
        XCTAssertEqual(posts[1].cover.fileName, "before.jpg", "Обкладинка допису — перше вибране фото")

        // Видалене фото зникає з допису, допис лишається
        posts[1].photos[0].markDeleted()
        XCTAssertEqual(ClientPhotoPost.group(client.photos)[1].photos.map(\.fileName), ["after.jpg"])
    }

    // Допис: один підпис (з'єднані підписи фото), видалення — усі фото разом
    func testPostCaptionAndDeleteWholePost() throws {
        let context = try F.makeContext()
        let client = Client(userID: F.userID, name: "Олена")
        context.insert(client)
        let post = UUID()
        ClientPhotoService.addPhoto(fileName: "1.jpg", stage: .before, caption: "Холодний блонд", postID: post, client: client, context: context)
        ClientPhotoService.addPhoto(fileName: "2.jpg", stage: .after, caption: nil, postID: post, client: client, context: context)
        ClientPhotoService.addPhoto(fileName: "solo.jpg", client: client, context: context)

        XCTAssertEqual(ClientPhotoService.postCaption(["  ", "a", nil, "b"]), "a\nb")

        let carousel = try XCTUnwrap(ClientPhotoPost.group(client.photos).first { $0.isCarousel })
        XCTAssertEqual(carousel.caption, "Холодний блонд", "Підпис допису не залежить від того, яке фото видно")

        ClientPhotoService.updatePost(carousel.photos, stages: [.after, .before], caption: "Новий підпис", context: context)
        XCTAssertEqual(carousel.photos.map(\.stage), [.after, .before])
        XCTAssertEqual(carousel.photos.map(\.caption), ["Новий підпис", nil])

        ClientPhotoService.deletePost(carousel.photos, client: client, context: context)
        XCTAssertEqual(ClientPhotoPost.group(client.photos).map { $0.photos.map(\.fileName) }, [["solo.jpg"]],
                       "Видалено весь допис, окреме фото лишилось")
    }
}
