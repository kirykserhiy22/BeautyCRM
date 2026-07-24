//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 18.07.26.
//
import Foundation


struct SupportedLanguage: Identifiable {

    let id: String

    let code: String
    let title: String
    let flag: String


    static let all: [SupportedLanguage] = [

        SupportedLanguage(
            id: "en",
            code: "en",
            title: "English",
            flag: "🇬🇧"
        ),

        SupportedLanguage(
            id: "uk",
            code: "uk",
            title: "Українська",
            flag: "🇺🇦"
        ),

        SupportedLanguage(
            id: "de",
            code: "de",
            title: "Deutsch",
            flag: "🇩🇪"
        ),

        SupportedLanguage(
            id: "cs",
            code: "cs",
            title: "Čeština",
            flag: "🇨🇿"
        ),

        SupportedLanguage(
            id: "pl",
            code: "pl",
            title: "Polski",
            flag: "🇵🇱"
        )
    ]
}
