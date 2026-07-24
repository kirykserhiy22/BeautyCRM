//
//  Untitled 2.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 22.07.26.
//

import Foundation
import SwiftData


enum UserProfileLoader {


    @discardableResult
    static func load(
        context: ModelContext,
        userID: String,
        localization: LocalizationManager,
        currency: CurrencyManager
    ) -> UserProfile? {


        let descriptor =
        FetchDescriptor<UserProfile>(
            predicate: #Predicate {
                $0.authUserID == userID
            }
        )


        guard let profile =
                try? context.fetch(descriptor).first
        else {
            return nil
        }



        localization.setLanguage(
            profile.languageCode
        )


        currency.setCurrency(
            profile.currencyCode
        )


        print(
            "PROFILE LOADED:",
            profile.languageCode,
            profile.currencyCode
        )


        return profile
    }
}
