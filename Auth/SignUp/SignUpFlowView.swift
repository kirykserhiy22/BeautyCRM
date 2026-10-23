//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 16.07.26.
//

import SwiftUI
import SwiftData


struct SignUpFlowView: View {


    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localization: LocalizationManager

    @Environment(\.modelContext)
    private var context


    @StateObject private var state =
    SignUpState()


    @State private var step = 0
    @State private var errorMessage = ""



    var body: some View {


        VStack {


            progress



            Spacer()



            switch step {


            case 0:

                SignUpAccountStep(
                    state: state
                )


            case 1:

                SignUpProfileStep(
                    state: state
                )


            case 2:

                SignUpBusinessStep(
                    state: state
                )


            case 3:

                SignUpCurrencyStep(
                    state: state
                )


            default:

                EmptyView()

            }



            Spacer()
            if !errorMessage.isEmpty {

                Text(LocalizedStringKey(errorMessage))
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }



            navigationButtons

        }
        .padding()
    }
}



private extension SignUpFlowView {


    var progress: some View {
        VStack {
            Text("signup.title")
                .font(.largeTitle.bold())

            HStack(spacing: 4) {
                Text("signup.step")
                Text("\(step + 1)")
                Text("signup.ofFour")
            }
            .foregroundColor(.secondary)
        }
    }



    var navigationButtons: some View {
        HStack {
            Button("signup.back") {
                goBack()
            }

            Spacer()

            Button(
                step == 3
                    ? "signup.createAccount"
                    : "signup.next"
            ) {
                nextStep()
            }
            .buttonStyle(.borderedProminent)
        }
    }


    // На першому кроці «Назад» веде на стартовий екран (вибір: створити акаунт чи увійти)
    func goBack() {

        errorMessage = ""

        if step > 0 {
            step -= 1
        } else {
            router.currentScreen = .welcome
        }
    }


    func nextStep() {

        errorMessage = ""

        switch step {

        case 0:

            guard AuthValidator.validateEmail(state.email) else {
                errorMessage = "signup.error.email"
                return
            }

            guard AuthValidator.validatePassword(state.password) else {
                errorMessage = "signup.error.password"
                return
            }

            guard !LocalAuthService().isEmailRegistered(state.email) else {
                errorMessage = AuthError.userAlreadyExists.localizationKey
                return
            }

            step += 1

        case 1:

            guard AuthValidator.validateName(state.firstName) else {
                errorMessage = "signup.error.firstName"
                return
            }

            guard AuthValidator.validateName(state.lastName) else {
                errorMessage = "signup.error.lastName"
                return
            }

            step += 1

        case 2:

            
            step += 1

        case 3:

            
            finishRegistration()

        default:
            break
        }
    }
    func finishRegistration() {


        let authService = LocalAuthService()


        let result = authService.signUp(
            email: state.email,
            password: state.password
        )



        switch result {


        case .success(let userID):


            print("USER CREATED:", userID)



            let profile = UserProfile(
                authUserID: userID,
                firstName: state.firstName,
                lastName: state.lastName,
                businessName: state.businessName,
                currencyCode: state.currencyCode,
                languageCode: localization.languageCode
            )


            context.insert(profile)

            do {
                try context.save()
            }
            catch {
                print("PROFILE SAVE ERROR:", error)
            }



            appState.session.login(
                userID: userID
            )

            localization.setLanguage(
                profile.languageCode
            )

            router.currentScreen = .main



        case .failure(let error):


            // Показуємо помилку на екрані і повертаємо на крок з email/паролем,
            // щоб майстер міг одразу її виправити
            errorMessage = error.localizationKey

            step = 0

        }

    }

}
