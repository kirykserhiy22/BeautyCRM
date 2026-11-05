//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 16.07.26.
//

import SwiftUI


struct SignUpProfileStep: View {

    @ObservedObject var state: SignUpState
    @EnvironmentObject var theme: ThemeManager

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 16) {

            Text("signup.profile.title")
                .font(.title2.bold())
                .foregroundColor(colors.textPrimary)

            TextField("signup.firstName", text: $state.firstName, prompt: Text("signup.firstName").foregroundColor(colors.textSecondary))
                .authField(colors)
                .accessibilityIdentifier("signup.firstName")

            TextField("signup.lastName", text: $state.lastName, prompt: Text("signup.lastName").foregroundColor(colors.textSecondary))
                .authField(colors)
                .accessibilityIdentifier("signup.lastName")
        }
    }
}
