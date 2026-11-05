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
    // Вітання — продовження заставки: завжди фірмове вишневе, незалежно від теми й режиму iPhone
    private var colors: ThemeColors {
        theme.colors(for: .darkCherry)
    }

    var body: some View {

        NavigationStack {

            ZStack {

                Color("SplashBackground")
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
                                    } ?? "🌐 \(localization.localizedString(for: "settings.language.title"))"
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

                    BrandMarkView(letters: .white, brush: colors.accent, size: 150)

                    Text(Constants.appName.uppercased())
                        .font(BrandFont.font(size: 20))
                        .tracking(4.4)
                        .foregroundColor(.white)
                        .padding(.top, 28)

                    Text("welcome.description")
                        .font(.body)
                        .foregroundColor(colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 12)

                    Spacer()

                    VStack(spacing: 14) {

                        Button {

                            router.currentScreen = .signUp

                        } label: {

                            AuthButtonLabel(
                                title: "welcome.createAccount",
                                background: colors.buttonPrimary,
                                foreground: .white
                            )
                        }
                        .accessibilityIdentifier("welcome.createAccount")

                        Button {

                            router.currentScreen = .login

                        } label: {

                            AuthButtonLabel(
                                title: "welcome.login",
                                background: colors.card,
                                foreground: .white
                            )
                        }
                        .accessibilityIdentifier("welcome.login")
                    }
                    .padding(.horizontal)

                    Spacer()
                        .frame(height: 24)
                }
            }
        }
        // Обидва потрібні: перший — для статус-бару, другий — щоб фірмові кольори взяли темний варіант
        .preferredColorScheme(.dark)
        .environment(\.colorScheme, .dark)
    }
}

#Preview {
    WelcomeView()
}
