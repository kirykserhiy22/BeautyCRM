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
    @EnvironmentObject var localization: LocalizationManager
    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    var body: some View {

        NavigationStack {

            ZStack {

                colors.background
                    .ignoresSafeArea()

                VStack {
                    HStack {
                        Spacer()

                        Menu {
                            ForEach(SupportedLanguage.all) { language in
                                Button {
                                    localization.setLanguage(language.code)
                                } label: {
                                    Text("\(language.flag) \(language.title)")
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Text(
                                    SupportedLanguage.all.first {
                                        $0.code == localization.languageCode
                                    }.map {
                                        "\($0.flag) \($0.title)"
                                    } ?? "🌐 Language"
                                )

                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(colors.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(colors.card)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)


                    Spacer()

                    // MARK: Logo

                    Image(systemName: "sparkles")
                        .font(.system(size: 70))
                        .foregroundColor(colors.accent)

                    Text("Beauty CRM")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(colors.textPrimary)
                        .padding(.top, 12)

                    Text("welcome.description")
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

                            Text("welcome.createAccount")
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

                            Text("welcome.login")
                                .font(.headline)
                                .foregroundColor(colors.accent)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(colors.card)
                                .cornerRadius(18)
                        }
                    }
                    .padding(.horizontal)

                    Text("welcome.tagline")
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
