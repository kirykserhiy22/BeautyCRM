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


        try? context.save()
    }



    static func update(
        profile: UserProfile,
        firstName: String,
        lastName: String,
        businessName: String?,
        currencyCode: String,
        languageCode: String,
        context: ModelContext
    ) {


        profile.firstName = firstName
        profile.lastName = lastName
        profile.businessName = businessName

        profile.currencyCode = currencyCode

        profile.languageCode = languageCode

       



        try? context.save()
    }
}
