//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 16.07.26.
//

import SwiftUI

struct WelcomeView: View {

    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var theme: ThemeManager

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    var body: some View {

        NavigationStack {

            ZStack {

                colors.background
                    .ignoresSafeArea()

                VStack {

                    Spacer()

                    // MARK: Logo

                    Image(systemName: "sparkles")
                        .font(.system(size: 70))
                        .foregroundColor(colors.accent)

                    Text("Beauty CRM")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(colors.textPrimary)
                        .padding(.top, 12)

                    Text("Manage clients, appointments and business in one place.")
                        .font(.body)
                        .foregroundColor(colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 8)

                    Spacer()

                    VStack(spacing: 14) {

                        Button {

                            router.currentScreen = .signUp

                        } label: {

                            Text("Create Account")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(colors.buttonPrimary)
                                .cornerRadius(18)
                        }

                        Button {

                            router.currentScreen = .login

                        } label: {

                            Text("I already have an account")
                                .font(.headline)
                                .foregroundColor(colors.accent)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(colors.card)
                                .cornerRadius(18)
                        }
                    }
                    .padding(.horizontal)

                    Text("Start managing your beauty business in minutes.")
                        .font(.caption)
                        .foregroundColor(colors.textMuted)
                        .padding(.top, 20)

                    Spacer()
                        .frame(height: 35)
                }
            }
        }
    }
}

#Preview {
    WelcomeView()
}
