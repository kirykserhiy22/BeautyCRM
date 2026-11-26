//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 23.05.26.
//
import Foundation
import SwiftData

// Позначка фото: стан до або після роботи майстра
enum ClientPhotoStage: String, CaseIterable {
    case before
    case after

    var localizationKey: String {
        switch self {
        case .before: return "clients.photo.before"
        case .after: return "clients.photo.after"
        }
    }
}

// Вид фото: готова робота майстра (основна галерея) чи референс — фото бажаного результату від клієнта
enum ClientPhotoKind: String, CaseIterable, Identifiable {
    case work
    case reference

    var id: String { rawValue }
    var titleKey: String { "photos.kind.\(rawValue)" }
}

@Model
final class ClientPhoto: SyncTrackable {

    var id: UUID

    var clientID: UUID

    /// local file name (НЕ full path)
    var fileName: String

    var createdAt: Date

    // Необов'язкові підпис і позначка «До/Після»
    var caption: String? = nil
    var stageRaw: String? = nil

    // Кілька фото, додані «одним дописом», мають спільний postID (як допис-карусель в Instagram).
    // nil — фото окремим дописом
    var postID: UUID? = nil

    // nil — робота (усі старі фото); "reference" — референс від клієнта
    var kindRaw: String? = nil

    // Запис, до якого клієнт надіслав референс (nil — додано просто в профіль)
    var appointmentID: UUID? = nil

    var kind: ClientPhotoKind {
        get { kindRaw.flatMap(ClientPhotoKind.init(rawValue:)) ?? .work }
        set { kindRaw = newValue == .work ? nil : newValue.rawValue }
    }

    var stage: ClientPhotoStage? {
        get { stageRaw.flatMap(ClientPhotoStage.init(rawValue:)) }
        set { stageRaw = newValue?.rawValue }
    }

    // MARK: - SYNC

    var workspaceID: UUID? = nil
    var updatedAt: Date? = nil
    var deletedAt: Date? = nil

    init(
        clientID: UUID,
        fileName: String
    ) {
        self.id = UUID()
        self.clientID = clientID
        self.fileName = fileName
        self.createdAt = Date()
    }
}
