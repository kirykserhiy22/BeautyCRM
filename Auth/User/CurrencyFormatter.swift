//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 22.07.26.
//

import Foundation


struct CurrencyFormatter {


    static func string(
        amount: Decimal,
        currencyCode: String
    ) -> String {


        let formatter = NumberFormatter()

        formatter.numberStyle = .currency

        formatter.currencyCode = currencyCode

        formatter.locale =
        Locale.current


        return formatter.string(
            from: NSDecimalNumber(decimal: amount)
        )
        ?? "\(amount)"
    }
}
