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

    // Екран коду з листа (сервер)
    @State private var codeEmail: String?
    @State private var isWorking = false





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
        .disabled(isWorking)
        .overlay {
            if isWorking {
                ProgressView()
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { codeEmail != nil },
            set: { if !$0 { codeEmail = nil } }
        )) {
            if let email = codeEmail {
                EmailCodeView(
                    email: email,
                    verify: { code in await verifyCode(code, email: email) },
                    resend: { await ServerAuth.resendSignUpCode(email: email) },
                    onChangeEmail: {
                        codeEmail = nil
                        state.step = .account
                    }
                )
            }
        }
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

        guard AuthMode.usesServer else {
            finishLocally()
            return
        }

        let pending = PendingSignUp(
            email: ServerAuth.normalized(state.email),
            firstName: state.firstName,
            lastName: state.lastName,
            businessName: state.businessName.isEmpty ? nil : state.businessName,
            currencyCode: state.currencyCode,
            languageCode: localization.languageCode,
            professionRaw: state.profession?.rawValue
        )

        isWorking = true
        state.errorMessage = ""

        Task {
            let result = await ServerAuth.signUp(email: state.email, password: state.password)
            isWorking = false

            switch result {

            case .success(.codeSent):
                pending.save()
                codeEmail = pending.email

            case .success(.alreadyRegistered):
                state.errorMessage = AuthError.userAlreadyExists.localizationKey
                state.step = .account

            case .failure(let error):
                state.errorMessage = error.localizationKey
                if [.invalidEmail, .weakPassword, .userAlreadyExists].contains(error) {
                    state.step = .account
                }
            }
        }
    }

    func verifyCode(_ code: String, email: String) async -> AuthError? {
        switch await ServerAuth.verifySignUp(email: email, code: code) {
        case .success(let userID):
            return await AccountEntry.enter(
                userID: userID,
                email: email,
                context: context,
                appState: appState,
                router: router,
                localization: localization,
                currency: currency,
                profession: profession
            )
        case .failure(let error):
            return error
        }
    }

    // Без сервера — лише автоматичні тести (-localAuth) або збірка без ключів
    func finishLocally() {


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

            // Новий майстер один раз побачить короткий гід по додатку
            OnboardingStore.markPending(userID: userID)

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
