//
//  Untitled 2.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 16.07.26.
//

import Foundation


final class AuthValidator {


    static func validateEmail(
        _ email: String
    ) -> Bool {

        let trimmed = email.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let regex =
        "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"


        return NSPredicate(
            format: "SELF MATCHES %@",
            regex
        )
        .evaluate(with: trimmed)
    }



    static func validatePassword(
        _ password: String
    ) -> Bool {

        password.count >= 8
    }



    static func validateName(
        _ name: String
    ) -> Bool {

        !name
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty
    }
}
