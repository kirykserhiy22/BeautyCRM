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

    // MARK: - ID

    var id: UUID

    // MARK: - OWNER

    var userID: String

    // MARK: - BASIC INFO

    var name: String
    var phone: String?
    var instagram: String?
    var telegram: String?

    // MARK: - PROFILE

    var notes: String?
    var avatarPath: String?

    // MARK: - FLAGS

    var isFavorite: Bool

    // MARK: - RELATIONS

    @Relationship(deleteRule: .cascade)
    var photos: [ClientPhoto] = []

    // MARK: - META

    var createdAt: Date

    // MARK: - INIT

    init(
        userID: String,
        name: String,
        phone: String? = nil,
        instagram: String? = nil,
        telegram: String? = nil,
        notes: String? = nil,
        avatarPath: String? = nil,
        isFavorite: Bool = false
    ) {

        self.id = UUID()

        self.userID = userID

        self.name = name
        self.phone = phone
        self.instagram = instagram
        self.telegram = telegram

        self.notes = notes
        self.avatarPath = avatarPath

        self.isFavorite = isFavorite

        self.createdAt = Date()
    }
}
