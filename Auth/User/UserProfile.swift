//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 17.05.26.
//

import Foundation
import SwiftData


@Model
final class UserProfile {

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
    

    // APP
    var createdAt: Date

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
    }
}
