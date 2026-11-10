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
        client: Client,
        context: ModelContext
    ) {

        let photo = ClientPhoto(
            clientID: client.id,
            fileName: fileName
        )

        client.photos.append(photo)
        context.insert(photo)

        context.saveReportingErrors()
    }

    // MARK: - CAPTION

    static let captionLimit = 120

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
