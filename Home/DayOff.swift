//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 17.05.26.
//
import Foundation
import SwiftData

@Model
final class DayOff: SyncTrackable {

    var id: UUID

    var userID: String

    var date: Date

    var createdAt: Date

    // MARK: - SYNC

    var workspaceID: UUID? = nil
    var updatedAt: Date? = nil
    var deletedAt: Date? = nil

    init(
        userID: String,
        date: Date
    ) {

        self.id = UUID()
        self.userID = userID
        self.date = Calendar.current.startOfDay(for: date)
        self.createdAt = Date()
    }
}
