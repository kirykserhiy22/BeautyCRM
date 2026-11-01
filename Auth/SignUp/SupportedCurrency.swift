//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 16.07.26.
//
import Foundation
import SwiftData

struct SupportedCurrency: Identifiable {

    let id = UUID()

    let code: String

    let symbol: String

    // Назва валюти — ключ `currency.<code>` у Localizable.strings
}
extension SupportedCurrency {

    static let all: [SupportedCurrency] = [

        .init(
            code: "EUR",
            symbol: "€"
        ),

        .init(
            code: "USD",
            symbol: "$"
        ),

        .init(
            code: "UAH",
            symbol: "₴"
        ),

        .init(
            code: "PLN",
            symbol: "zł"
        ),

        .init(
            code: "GBP",
            symbol: "£"
        ),

        .init(
            code: "CZK",
            symbol: "Kč"
        )
    ]
}
extension SupportedCurrency {

    static func symbol(for code: String) -> String {

        all.first(where: { $0.code == code })?.symbol ?? code
    }
}
