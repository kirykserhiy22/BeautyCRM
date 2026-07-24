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

                Text(errorMessage)
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

            Text(
                "Create account"
            )
            .font(.largeTitle.bold())


            Text(
                "Step \(step + 1) of 4"
            )
            .foregroundColor(.secondary)

        }
    }



    var navigationButtons: some View {

        HStack {

            if step > 0 {

                Button("Back") {
                    step -= 1
                }

            }

            Spacer()

            Button(step == 3 ? "Create account" : "Next") {

                nextStep()
            }
            .buttonStyle(.borderedProminent)

        }

    }


    func nextStep() {

        errorMessage = ""

        switch step {

        case 0:

            guard AuthValidator.validateEmail(state.email) else {
                errorMessage = "Enter a valid email."
                return
            }

            guard AuthValidator.validatePassword(state.password) else {
                errorMessage = "Password must contain at least 8 characters."
                return
            }

            step += 1

        case 1:

            guard AuthValidator.validateName(state.firstName) else {
                errorMessage = "Enter your first name."
                return
            }

            guard AuthValidator.validateName(state.lastName) else {
                errorMessage = "Enter your last name."
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
                languageCode: "en"
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


       


            router.currentScreen = .main



        case .failure(let error):


            print(
                error.localizedDescription
            )

        }

    }

}
