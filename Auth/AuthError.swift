//
//  Untitled 2.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 16.07.26.
//

import Foundation


enum AuthError: LocalizedError {


    case emptyEmail

    case invalidEmail

    case weakPassword

    case userAlreadyExists

    case userNotFound

    case wrongPassword



    var errorDescription: String? {


        switch self {


        case .emptyEmail:

            return "Email cannot be empty"



        case .invalidEmail:

            return "Invalid email format"



        case .weakPassword:

            return "Password must contain at least 8 characters"



        case .userAlreadyExists:

            return "User already exists"



        case .userNotFound:

            return "User not found"



        case .wrongPassword:

            return "Wrong password"
        }
    }
}
