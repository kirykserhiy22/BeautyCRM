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
        }
    }
}


// MARK: Header

private extension LoginView {


    var header: some View {

        VStack(spacing: 10) {


            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundColor(colors.accent)


            Text("login.title")
                .font(.largeTitle.bold())

            Text("login.subtitle")
                .foregroundColor(.secondary)
        }
    }
}


// MARK: Form


private extension LoginView {


    var form: some View {

        VStack(spacing: 16) {


            TextField("login.email", text: $email)
            .accessibilityIdentifier("login.email")
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .padding()
            .background(colors.inputBackground)
            .cornerRadius(14)



            SecureField("login.password", text: $password)
            .accessibilityIdentifier("login.password")
            .padding()
            .background(colors.inputBackground)
            .cornerRadius(14)

        }
    }
}


// MARK: Buttons

private extension LoginView {


    var loginButton: some View {

        Button {

            login()

        } label: {

            Text("login.button")
                .frame(maxWidth: .infinity)
                .padding()
                .background(colors.buttonPrimary)
                .foregroundColor(.white)
                .cornerRadius(14)
        }
        .accessibilityIdentifier("login.submit")
    }



    var signupButton: some View {

        Button {

            router.currentScreen = .signUp

        } label: {

            Text("login.createAccount")
                .font(.subheadline)
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
}
