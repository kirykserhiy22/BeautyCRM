//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 21.10.26.
//


import Foundation

enum CountFormatting {

    static func visits(_ count: Int, locale: Locale) -> String {
        noun(
            count,
            locale: locale,
            english: ("visit", "visits"),
            german: ("Besuch", "Besuche"),
            ukrainian: ("відвідування", "відвідування", "відвідувань"),
            polish: ("wizyta", "wizyty", "wizyt"),
            czech: ("návštěva", "návštěvy", "návštěv")
        )
    }

    static func appointments(_ count: Int, locale: Locale) -> String {
        noun(
            count,
            locale: locale,
            english: ("appointment", "appointments"),
            german: ("Termin", "Termine"),
            ukrainian: ("запис", "записи", "записів"),
            polish: ("wizyta", "wizyty", "wizyt"),
            czech: ("rezervace", "rezervace", "rezervací")
        )
    }

    private static func noun(
        _ count: Int,
        locale: Locale,
        english: (String, String),
        german: (String, String),
        ukrainian: (String, String, String),
        polish: (String, String, String),
        czech: (String, String, String)
    ) -> String {
        let language = locale.language.languageCode?.identifier ?? "en"
        let n = abs(count)
        let lastTwo = n % 100
        let last = n % 10

        let word: String

        switch language {
        case "uk":
            if last == 1 && lastTwo != 11 {
                word = ukrainian.0
            } else if (2...4).contains(last) && !(12...14).contains(lastTwo) {
                word = ukrainian.1
            } else {
                word = ukrainian.2
            }

        case "pl":
            if n == 1 {
                word = polish.0
            } else if (2...4).contains(last) && !(12...14).contains(lastTwo) {
                word = polish.1
            } else {
                word = polish.2
            }

        case "cs":
            if n == 1 {
                word = czech.0
            } else if (2...4).contains(n) {
                word = czech.1
            } else {
                word = czech.2
            }

        case "de":
            word = n == 1 ? german.0 : german.1

        default:
            word = n == 1 ? english.0 : english.1
        }

        return "\(count) \(word)"
    }
}
