//
//  DeleteAccountView.swift
//  BeautyCRM
//
//  Налаштування → «Видалити акаунт»: чесне попередження і підтвердження власною поштою,
//  щоб не видалити все випадковим тапом. Після видалення — стартовий екран.
//

import SwiftUI
import SwiftData

struct DeleteAccountView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var profession: ProfessionManager

    @State private var typedEmail = ""
    @State private var errorKey: String?
    @State private var isWorking = false

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    private var userID: String? {
        appState.session.userID
    }

    private var accountEmail: String {
        userID.flatMap { AccountDeletion.email(userID: $0) } ?? ""
    }

    private var isConfirmed: Bool {
        !accountEmail.isEmpty && ServerAuth.normalized(typedEmail) == ServerAuth.normalized(accountEmail)
    }

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(alignment: .leading, spacing: 16) {

                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundColor(colors.danger)
                        .frame(width: 56, height: 56)
                        .background(RoundedRectangle(cornerRadius: 16).fill(colors.card))

                    Text(localization.localizedString(for: "deleteAccount.title"))
                        .font(.title.bold())
                        .foregroundColor(colors.textPrimary)

                    Text(localization.localizedString(for: "deleteAccount.warning"))
                        .foregroundColor(colors.textPrimary)

                    Text(String(format: localization.localizedString(for: "deleteAccount.typeEmail"), accountEmail))
                        .font(.subheadline)
                        .foregroundColor(colors.textSecondary)

                    TextField(accountEmail, text: $typedEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .authField(colors)
                        .accessibilityIdentifier("deleteAccount.email")

                    if let errorKey {
                        Text(localization.localizedString(for: errorKey))
                            .font(.footnote)
                            .foregroundColor(colors.danger)
                    }

                    Button {
                        deleteAccount()
                    } label: {
                        ZStack {
                            AuthButtonLabel(
                                title: LocalizedStringKey(isWorking ? "" : "deleteAccount.confirm"),
                                background: isConfirmed ? colors.danger : colors.buttonSecondary,
                                foreground: .white
                            )
                            if isWorking {
                                ProgressView().tint(.white)
                            }
                        }
                    }
                    .disabled(!isConfirmed || isWorking)
                    .accessibilityIdentifier("deleteAccount.confirm")
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .background(colors.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localization.localizedString(for: "common.cancel")) {
                        dismiss()
                    }
                    .disabled(isWorking)
                }
            }
        }
        .interactiveDismissDisabled(isWorking)
    }

    private func deleteAccount() {
        guard let userID, isConfirmed else { return }
        isWorking = true
        errorKey = nil
        Task {
            if let error = await AccountDeletion.deleteAccount(userID: userID, context: context) {
                errorKey = error.localizationKey
                isWorking = false
                return
            }
            appState.session.logout()
            profession.reset()
            dismiss()
            router.currentScreen = .welcome
        }
    }
}
