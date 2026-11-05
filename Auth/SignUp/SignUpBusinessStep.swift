//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 16.07.26.
//

import SwiftUI


struct SignUpBusinessStep: View {

    @ObservedObject var state: SignUpState
    @EnvironmentObject var theme: ThemeManager

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 16) {

            Text("signup.business.title")
                .font(.title2.bold())
                .foregroundColor(colors.textPrimary)

            TextField("signup.business.name", text: $state.businessName, prompt: Text("signup.business.name").foregroundColor(colors.textSecondary))
                .authField(colors)
                .accessibilityIdentifier("signup.businessName")
        }
    }
}
