//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 30.04.26.
//
import Foundation
import SwiftData

@Model
final class Client {
    
    var id: UUID
    
    // OWNER
    var userID: String
    
    // BASIC INFO
    var name: String
    var phone: String?
    var instagram: String?
    
    // META
    var createdAt: Date
    
    // INIT
    init(
        userID: String,
        name: String,
        phone: String? = nil,
        instagram: String? = nil
    ) {
        self.id = UUID()
        self.userID = userID
        self.name = name
        self.phone = phone
        self.instagram = instagram
        self.createdAt = Date()
    }
}
