//
//  Untitled 2.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 16.07.26.
//

import Foundation


enum AuthValidationError: LocalizedError {

    case emptyEmail
    case invalidEmail
    case weakPassword
    case emptyName


    var errorDescription: String? {

        switch self {

        case .emptyEmail:
            return "Email is required"


        case .invalidEmail:
            return "Enter a valid email"


        case .weakPassword:
            return "Password must contain at least 8 characters and a number"


        case .emptyName:
            return "Name is required"
        }
    }
}



