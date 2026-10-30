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
    @EnvironmentObject var currency: CurrencyManager
    @EnvironmentObject var profession: ProfessionManager

    @Environment(\.modelContext)
    private var context


    @StateObject private var state =
    SignUpState()





    var body: some View {


        VStack {


            progress



            Spacer()



            switch state.step {


            case .account:

                SignUpAccountStep(
                    state: state
                )


            case .profile:

                SignUpProfileStep(
                    state: state
                )


            case .profession:

                ScrollView {
                    ProfessionPickerView(
                        selection: $state.profession
                    )
                    .padding(.vertical, 8)
                }


            case .business:

                SignUpBusinessStep(
                    state: state
                )


            case .currency:

                SignUpCurrencyStep(
                    state: state
                )
            }



            Spacer()
            if !state.errorMessage.isEmpty {

                Text(LocalizedStringKey(state.errorMessage))
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

            // «Крок 3 з 5» — кількість кроків береться з SignUpStep
            Text(
                String(
                    format: localization.localizedString(for: "signup.stepOf"),
                    state.step.number,
                    SignUpStep.allCases.count
                )
            )
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
                state.step.isLast
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

        if !state.goBack() {
            router.currentScreen = .welcome
        }
    }


    // Перевірка й перехід — у SignUpState; тут лише створення акаунта в кінці
    func nextStep() {

        if state.goNext() {
            finishRegistration()
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

            profile.profession = state.profession


            context.insert(profile)

            // Без збереженого профілю не входимо: майстер побачить помилку
            // і зможе натиснути «Створити акаунт» ще раз
            guard context.saveReportingErrors() else {
                return
            }



            appState.session.login(
                userID: userID
            )

            // Мова, валюта і професія з щойно створеного профілю
            UserProfileLoader.load(
                context: context,
                userID: userID,
                localization: localization,
                currency: currency,
                profession: profession
            )

            router.currentScreen = .main



        case .failure(let error):


            // Показуємо помилку на екрані і повертаємо на крок з email/паролем,
            // щоб майстер міг одразу її виправити
            state.errorMessage = error.localizationKey

            state.step = .account

        }

    }

}
