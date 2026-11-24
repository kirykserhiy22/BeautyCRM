//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 30.04.26.
//
import SwiftUI
import SwiftData

struct LoginView: View {

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var currency: CurrencyManager
    @EnvironmentObject var profession: ProfessionManager

    private let authService = LocalAuthService()
    @Environment(\.modelContext)
    private var context


    @State private var email = ""
    @State private var password = ""

    @State private var errorMessage = ""

    @State private var isLoading = false

    // Пошту не підтверджено — екран коду з листа
    @State private var codeEmail: String?

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }


    var body: some View {

        ZStack {

            colors.background
                .ignoresSafeArea()


            VStack(spacing: 28) {


                Spacer()


                header


                form


                loginButton


                signupButton


                if !errorMessage.isEmpty {

                    Text(LocalizedStringKey(errorMessage))
                        .foregroundColor(colors.danger)
                        .font(.caption)
                }


                Spacer()

            }
            .padding()
            .disabled(isLoading)

            if isLoading {
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
                    onChangeEmail: { codeEmail = nil }
                )
            }
        }
    }
}


// MARK: Header

private extension LoginView {


    var header: some View {

        VStack(spacing: 10) {


            BrandMarkView(letters: colors.textPrimary, brush: colors.buttonPrimary, size: 88)


            Text("login.title")
                .font(.largeTitle.bold())
                .foregroundColor(colors.textPrimary)

            Text("login.subtitle")
                .foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}


// MARK: Form


private extension LoginView {


    var form: some View {

        VStack(spacing: 16) {


            TextField("login.email", text: $email, prompt: Text("login.email").foregroundColor(colors.textSecondary))
            .accessibilityIdentifier("login.email")
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .authField(colors)



            PasswordField(
                titleKey: "login.password",
                text: $password,
                colors: colors,
                identifier: "login.password"
            )

        }
    }
}


// MARK: Buttons

private extension LoginView {


    var loginButton: some View {

        Button {

            login()

        } label: {

            AuthButtonLabel(
                title: "login.button",
                background: colors.buttonPrimary,
                foreground: .white
            )
        }
        .accessibilityIdentifier("login.submit")
    }



    var signupButton: some View {

        Button {

            router.currentScreen = .signUp

        } label: {

            Text("login.createAccount")
                .font(.subheadline)
                .foregroundColor(colors.accent)
        }
    }
}


// MARK: Logic

private extension LoginView {


    var isValid: Bool {

        !email.isEmpty &&
        !password.isEmpty
    }

    // Мова, валюта і професія з профілю користувача
    func loadUserProfile(userID: String) {

        UserProfileLoader.load(
            context: context,
            userID: userID,
            localization: localization,
            currency: currency,
            profession: profession
        )
    }


    func login() {

        errorMessage = ""

        guard isValid else {

            errorMessage = "login.error.fillFields"
            return
        }


        guard !AuthMode.usesServer else {
            loginOnServer()
            return
        }

        let result = authService.login(
            email: email,
            password: password
        )


        guard result.isSuccess else {

            errorMessage = "login.error.failed"

            return
        }


        guard let userID = result.userID else {

            errorMessage = "login.error.missingUserID"
            return
        }


        appState.session.login(
            userID: userID
        )
        loadUserProfile(
            userID: userID
        )


        router.currentScreen = .main
    }

    func loginOnServer() {

        let email = ServerAuth.normalized(self.email)
        isLoading = true

        Task {
            let result = await ServerAuth.signIn(email: email, password: password)

            switch result {

            case .success(let userID):
                if let error = await enter(userID: userID, email: email) {
                    errorMessage = error.localizationKey
                }

            case .failure(.emailNotConfirmed):
                // Новий код і екран для нього
                if let error = await ServerAuth.resendSignUpCode(email: email), error != .tooManyRequests {
                    errorMessage = error.localizationKey
                } else {
                    codeEmail = email
                }

            case .failure(.wrongPassword):
                errorMessage = "login.error.failed"

            case .failure(let error):
                errorMessage = error.localizationKey
            }

            isLoading = false
        }
    }

    func verifyCode(_ code: String, email: String) async -> AuthError? {
        switch await ServerAuth.verifySignUp(email: email, code: code) {
        case .success(let userID):
            return await enter(userID: userID, email: email)
        case .failure(let error):
            return error
        }
    }

    func enter(userID: String, email: String) async -> AuthError? {
        await AccountEntry.enter(
            userID: userID,
            email: email,
            context: context,
            appState: appState,
            router: router,
            localization: localization,
            currency: currency,
            profession: profession
        )
    }
}
