//
//  ContactLinks.swift
//  BeautyCRM
//
//  Посилання на контакти клієнта. Майстер пише нік як завгодно («@nick»,
//  «instagram.com/nick»), а посилання збирається тільки з чистого ніка (#46).
//

import Foundation


enum ContactLinks {

    static func phone(_ text: String) -> URL? {
        let digits = text.filter { $0.isASCII && ($0.isNumber || $0 == "+") }
        guard digits.contains(where: \.isNumber) else {
            return nil
        }
        return URL(string: "tel:\(digits)")
    }

    static func instagram(_ text: String) -> URL? {
        nick(from: text, sites: ["instagram.com/"]).flatMap {
            URL(string: "https://instagram.com/\($0)")
        }
    }

    static func telegram(_ text: String) -> URL? {
        nick(from: text, sites: ["t.me/", "telegram.me/"]).flatMap {
            URL(string: "https://t.me/\($0)")
        }
    }


    // Чистий нік або nil, якщо такого ніка не може бути (пробіли, кирилиця)
    private static func nick(from text: String, sites: [String]) -> String? {

        var value = text.trimmingCharacters(in: .whitespacesAndNewlines)

        for site in sites {
            if let range = value.range(of: site, options: .caseInsensitive) {
                value = String(value[range.upperBound...])
            }
        }

        // Хвіст посилання: «nick/?igsh=abc»
        value = value.components(separatedBy: CharacterSet(charactersIn: "?#")).first ?? ""
        value = value.trimmingCharacters(in: CharacterSet(charactersIn: "@/"))

        let isValid = !value.isEmpty && value.allSatisfy {
            $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "." || $0 == "_")
        }

        return isValid ? value : nil
    }
}
