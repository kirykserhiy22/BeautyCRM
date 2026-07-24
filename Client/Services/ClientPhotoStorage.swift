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

    static func saveImage(_ image: UIImage) -> String? {

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

            print("Save image error:", error)
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

    static func deleteImage(at path: String) {

        let fileURL = photosFolderURL()
            .appendingPathComponent(path)

        do {

            try FileManager.default.removeItem(at: fileURL)

        } catch {

            print("Delete image error:", error)
        }
    }

    // MARK: - Новий шлях для thumbnails
    private static func thumbnailsFolderURL() -> URL {
        FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        .appendingPathComponent("client_photos_thumbs")
    }
    
    static func saveThumbnail(
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
    
    static func getOptimizedImage(from path: String) -> UIImage? {

        // 1. try thumbnail first
        if let thumb = loadThumbnail(from: path) {
            return thumb
        }

        // 2. fallback full image
        guard let full = loadImage(from: path) else {
            return nil
        }

        // 3. async generate thumbnail (optional optimization later)
        DispatchQueue.global(qos: .utility).async {
            let thumb = ClientPhotoThumbnailGenerator.generate(from: full)
            if let thumb {
                saveThumbnail(thumb, fileName: path)
            }
        }

        return full
    }
    // MARK: - FOLDER URL

    private static func photosFolderURL() -> URL {

        FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        .appendingPathComponent("client_photos")
    }
}
