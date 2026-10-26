//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 17.05.26.
//

import Foundation
import SwiftData


@Model
final class UserProfile: SyncTrackable {

    var id: UUID

    // AUTH
    var authUserID: String

    // OWNER
    var firstName: String
    var lastName: String

    // BUSINESS
    var businessName: String?

    // LOCALIZATION

    var currencyCode: String
    var languageCode: String

    // WORK HOURS — хвилини від 00:00; nil = за замовчуванням (9:00–19:00)
    var workStartMinute: Int? = nil
    var workEndMinute: Int? = nil
    

    // APP
    var createdAt: Date

    // MARK: - SYNC

    var workspaceID: UUID? = nil
    var updatedAt: Date? = nil
    var deletedAt: Date? = nil

    init(
        authUserID: String,
        firstName: String,
        lastName: String,
        businessName: String? = nil,
        currencyCode: String,
        languageCode: String
        
    ) {

        self.id = UUID()

        self.authUserID = authUserID

        self.firstName = firstName
        self.lastName = lastName

        self.businessName = businessName

        self.currencyCode = currencyCode
        self.languageCode = languageCode
   

        self.createdAt = Date()

        // Новий користувач одразу отримує власний робочий простір
        self.workspaceID = UUID()
    }
}
