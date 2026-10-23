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

        self.languageCode =
            UserDefaults.standard.string(
                forKey: key
            )
            ?? "en"
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
