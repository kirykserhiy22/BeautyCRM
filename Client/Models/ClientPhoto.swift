//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 23.05.26.
//
import Foundation
import SwiftData

@Model
final class ClientPhoto: SyncTrackable {

    var id: UUID

    var clientID: UUID

    /// local file name (НЕ full path)
    var fileName: String

    var createdAt: Date

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
