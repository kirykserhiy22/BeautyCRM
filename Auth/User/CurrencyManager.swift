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



    func setCurrency(
        _ code: String
    ) {

        currencyCode = code

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


        let formatter = NumberFormatter()

        formatter.numberStyle = .currency

        formatter.currencyCode = currencyCode

        formatter.locale =
        Locale(identifier: Locale.current.identifier)



        return formatter.string(
            from: NSDecimalNumber(decimal: amount)
        )
        ?? "\(amount) \(symbol)"
    }
}
