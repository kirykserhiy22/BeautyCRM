//
//  ProfessionManager.swift
//  BeautyCRM
//

import Foundation
import Combine
import SwiftData


// Поточна спеціалізація майстра для всього додатку.
// View беруть значення з `config` і ніколи не перевіряють конкретну професію
// (без `if profession == .nailArtist`).
final class ProfessionManager: ObservableObject {

    @Published private(set) var current: Profession?


    var config: ProfessionConfig {
        current?.config ?? .generic
    }


    func apply(_ profession: Profession?) {
        current = profession
    }


    // Вибір майстра: зберегти в профіль (updatedAt оновить SyncTracking) і застосувати.
    // Одне місце для Налаштувань і екрана для старих акаунтів.
    func choose(
        _ profession: Profession,
        for profile: UserProfile,
        context: ModelContext
    ) {
        profile.profession = profession
        try? context.save()
        apply(profession)
    }


    // Вихід з акаунта
    func reset() {
        current = nil
    }
}
