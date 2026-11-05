//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 22.07.26.
//

import Foundation
import Combine


final class CurrencyManager: ObservableObject {


    @Published var currencyCode: String = "EUR"

    // Формат суми йде за мовою додатку, а не телефона (#41)
    @Published private(set) var locale: Locale = .current

    // Один форматер на валюту й мову
    private var formatters: [String: NumberFormatter] = [:]



    func setCurrency(
        _ code: String
    ) {

        currencyCode = code

    }



    func setLocale(
        _ locale: Locale
    ) {

        self.locale = locale

    }



    var symbol: String {

        switch currencyCode {

        case "EUR":
            return "€"

        case "USD":
            return "$"

        case "UAH":
            return "₴"

        case "CZK":
            return "Kč"

        case "PLN":
            return "zł"

        case "GBP":
            return "£"

        default:
            return "€"
        }
    }



    func format(
        _ amount: Decimal
    ) -> String {


        let key = "\(currencyCode)|\(locale.identifier)"

        let formatter = formatters[key] ?? {

            let formatter = NumberFormatter()

            formatter.numberStyle = .currency

            formatter.locale = locale

            formatter.currencyCode = currencyCode

            // Той самий символ у всіх мовах: в українській локалі євро інакше було б «EUR»
            formatter.currencySymbol = symbol

            return formatter
        }()

        formatters[key] = formatter


        return formatter.string(
            from: NSDecimalNumber(decimal: amount)
        )
        ?? "\(amount) \(symbol)"
    }
}
