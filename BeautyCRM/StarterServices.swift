//
//  StarterServices.swift
//  BeautyCRM
//
//  Новий майстер одразу бачить прайс зі стандартних послуг своєї спеціалізації:
//  «Стрижка», «Фарбування»… Ціна не вказана (змінна — вводиться при записі),
//  бо в Празі й у Львові вона різна. Будь-яку послугу можна змінити чи видалити.
//

import Foundation
import SwiftData


enum StarterServices {

    // Створює послуги лише тоді, коли в майстра ще немає жодної (повторний вхід нічого не дублює).
    // Повертає, скільки послуг створено.
    @discardableResult
    static func createIfNeeded(
        userID: String,
        profession: Profession?,
        context: ModelContext,
        localized: (String) -> String
    ) -> Int {

        guard let profession else {
            return 0
        }

        let existing = (try? context.fetch(
            FetchDescriptor<Service>(predicate: #Predicate { $0.userID == userID && $0.deletedAt == nil })
        )) ?? []

        guard existing.isEmpty else {
            return 0
        }

        let names = profession.config.suggestedServiceKeys.map(localized)
        for name in names {
            context.insert(Service(userID: userID, name: name, pricingType: .variable))
        }
        context.saveReportingErrors()
        return names.count
    }
}
