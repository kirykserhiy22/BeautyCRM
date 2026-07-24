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

    let title: String
}
extension SupportedCurrency {

    static let all: [SupportedCurrency] = [

        .init(
            code: "EUR",
            symbol: "€",
            title: "Euro"
        ),

        .init(
            code: "USD",
            symbol: "$",
            title: "US Dollar"
        ),

        .init(
            code: "UAH",
            symbol: "₴",
            title: "Ukrainian Hryvnia"
        ),

        .init(
            code: "PLN",
            symbol: "zł",
            title: "Polish Zloty"
        ),

        .init(
            code: "GBP",
            symbol: "£",
            title: "British Pound"
        ),

        .init(
            code: "CZK",
            symbol: "Kč",
            title: "Czech Koruna"
        )
    ]
}
extension SupportedCurrency {

    static func symbol(for code: String) -> String {

        all.first(where: { $0.code == code })?.symbol ?? code
    }

    static func title(for code: String) -> String {

        all.first(where: { $0.code == code })?.title ?? code
    }
}
