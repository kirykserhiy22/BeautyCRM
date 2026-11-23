//
//  ProfessionConfig.swift
//  BeautyCRM
//

import Foundation


// Усе, чим професії відрізняються в інтерфейсі: тексти, іконки, підказки.
// Функціонал однаковий для всіх. Майбутні параметри (аналітика, фічі,
// категорії послуг) додаються сюди новими полями.
struct ProfessionConfig {

    // Ключі Localizable.strings
    let titleKey: String
    let descriptionKey: String
    let examplesKey: String

    // Головна іконка професії (картка вибору, налаштування)
    let icon: ProfessionIcon

    // Іконка «послуг» для цієї професії
    let serviceIcon: ProfessionIcon

    // Ключі назв типових послуг (поки лише дані, без UI)
    let suggestedServiceKeys: [String]

    // Позначки «До/Після» на фото клієнта (для нігтів не потрібні)
    var showsPhotoStages = true

    // Початок ключів текстів-прикладів цієї професії («profession.nail_artist»):
    // підказка в нотатці до візиту, приклад візиту в гіді
    var textKeyPrefix = "profession.generic"

    // «Наприклад: …» у полі нотатки при завершенні запису
    var noteExampleKey: String { textKeyPrefix + ".noteExample" }

    // Приклад візиту в гіді по додатку: послуги й нотатка
    var sampleServicesKey: String { textKeyPrefix + ".sampleServices" }
    var sampleNoteKey: String { textKeyPrefix + ".sampleNote" }


    // Нейтральна конфігурація, коли професію не обрано (іконки як раніше)
    static let generic = ProfessionConfig(
        titleKey: "profession.generic.title",
        descriptionKey: "profession.generic.description",
        examplesKey: "profession.generic.examples",
        icon: .system("sparkles"),
        serviceIcon: .system("scissors"),
        suggestedServiceKeys: []
    )
}
