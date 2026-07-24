//
//  Untitled 2.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 16.07.26.
//

import Foundation


enum AuthResult {

    case success(userID: String)

    case failure(AuthError)



    var isSuccess: Bool {

        switch self {

        case .success:
            return true

        case .failure:
            return false
        }
    }



    var userID: String? {

        switch self {

        case .success(let userID):
            return userID

        case .failure:
            return nil
        }
    }



    var error: AuthError? {

        switch self {

        case .success:
            return nil

        case .failure(let error):
            return error
        }
    }
}
