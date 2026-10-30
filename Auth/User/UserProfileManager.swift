//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 30.04.26.
//
import Foundation
import SwiftData


final class UserProfileManager {


    static func profile(
        context: ModelContext,
        userID: String
    ) -> UserProfile? {


        let descriptor =
        FetchDescriptor<UserProfile>(
            predicate: #Predicate {
                $0.authUserID == userID
            }
        )


        return try? context.fetch(descriptor).first
    }



    static func create(
        context: ModelContext,
        userID: String,
        firstName: String,
        lastName: String,
        businessName: String?,
        currencyCode: String,
        languageCode: String
    ) {


        guard profile(
            context: context,
            userID: userID
        ) == nil else {

            return
        }



        let profile = UserProfile(
            authUserID: userID,
            firstName: firstName,
            lastName: lastName,
            businessName: businessName,
            currencyCode: currencyCode,
            languageCode: languageCode,
            
        )



        context.insert(profile)


        context.saveReportingErrors()
    }



    // Перевірка полів профілю: ключ Localizable.strings або nil, якщо все гаразд
    static func validationErrorKey(
        firstName: String,
        lastName: String
    ) -> String? {

        guard AuthValidator.validateName(firstName) else {
            return "signup.error.firstName"
        }

        guard AuthValidator.validateName(lastName) else {
            return "signup.error.lastName"
        }

        return nil
    }


    // Зміна профілю з екрана «Профіль». Пробіли по краях обрізаються,
    // порожня назва салону зберігається як «немає».
    // Повертає true, коли збережено.
    @discardableResult
    static func update(
        profile: UserProfile,
        firstName: String,
        lastName: String,
        businessName: String,
        currencyCode: String,
        context: ModelContext
    ) -> Bool {

        let business = businessName.trimmingCharacters(in: .whitespacesAndNewlines)

        profile.firstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.lastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.businessName = business.isEmpty ? nil : business
        profile.currencyCode = currencyCode

        return context.saveReportingErrors()
    }
}
