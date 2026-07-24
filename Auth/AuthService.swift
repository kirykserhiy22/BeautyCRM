//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 30.04.26.
//
import Foundation

final class AuthService {
    
    func mockLogin(email: String) -> AuthUser {
        return AuthUser(id: UUID().uuidString, email: email)
    }
}
