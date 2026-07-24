//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 16.07.26.
//

import Foundation
import Combine

final class SignUpState: ObservableObject {

    // MARK: - Account

    @Published var email = ""
    @Published var password = ""

    // MARK: - Profile

    @Published var firstName = ""
    @Published var lastName = ""

    // MARK: - Business

    @Published var businessName = ""

    // MARK: - Preferences




    // CURRENCY

    @Published var currencyCode = "EUR"


    // MARK: - UI State

    @Published var currentStep = 0

    @Published var errorMessage = ""

    @Published var isLoading = false

    func reset() {

        email = ""
        password = ""

        firstName = ""
        lastName = ""

        businessName = ""

       
        currencyCode = "EUR"

        currentStep = 0

        errorMessage = ""

        isLoading = false
    }
}
