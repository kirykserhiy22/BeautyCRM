//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 23.05.26.
//

import UIKit
import SwiftData

enum ClientPhotoService {

    // MARK: - ADD PHOTO

    // Важка частина: JPEG і мініатюра на диск. Викликати у фоні,
    // щоб екран не «замерзав» на великих фото (#39)
    nonisolated static func storeFiles(for image: UIImage) -> String? {

        guard let fileName = ClientPhotoStorage.saveImage(image) else {
            return nil
        }

        if let thumb = ClientPhotoThumbnailGenerator.generate(from: image) {
            ClientPhotoStorage.saveThumbnail(thumb, fileName: fileName)
        }

        return fileName
    }

    static func addPhoto(
        image: UIImage,
        client: Client,
        context: ModelContext
    ) {

        guard let fileName = storeFiles(for: image) else {
            return
        }

        addPhoto(fileName: fileName, client: client, context: context)
    }

    // Запис у базу — на головному потоці, коли файли вже на диску
    static func addPhoto(
        fileName: String,
        stage: ClientPhotoStage? = nil,
        caption: String? = nil,
        postID: UUID? = nil,
        client: Client,
        context: ModelContext
    ) {

        let photo = ClientPhoto(
            clientID: client.id,
            fileName: fileName
        )
        photo.stage = stage
        photo.caption = cleanCaption(caption)
        photo.postID = postID

        client.photos.append(photo)
        context.insert(photo)

        context.saveReportingErrors()
    }

    // MARK: - CAPTION

    static let captionLimit = 120

    // Підпис без зайвих пробілів і не довший за ліміт; порожній — nil
    static func cleanCaption(_ text: String?) -> String? {
        let trimmed = String((text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).prefix(captionLimit))
        return trimmed.isEmpty ? nil : trimmed
    }

    // Зміна позначки й підпису з меню «⋯» у стрічці фото
    static func update(
        stage: ClientPhotoStage?,
        caption: String?,
        photo: ClientPhoto,
        context: ModelContext
    ) {
        let caption = cleanCaption(caption)
        guard photo.stage != stage || photo.caption != caption else {
            return
        }
        photo.stage = stage
        photo.caption = caption
        context.saveReportingErrors()
    }

    static func updateCaption(
        _ text: String,
        photo: ClientPhoto,
        context: ModelContext
    ) {

        let trimmed = String(
            text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(captionLimit)
        )
        let caption = trimmed.isEmpty ? nil : trimmed

        guard caption != photo.caption else {
            return
        }

        photo.caption = caption
        context.saveReportingErrors()
    }

    // Повторний дотик по вибраній позначці знімає її
    static func toggleStage(
        _ stage: ClientPhotoStage,
        photo: ClientPhoto,
        context: ModelContext
    ) {
        photo.stage = photo.stage == stage ? nil : stage
        context.saveReportingErrors()
    }

    // MARK: - POSTS

    // Один підпис на допис: підписи окремих фото, з'єднані в порядку вибору.
    // Так нічого з набраного в редакторі не губиться, коли майстер вибрав «Одним дописом»
    static func postCaption(_ captions: [String?]) -> String? {
        let parts = captions.compactMap { cleanCaption($0) }
        guard !parts.isEmpty else { return nil }
        return cleanCaption(parts.joined(separator: "\n"))
    }

    // Редагування допису з меню «⋯»: позначка — кожному фото своя, підпис — один, на першому фото
    static func updatePost(
        _ photos: [ClientPhoto],
        stages: [ClientPhotoStage?],
        caption: String?,
        context: ModelContext
    ) {
        let caption = cleanCaption(caption)
        for (index, photo) in photos.enumerated() {
            photo.stage = index < stages.count ? stages[index] : photo.stage
            photo.caption = index == 0 ? caption : nil
        }
        context.saveReportingErrors()
    }

    // Видалення допису — усі його фото разом
    static func deletePost(_ photos: [ClientPhoto], client: Client, context: ModelContext) {
        for photo in photos {
            ClientPhotoStorage.deleteImage(at: photo.fileName)
            photo.markDeleted()
        }
        context.saveReportingErrors()
    }

    // MARK: - DELETE PHOTO

    static func deletePhoto(
        photo: ClientPhoto,
        client: Client,
        context: ModelContext
    ) {

        ClientPhotoStorage.deleteImage(at: photo.fileName)

        photo.markDeleted()

        context.saveReportingErrors()
    }
}


// Фото клієнта, складені в дописи: окреме фото — допис з одного фото,
// фото з однаковим postID — один допис-карусель
struct ClientPhotoPost: Identifiable {
    let photos: [ClientPhoto]

    // Ідентифікатор допису = перше фото в ньому
    var id: UUID { photos[0].id }
    var cover: ClientPhoto { photos[0] }
    var isCarousel: Bool { photos.count > 1 }

    // Підпис допису — під каруселлю, не змінюється при гортанні
    var caption: String? { ClientPhotoService.postCaption(photos.map(\.caption)) }

    // Нові дописи першими; всередині допису — у порядку, в якому фото вибрали
    static func group(_ photos: [ClientPhoto]) -> [ClientPhotoPost] {
        let alive = photos.filter { $0.deletedAt == nil }
        let groups = Dictionary(grouping: alive) { $0.postID ?? $0.id }
        return groups.values
            .map { ClientPhotoPost(photos: $0.sorted { $0.createdAt < $1.createdAt }) }
            .sorted { lhs, rhs in
                let l = lhs.photos.map(\.createdAt).max() ?? .distantPast
                let r = rhs.photos.map(\.createdAt).max() ?? .distantPast
                return l > r
            }
    }
}
