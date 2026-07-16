//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 17.05.26.
//

import Foundation
import SwiftData


@Model final class UserProfile {
    
    
    var id: UUID
    var authUserID: String
    var currency: String
    var createdAt: Date
    init
        (authUserID: String,currency: String = "₴")
    {
        self.id = UUID()
        self.authUserID = authUserID
        self.currency = currency
        self.createdAt = Date()
    }
}
