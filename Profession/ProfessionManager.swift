//
//  ProfessionManager.swift
//  BeautyCRM
//

import Foundation
import Combine


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


    // Вихід з акаунта
    func reset() {
        current = nil
    }
}
