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
    
    // MARK: - DUPLICATES

    // Можливий дублікат — клієнт з тим самим ім'ям (без різниці у великих
    // літерах, пробілах і наголосах), і при цьому:
    //   • хоч один контакт збігається (телефон, Instagram або Telegram) — той самий;
    //   • контакт одного типу є в обох, але різний — різні люди, не дублікат;
    //   • спільних контактів немає — розрізнити неможливо, тож «можливо той самий».
    static func possibleDuplicate(
        name: String,
        phone: String?,
        instagram: String?,
        telegram: String?,
        userID: String,
        excluding clientID: UUID? = nil,
        context: ModelContext
    ) throws -> Client? {

        let normalizedName = normalized(name)
        let contacts = Contacts(phone: phone, instagram: instagram, telegram: telegram)

        let descriptor = FetchDescriptor<Client>(
            predicate: #Predicate { client in
                client.userID == userID &&
                client.deletedAt == nil
            }
        )

        return try context.fetch(descriptor).first { client in

            guard client.id != clientID, normalized(client.name) == normalizedName else {
                return false
            }

            let existing = Contacts(phone: client.phone, instagram: client.instagram, telegram: client.telegram)

            return contacts.mayBeSamePerson(as: existing)
        }
    }

    static func normalized(_ name: String) -> String {
        name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }


    // Контакти клієнта у вигляді для порівняння
    private struct Contacts {

        let values: [String]   // телефон, Instagram, Telegram; "" — немає

        init(phone: String?, instagram: String?, telegram: String?) {
            values = [
                (phone ?? "").filter(\.isNumber),
                Self.handle(instagram, site: "instagram.com/"),
                Self.handle(telegram, site: "t.me/")
            ]
        }

        func mayBeSamePerson(as other: Contacts) -> Bool {

            let pairs = zip(values, other.values).filter { !$0.isEmpty && !$1.isEmpty }

            if pairs.contains(where: { $0 == $1 }) {
                return true    // спільний контакт — той самий клієнт
            }

            return pairs.isEmpty    // є різні контакти — різні люди
        }

        // "@Anna.Nails", "anna.nails", "https://instagram.com/anna.nails/" → "anna.nails"
        private static func handle(_ text: String?, site: String) -> String {
            var value = (text ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

            if let range = value.range(of: site) {
                value = String(value[range.upperBound...])
            }

            return value
                .trimmingCharacters(in: CharacterSet(charactersIn: "@/"))
        }
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
