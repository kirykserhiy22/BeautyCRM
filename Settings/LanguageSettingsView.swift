//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 18.07.26.
//

import SwiftUI
import SwiftData


struct LanguageSettingsView: View {


    // MARK: - ENV

    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var appState: AppState

    @Environment(\.modelContext)
    private var context


    // MARK: - STATE

    @State private var selectedLanguage: SupportedLanguage?
    @State private var showConfirmation = false



    // MARK: - BODY

    var body: some View {


        List {


            ForEach(
                SupportedLanguage.all
            ) { language in


                Button {


                    guard localization.languageCode != language.code else {
                        return
                    }


                    selectedLanguage = language

                    showConfirmation = true


                } label: {


                    HStack {


                        Text(
                            "\(language.flag) \(language.title)"
                        )


                        Spacer()



                        if localization.languageCode == language.code {


                            Image(
                                systemName: "checkmark"
                            )
                            .foregroundColor(.blue)

                        }
                    }
                }
            }
        }


        .navigationTitle("Language")


        .alert(
            "Change language?",
            isPresented: $showConfirmation
        ) {


            Button(
                "Cancel",
                role: .cancel
            ) { }


            Button(
                "Change"
            ) {

                applyLanguageChange()

            }


        } message: {


            if let language = selectedLanguage {

                Text(
                    "The application language will be changed to \(language.title)."
                )
            }
        }
    }
}



// MARK: - LOGIC

private extension LanguageSettingsView {


    func applyLanguageChange() {


        guard let language = selectedLanguage else {
            return
        }



        let code = language.code



        // 1. Change current app language

        localization.setLanguage(
            code
        )



        // 2. Save language into UserProfile


        guard let userID = appState.session.userID else {
            return
        }



        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate {
                $0.authUserID == userID
            }
        )



        guard let profile =
                try? context.fetch(descriptor).first
        else {
            return
        }



        profile.languageCode = code



        do {

            try context.save()

            print(
                "LANGUAGE SAVED:",
                code
            )

        }
        catch {

            print(
                "LANGUAGE SAVE ERROR:",
                error
            )
        }
    }
}
