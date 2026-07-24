//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 30.05.26.
//

import UIKit

enum PhotoRenderService {

    static func loadThumbnailAsync(
        fileName: String
    ) async -> UIImage? {

        // 1. memory cache first
        if let cached = PhotoMemoryCache.shared.image(for: fileName) {
            return cached
        }

        // 2. disk thumbnail
        if let thumb = ClientPhotoStorage.loadThumbnail(from: fileName) {
            PhotoMemoryCache.shared.set(thumb, for: fileName)
            return thumb
        }

        // 3. fallback full image (rare case)
        guard let full = ClientPhotoStorage.loadImage(from: fileName) else {
            return nil
        }

        let resized = ClientPhotoThumbnailGenerator.generate(from: full)

        if let resized {
            PhotoMemoryCache.shared.set(resized, for: fileName)
            ClientPhotoStorage.saveThumbnail(resized, fileName: fileName)
            return resized
        }

        return full
    }
}
