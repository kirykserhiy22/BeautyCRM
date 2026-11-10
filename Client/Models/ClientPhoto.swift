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
