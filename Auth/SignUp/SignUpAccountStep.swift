//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 16.07.26.
//

import SwiftUI


struct SignUpAccountStep: View {

    @ObservedObject var state: SignUpState
    @EnvironmentObject var theme: ThemeManager

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 16) {

            Text("signup.account.title")
                .font(.title2.bold())
                .foregroundColor(colors.textPrimary)

            TextField("signup.email", text: $state.email, prompt: Text("signup.email").foregroundColor(colors.textSecondary))
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .authField(colors)
                .accessibilityIdentifier("signup.email")

            SecureField("signup.password", text: $state.password, prompt: Text("signup.password").foregroundColor(colors.textSecondary))
                .authField(colors)
                .accessibilityIdentifier("signup.password")

            Text("signup.password.hint")
                .font(.caption)
                .foregroundColor(colors.textSecondary)
        }
    }
}
