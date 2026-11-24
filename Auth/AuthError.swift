//
//  Untitled 2.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 16.07.26.
//

import Foundation


enum AuthError: Error {


    case emptyEmail

    case invalidEmail

    case weakPassword

    case userAlreadyExists

    case userNotFound

    case wrongPassword

    // Сервер (Supabase)
    case emailNotConfirmed
    case invalidCode
    case tooManyRequests
    case noConnection
    case serverError
    case samePassword
    case passwordsDontMatch



    // Ключ з Localizable.strings — текст перекладається на мову додатку
    var localizationKey: String {


        switch self {


        case .emptyEmail:

            return "auth.error.emptyEmail"



        case .invalidEmail:

            return "auth.error.invalidEmail"



        case .weakPassword:

            return "auth.error.weakPassword"



        case .userAlreadyExists:

            return "auth.error.userAlreadyExists"



        case .userNotFound:

            return "auth.error.userNotFound"



        case .wrongPassword:

            return "auth.error.wrongPassword"

        case .emailNotConfirmed:
            return "auth.error.emailNotConfirmed"

        case .invalidCode:
            return "auth.error.invalidCode"

        case .tooManyRequests:
            return "auth.error.tooManyRequests"

        case .noConnection:
            return "auth.error.noConnection"

        case .serverError:
            return "auth.error.serverError"

        case .samePassword:
            return "auth.error.samePassword"

        case .passwordsDontMatch:
            return "auth.error.passwordsDontMatch"
        }
    }
}
