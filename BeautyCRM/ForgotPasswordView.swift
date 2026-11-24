//
//  ForgotPasswordView.swift
//  BeautyCRM
//
//  «Забули пароль?»: email → лист із кодом → код і новий пароль двічі → вхід.
//  Пароль на телефоні не зберігається: його приймає лише сервер.
//

import SwiftUI
import SwiftData

struct ForgotPasswordView: View {

    let initialEmail: String
    let onClose: () -> Void

    @Environment(\.modelContext) private var context
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var currency: CurrencyManager
    @EnvironmentObject var profession: ProfessionManager

    private enum Step { case email, reset }

    @State private var step = Step.email
    @State private var email = ""
    @State private var code = ""
    @State private var password = ""
    @State private var repeatPassword = ""
    @State private var errorKey: String?
    @State private var noticeKey: String?
    @State private var isWorking = false
    @FocusState private var isCodeFocused: Bool

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 16) {

                Button {
                    if step == .reset {
                        step = .email
                        errorKey = nil
                    } else {
                        onClose()
                    }
                } label: {
                    Label(localization.localizedString(for: "signup.back"), systemImage: "chevron.left")
                        .font(.subheadline)
                        .foregroundColor(colors.textSecondary)
                }
                .buttonStyle(.plain)

                Image(systemName: "lock")
                    .font(.title2)
                    .foregroundColor(colors.accent)
                    .frame(width: 56, height: 56)
                    .background(RoundedRectangle(cornerRadius: 16).fill(colors.card))
                    .padding(.top, 4)

                if step == .email {
                    emailStep
                } else {
                    resetStep
                }

                if let errorKey {
                    Text(localization.localizedString(for: errorKey))
                        .font(.footnote)
                        .foregroundColor(colors.danger)
                        .accessibilityIdentifier("reset.error")
                } else if let noticeKey {
                    Text(localization.localizedString(for: noticeKey))
                        .font(.footnote)
                        .foregroundColor(colors.success)
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .background(colors.background.ignoresSafeArea())
        .disabled(isWorking)
        .overlay {
            if isWorking {
                ProgressView()
            }
        }
        .onAppear {
            if email.isEmpty {
                email = initialEmail
            }
        }
    }

    // MARK: - STEPS

    private var emailStep: some View {

        VStack(alignment: .leading, spacing: 16) {

            Text(localization.localizedString(for: "auth.forgot.title"))
                .font(.title.bold())
                .foregroundColor(colors.textPrimary)

            Text(localization.localizedString(for: "auth.forgot.subtitle"))
                .font(.subheadline)
                .foregroundColor(colors.textSecondary)

            TextField("login.email", text: $email, prompt: Text("login.email").foregroundColor(colors.textSecondary))
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .authField(colors)
                .accessibilityIdentifier("reset.email")

            Button {
                sendCode()
            } label: {
                AuthButtonLabel(
                    title: "auth.forgot.send",
                    background: AuthValidator.validateEmail(email) ? colors.buttonPrimary : colors.buttonSecondary,
                    foreground: .white
                )
            }
            .disabled(!AuthValidator.validateEmail(email))
            .accessibilityIdentifier("reset.send")
        }
    }

    private var resetStep: some View {

        VStack(alignment: .leading, spacing: 14) {

            Text(localization.localizedString(for: "auth.reset.title"))
                .font(.title.bold())
                .foregroundColor(colors.textPrimary)

            Text(String(format: localization.localizedString(for: "auth.reset.codeTo"), ServerAuth.normalized(email)))
                .font(.subheadline)
                .foregroundColor(colors.textSecondary)

            CodeBoxes(
                code: $code,
                isFocused: $isCodeFocused,
                hasError: errorKey == AuthError.invalidCode.localizationKey,
                colors: colors,
                onChange: { errorKey = nil }
            )

            PasswordField(titleKey: "auth.reset.newPassword", text: $password, colors: colors, identifier: "reset.password")
            PasswordField(titleKey: "auth.reset.repeat", text: $repeatPassword, colors: colors, identifier: "reset.repeat")

            Text(localization.localizedString(for: "auth.reset.hint"))
                .font(.caption)
                .foregroundColor(colors.textSecondary)

            Button {
                save()
            } label: {
                AuthButtonLabel(
                    title: "auth.reset.save",
                    background: canSave ? colors.buttonPrimary : colors.buttonSecondary,
                    foreground: .white
                )
            }
            .disabled(!canSave)
            .accessibilityIdentifier("reset.save")

            Button {
                sendCode()
            } label: {
                Text(localization.localizedString(for: "auth.code.resend"))
                    .font(.subheadline)
                    .foregroundColor(colors.accent)
                    .frame(maxWidth: .infinity)
            }
        }
        .onAppear { isCodeFocused = true }
    }

    // MARK: - ACTIONS

    private var canSave: Bool {
        code.count == EmailCodeView.codeLength && !password.isEmpty && !repeatPassword.isEmpty
    }

    private func sendCode() {
        isWorking = true
        errorKey = nil
        noticeKey = nil
        Task {
            let error = await ServerAuth.sendPasswordReset(email: email)
            isWorking = false
            if let error {
                errorKey = error.localizationKey
            } else {
                if step == .reset {
                    noticeKey = "auth.code.resent"
                }
                step = .reset
            }
        }
    }

    private func save() {
        guard AuthValidator.validatePassword(password) else {
            errorKey = "signup.error.password"
            return
        }
        guard password == repeatPassword else {
            errorKey = AuthError.passwordsDontMatch.localizationKey
            return
        }
        isWorking = true
        errorKey = nil
        let email = ServerAuth.normalized(self.email)
        Task {
            switch await ServerAuth.resetPassword(email: email, code: code, newPassword: password) {
            case .success(let userID):
                if let error = await AccountEntry.enter(
                    userID: userID,
                    email: email,
                    context: context,
                    appState: appState,
                    router: router,
                    localization: localization,
                    currency: currency,
                    profession: profession
                ) {
                    errorKey = error.localizationKey
                } else {
                    onClose()
                }
            case .failure(let error):
                errorKey = error.localizationKey
                if error == .invalidCode {
                    code = ""
                }
            }
            isWorking = false
        }
    }
}
