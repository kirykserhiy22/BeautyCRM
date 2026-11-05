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
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var currency: CurrencyManager
    @EnvironmentObject var profession: ProfessionManager

    @Environment(\.modelContext)
    private var context


    @StateObject private var state =
    SignUpState()





    var body: some View {


        VStack(spacing: 24) {


            progress



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
                    .padding(.vertical, 2)
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



            Spacer(minLength: 0)

            if !state.errorMessage.isEmpty {

                Text(LocalizedStringKey(state.errorMessage))
                    .foregroundColor(colors.danger)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }



            navigationButtons

        }
        .padding()
        .background(colors.background.ignoresSafeArea())
    }
}



private extension SignUpFlowView {


    var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    var progress: some View {
        VStack(alignment: .leading, spacing: 8) {

            SignUpProgressBar(
                step: state.step.number,
                total: SignUpStep.allCases.count,
                colors: colors
            )

            // «Крок 3 з 5» — кількість кроків береться з SignUpStep
            Text(
                String(
                    format: localization.localizedString(for: "signup.stepOf"),
                    state.step.number,
                    SignUpStep.allCases.count
                )
            )
            .font(.subheadline)
            .foregroundColor(colors.textSecondary)
        }
    }



    var navigationButtons: some View {
        VStack(spacing: 14) {

            Button {
                nextStep()
            } label: {
                AuthButtonLabel(
                    title: state.step.isLast
                        ? "signup.createAccount"
                        : "signup.next",
                    background: colors.buttonPrimary,
                    foreground: .white
                )
            }
            .accessibilityIdentifier("signup.next")

            Button {
                goBack()
            } label: {
                Text("signup.back")
                    .font(.subheadline)
                    .foregroundColor(colors.textSecondary)
            }
            .accessibilityIdentifier("signup.back")
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
