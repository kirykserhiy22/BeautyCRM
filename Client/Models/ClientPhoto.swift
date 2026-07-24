//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 23.05.26.
//
import Foundation
import SwiftData

@Model
final class ClientPhoto {

    var id: UUID

    var clientID: UUID

    /// local file name (НЕ full path)
    var fileName: String

    var createdAt: Date

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
