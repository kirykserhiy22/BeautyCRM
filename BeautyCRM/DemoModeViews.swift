//
//  DemoModeViews.swift
//  BeautyCRM
//
//  Пропозиція «Спробувати на прикладі» після гіда і тонка плашка демо-режиму зверху
//  з кнопкою «Почати роботу» (видаляє лише демо-дані).
//

import SwiftUI


// Після гіда: спробувати на демо чи почати з чистого аркуша
struct DemoOfferView: View {

    let onTryDemo: () -> Void
    let onStartClean: () -> Void

    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    var body: some View {

        VStack(spacing: 22) {

            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 44, weight: .semibold))
                .foregroundColor(colors.accent)

            VStack(spacing: 10) {
                Text(localization.localizedString(for: "demo.offer.title"))
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .foregroundColor(colors.textPrimary)
                Text(localization.localizedString(for: "demo.offer.message"))
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 8)

            Spacer()

            VStack(spacing: 12) {
                Button(action: onTryDemo) {
                    Text(localization.localizedString(for: "demo.offer.try"))
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(colors.buttonPrimary))
                }
                .accessibilityIdentifier("demo.try")

                Button(action: onStartClean) {
                    Text(localization.localizedString(for: "demo.offer.clean"))
                        .font(.headline)
                        .foregroundColor(colors.accent)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .accessibilityIdentifier("demo.clean")
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.background.ignoresSafeArea())
    }
}


// Тонка плашка зверху, поки ввімкнено демо
struct DemoBanner: View {

    let onStart: () -> Void

    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager

    @State private var askStart = false

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    var body: some View {

        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.subheadline)
                .foregroundColor(colors.accent)
            Text(localization.localizedString(for: "demo.banner"))
                .font(.subheadline)
                .foregroundColor(colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 8)
            Button {
                askStart = true
            } label: {
                Text(localization.localizedString(for: "demo.banner.start"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(colors.buttonPrimary))
            }
            .accessibilityIdentifier("demo.start")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(colors.card.ignoresSafeArea(edges: .top))
        .confirmationDialog(
            localization.localizedString(for: "demo.start.title"),
            isPresented: $askStart,
            titleVisibility: .visible
        ) {
            Button(localization.localizedString(for: "demo.start.confirm"), role: .destructive, action: onStart)
            Button(localization.localizedString(for: "common.cancel"), role: .cancel) { }
        } message: {
            Text(localization.localizedString(for: "demo.start.message"))
        }
    }
}
