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
