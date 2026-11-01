//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 23.05.26.
//
import SwiftUI
import UIKit

final class ClientPhotoStorage {

    // MARK: - SAVE IMAGE

    nonisolated static func saveImage(_ image: UIImage) -> String? {

        guard let data = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }

        let filename = "\(UUID().uuidString).jpg"

        let folderURL = photosFolderURL()

        // create folder if needed
        if !FileManager.default.fileExists(atPath: folderURL.path) {

            try? FileManager.default.createDirectory(
                at: folderURL,
                withIntermediateDirectories: true
            )
        }

        let fileURL = folderURL.appendingPathComponent(filename)

        do {

            try data.write(to: fileURL)

            return filename

        } catch {
            // Не вдалося записати файл — фото просто не додасться
            return nil
        }
    }

    // MARK: - LOAD IMAGE

    static func loadImage(
        from path: String
    ) -> UIImage? {

        if let cached =
            PhotoThumbnailCache.image(
                for: path
            ) {

            return cached
        }

        let fileURL = photosFolderURL()
            .appendingPathComponent(path)

        guard let image =
            UIImage(
                contentsOfFile: fileURL.path
            )
        else {
            return nil
        }

        PhotoThumbnailCache.save(
            image: image,
            for: path
        )

        return image
    }

    // MARK: - DELETE IMAGE

    // Прибирає повне фото, мініатюру і обидва кеші в пам'яті (#38)
    static func deleteImage(at path: String) {

        for folder in [photosFolderURL(), thumbnailsFolderURL()] {
            // Файлу вже немає — нічого робити не треба
            try? FileManager.default.removeItem(at: folder.appendingPathComponent(path))
        }

        PhotoThumbnailCache.remove(for: path)
        PhotoMemoryCache.shared.remove(for: path)
    }

    // MARK: - Новий шлях для thumbnails
    nonisolated private static func thumbnailsFolderURL() -> URL {
        FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        .appendingPathComponent("client_photos_thumbs")
    }
    
    nonisolated static func saveThumbnail(
        _ image: UIImage,
        fileName: String
    ) {

        guard let data = image.jpegData(compressionQuality: 0.7) else {
            return
        }

        let folderURL = thumbnailsFolderURL()

        if !FileManager.default.fileExists(atPath: folderURL.path) {
            try? FileManager.default.createDirectory(
                at: folderURL,
                withIntermediateDirectories: true
            )
        }

        let fileURL = folderURL.appendingPathComponent(fileName)

        try? data.write(to: fileURL)
    }
    
    static func loadThumbnail(from path: String) -> UIImage? {

        let fileURL = thumbnailsFolderURL()
            .appendingPathComponent(path)

        return UIImage(contentsOfFile: fileURL.path)
    }
    
    // MARK: - FOLDER URL

    nonisolated private static func photosFolderURL() -> URL {

        FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        .appendingPathComponent("client_photos")
    }
}
