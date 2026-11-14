//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 18.07.26.
//

import Foundation
import Combine


final class LocalizationManager: ObservableObject {


    @Published var languageCode: String


    private let key = "app_language"



    init() {

        // Перший запуск — мова iPhone, якщо вона серед підтримуваних; інакше англійська
        self.languageCode =
            UserDefaults.standard.string(
                forKey: key
            )
            ?? Self.deviceLanguage()
    }



    // Перша мова iPhone з тих, що підтримує додаток («uk-UA» → «uk»); інакше «en»
    static func deviceLanguage(preferred: [String] = Locale.preferredLanguages) -> String {
        let supported = Set(SupportedLanguage.all.map(\.code))
        for identifier in preferred {
            let code = Locale(identifier: identifier).language.languageCode?.identifier
                ?? String(identifier.prefix(2))
            if supported.contains(code) {
                return code
            }
        }
        return "en"
    }

    func setLanguage(
        _ code: String
    ) {

        languageCode = code


        UserDefaults.standard.set(
            code,
            forKey: key
        )
    }



    var locale: Locale {

        Locale(
            identifier: languageCode
        )
    }
    func localizedString(for key: String) -> String {
        let bundlePath = Bundle.main.path(
            forResource: languageCode,
            ofType: "lproj"
        )

        guard
            let bundlePath,
            let languageBundle = Bundle(path: bundlePath)
        else {
            return key
        }

        return languageBundle.localizedString(
            forKey: key,
            value: key,
            table: "Localizable"
        )
    }
}
