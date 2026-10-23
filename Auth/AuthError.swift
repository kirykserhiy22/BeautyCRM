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
        }
    }
}
