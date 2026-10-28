//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 16.07.26.
//

import Foundation
import Combine


// Кроки реєстрації в порядку показу.
// Прогрес «Крок X з N» береться звідси, тож новий крок — це лише новий case.
enum SignUpStep: Int, CaseIterable {

    case account
    case profile
    case profession
    case business
    case currency


    // Номер для людини: 1, 2, 3…
    var number: Int {
        rawValue + 1
    }

    var isLast: Bool {
        self == Self.allCases.last
    }

    var next: SignUpStep? {
        SignUpStep(rawValue: rawValue + 1)
    }

    var previous: SignUpStep? {
        SignUpStep(rawValue: rawValue - 1)
    }
}


// Дані й логіка реєстрації. View лише показують поля і викликають
// goNext() / goBack(), тож під час редизайну міняються тільки View.
final class SignUpState: ObservableObject {

    // MARK: - Account

    @Published var email = ""
    @Published var password = ""

    // MARK: - Profile

    @Published var firstName = ""
    @Published var lastName = ""

    // MARK: - Profession

    @Published var profession: Profession?

    // MARK: - Business

    @Published var businessName = ""

    // MARK: - Preferences

    // CURRENCY

    @Published var currencyCode = "EUR"


    // MARK: - UI State

    @Published var step: SignUpStep = .account

    // Ключ Localizable.strings; порожній — помилки немає
    @Published var errorMessage = ""

    @Published var isLoading = false


    // MARK: - Navigation

    // Перевіряє поточний крок і переходить далі.
    // Повертає true, коли це був останній крок і можна створювати акаунт.
    func goNext() -> Bool {

        errorMessage = ""

        if let error = validationErrorKey(for: step) {
            errorMessage = error
            return false
        }

        guard let next = step.next else {
            return true
        }

        step = next
        return false
    }


    // Повертає false, якщо це перший крок (тоді треба вийти з реєстрації)
    func goBack() -> Bool {

        errorMessage = ""

        guard let previous = step.previous else {
            return false
        }

        step = previous
        return true
    }


    // MARK: - Validation

    // Один вичерпний switch: новий крок не скомпілюється без своєї перевірки
    func validationErrorKey(for step: SignUpStep) -> String? {

        switch step {

        case .account:

            guard AuthValidator.validateEmail(email) else {
                return "signup.error.email"
            }

            guard AuthValidator.validatePassword(password) else {
                return "signup.error.password"
            }

            guard !LocalAuthService().isEmailRegistered(email) else {
                return AuthError.userAlreadyExists.localizationKey
            }

            return nil


        case .profile:

            guard AuthValidator.validateName(firstName) else {
                return "signup.error.firstName"
            }

            guard AuthValidator.validateName(lastName) else {
                return "signup.error.lastName"
            }

            return nil


        case .profession:

            return profession == nil ? "signup.error.profession" : nil


        case .business, .currency:

            return nil
        }
    }


    func reset() {

        email = ""
        password = ""

        firstName = ""
        lastName = ""

        profession = nil

        businessName = ""

        currencyCode = "EUR"

        step = .account

        errorMessage = ""

        isLoading = false
    }
}
