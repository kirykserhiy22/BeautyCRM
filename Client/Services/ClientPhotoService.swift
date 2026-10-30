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

    static func addPhoto(
        image: UIImage,
        client: Client,
        context: ModelContext
    ) {

        guard let fileName = ClientPhotoStorage.saveImage(image) else {
            return
        }

        // 1. Create thumbnail
        if let thumb = ClientPhotoThumbnailGenerator.generate(from: image) {
            ClientPhotoStorage.saveThumbnail(thumb, fileName: fileName)
        }

        let photo = ClientPhoto(
            clientID: client.id,
            fileName: fileName
        )

        client.photos.append(photo)
        context.insert(photo)

        context.saveReportingErrors()
    }

    // MARK: - DELETE PHOTO

    static func deletePhoto(
        photo: ClientPhoto,
        client: Client,
        context: ModelContext
    ) {

        ClientPhotoStorage.deleteImage(at: photo.fileName)

        PhotoThumbnailCache.remove(
            for: photo.fileName
        )

        photo.markDeleted()

        context.saveReportingErrors()
    }
}
