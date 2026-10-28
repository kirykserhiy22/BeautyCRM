//
//  Profession.swift
//  BeautyCRM
//

import Foundation


// Спеціалізація майстра.
// rawValue зберігається в базі (а пізніше і на сервері) — НІКОЛИ його не міняти.
// Перейменовувати можна тільки case.
enum Profession: String, CaseIterable, Identifiable, Codable {

    case hairStylist = "hair_stylist"
    case nailArtist = "nail_artist"
    case lashBrowArtist = "lash_brow_artist"


    var id: String {
        rawValue
    }


    // Один вичерпний switch без default: нова професія не скомпілюється,
    // поки для неї не задано конфігурацію.
    var config: ProfessionConfig {

        switch self {

        case .hairStylist:

            return ProfessionConfig(
                titleKey: "profession.hair_stylist.title",
                descriptionKey: "profession.hair_stylist.description",
                examplesKey: "profession.hair_stylist.examples",
                icon: .system("scissors"),
                serviceIcon: .system("scissors"),
                suggestedServiceKeys: [
                    "service.suggestion.haircut",
                    "service.suggestion.coloring",
                    "service.suggestion.highlights",
                    "service.suggestion.styling",
                    "service.suggestion.keratin"
                ]
            )


        case .nailArtist:

            return ProfessionConfig(
                titleKey: "profession.nail_artist.title",
                descriptionKey: "profession.nail_artist.description",
                examplesKey: "profession.nail_artist.examples",
                icon: .system("hand.raised.fingers.spread"),
                serviceIcon: .system("paintbrush.pointed"),
                suggestedServiceKeys: [
                    "service.suggestion.manicure",
                    "service.suggestion.pedicure",
                    "service.suggestion.gelPolish",
                    "service.suggestion.nailExtensions",
                    "service.suggestion.nailDesign"
                ]
            )


        case .lashBrowArtist:

            return ProfessionConfig(
                titleKey: "profession.lash_brow_artist.title",
                descriptionKey: "profession.lash_brow_artist.description",
                examplesKey: "profession.lash_brow_artist.examples",
                icon: .system("eyebrow"),
                serviceIcon: .system("eyebrow"),
                suggestedServiceKeys: [
                    "service.suggestion.lashExtensions",
                    "service.suggestion.lashLift",
                    "service.suggestion.browShaping",
                    "service.suggestion.browTint",
                    "service.suggestion.browLamination"
                ]
            )
        }
    }
}
