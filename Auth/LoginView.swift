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
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var localization: LocalizationManager

    private let authService = LocalAuthService()
    @Environment(\.modelContext)
    private var context


    @State private var email = ""
    @State private var password = ""

    @State private var errorMessage = ""

    @State private var isLoading = false


    var body: some View {

        ZStack {

            Color(.systemGroupedBackground)
                .ignoresSafeArea()


            VStack(spacing: 28) {


                Spacer()


                header


                form


                loginButton


                signupButton


                if !errorMessage.isEmpty {

                    Text(errorMessage)
                        .foregroundColor(.red)
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
                .foregroundColor(.pink)


            Text("Welcome back")
                .font(.largeTitle.bold())


            Text(
                "Manage your beauty business smarter"
            )
            .foregroundColor(.secondary)
        }
    }
}


// MARK: Form


private extension LoginView {


    var form: some View {

        VStack(spacing: 16) {


            TextField(
                "Email",
                text: $email
            )
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .padding()
            .background(.white)
            .cornerRadius(14)



            SecureField(
                "Password",
                text: $password
            )
            .padding()
            .background(.white)
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

            Text("Log In")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.pink)
                .foregroundColor(.white)
                .cornerRadius(14)
        }
    }



    var signupButton: some View {

        Button {

            router.currentScreen = .signUp

        } label: {

            Text("Create new account")
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

    func loadUserLanguage(userID: String) {

        guard let profile = UserProfileManager.profile(
            context: context,
            userID: userID
        ) else {
            return
        }

        localization.setLanguage(profile.languageCode)
    }


    func login() {

        errorMessage = ""

        guard isValid else {

            errorMessage = "Fill all fields"
            return
        }


        let result = authService.login(
            email: email,
            password: password
        )


        guard result.isSuccess else {

            errorMessage =
            result.error?.localizedDescription
            ?? "Login failed"

            return
        }


        guard let userID = result.userID else {

            errorMessage = "Missing user ID"
            return
        }


        appState.session.login(
            userID: userID
        )
        loadUserLanguage(
            userID: userID
        )


        router.currentScreen = .main
    }
}
