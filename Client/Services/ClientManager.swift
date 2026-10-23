//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 03.05.26.
//

import Foundation
import SwiftData

final class ClientManager {
    
    static func createClient(
        name: String,
        phone: String?,
        instagram: String?,
        userID: String,
        context: ModelContext
    ) {
        let client = Client(
            userID: userID,
            name: name,
            phone: phone,
            instagram: instagram
        )
        
        context.insert(client)
    }
    
    // Позначає клієнта і всі його фото як видалені.
    // Файли фото прибираємо одразу — на екрані вони вже не потрібні.
    static func delete(client: Client, context: ModelContext) {

        for photo in client.photos where photo.deletedAt == nil {
            ClientPhotoStorage.deleteImage(at: photo.fileName)
            PhotoThumbnailCache.remove(for: photo.fileName)
            photo.markDeleted()
        }

        client.markDeleted()
    }
}
