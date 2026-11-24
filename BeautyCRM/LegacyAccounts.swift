//
//  LegacyAccounts.swift
//  BeautyCRM
//
//  Старі локальні акаунти (до сервера): email і пароль лежали в UserDefaults відкритим текстом (#21).
//
//  1) stripPasswords — при запуску з сервером паролі видаляються; лишається тільки «email → userID»,
//     щоб знайти дані старого акаунта.
//  2) migrate — коли майстер реєструється чи входить на сервер з тим самим email, усі його клієнти,
//     фото, послуги, записи й вихідні переходять до серверного акаунта. Нічого не губиться.
//

import Foundation
import SwiftData

enum LegacyAccounts {

    static let credentialsKey = "local_users"
    static let mapKey = "legacy_accounts"

    // MARK: - PASSWORDS

    static func stripPasswords(defaults: UserDefaults = .standard) {
        guard
            let data = defaults.data(forKey: credentialsKey),
            let users = try? JSONDecoder().decode([AuthCredentials].self, from: data)
        else {
            return
        }
        var map = accounts(defaults: defaults)
        for user in users {
            map[normalized(user.email)] = user.userID
        }
        defaults.set(map, forKey: mapKey)
        defaults.removeObject(forKey: credentialsKey)
    }

    static func accounts(defaults: UserDefaults = .standard) -> [String: String] {
        defaults.dictionary(forKey: mapKey) as? [String: String] ?? [:]
    }

    static func userID(forEmail email: String, defaults: UserDefaults = .standard) -> String? {
        accounts(defaults: defaults)[normalized(email)]
    }

    static func forget(email: String, defaults: UserDefaults = .standard) {
        var map = accounts(defaults: defaults)
        map[normalized(email)] = nil
        defaults.set(map, forKey: mapKey)
    }

    private static func normalized(_ email: String) -> String {
        email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - DATA

    // Дані старого акаунта з тим самим email → до серверного userID.
    // Якщо серверний профіль на телефоні вже є — дані переходять у його робочий простір,
    // старий профіль позначається видаленим. Якщо немає — старий профіль сам стає серверним
    // (разом зі своїм робочим простором, ім'ям, налаштуваннями).
    @discardableResult
    static func migrate(
        email: String,
        to newUserID: String,
        context: ModelContext,
        defaults: UserDefaults = .standard
    ) -> Bool {

        guard let oldUserID = userID(forEmail: email, defaults: defaults), oldUserID != newUserID else {
            return false
        }

        let oldProfile = UserProfileManager.profile(context: context, userID: oldUserID)
        let newProfile = UserProfileManager.profile(context: context, userID: newUserID)

        let workspaceID: UUID?
        if let newProfile {
            workspaceID = newProfile.workspaceID
            oldProfile?.markDeleted()
        } else {
            workspaceID = oldProfile?.workspaceID
            oldProfile?.authUserID = newUserID
        }

        let clients = (try? context.fetch(FetchDescriptor<Client>(predicate: #Predicate { $0.userID == oldUserID }))) ?? []
        let services = (try? context.fetch(FetchDescriptor<Service>(predicate: #Predicate { $0.userID == oldUserID }))) ?? []
        let appointments = (try? context.fetch(FetchDescriptor<Appointment>(predicate: #Predicate { $0.userID == oldUserID }))) ?? []
        let dayOffs = (try? context.fetch(FetchDescriptor<DayOff>(predicate: #Predicate { $0.userID == oldUserID }))) ?? []

        for client in clients {
            client.userID = newUserID
            if let workspaceID {
                client.workspaceID = workspaceID
                client.photos.forEach { $0.workspaceID = workspaceID }
            }
        }
        for service in services {
            service.userID = newUserID
            if let workspaceID { service.workspaceID = workspaceID }
        }
        for appointment in appointments {
            appointment.userID = newUserID
            if let workspaceID { appointment.workspaceID = workspaceID }
        }
        for dayOff in dayOffs {
            dayOff.userID = newUserID
            if let workspaceID { dayOff.workspaceID = workspaceID }
        }

        guard context.saveReportingErrors() else {
            return false
        }
        forget(email: email, defaults: defaults)
        return true
    }
}
