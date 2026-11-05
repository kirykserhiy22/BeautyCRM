//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 16.07.26.
//

import SwiftUI


struct SignUpCurrencyStep: View {

    @ObservedObject var state: SignUpState
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 12) {

                Text("signup.currency.title")
                    .font(.title2.bold())
                    .foregroundColor(colors.textPrimary)
                    .padding(.bottom, 4)

                ForEach(SupportedCurrency.all) { currency in
                    row(for: currency)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func row(for currency: SupportedCurrency) -> some View {

        let isSelected = state.currencyCode == currency.code

        return Button {
            state.currencyCode = currency.code
        } label: {
            HStack(spacing: 14) {

                Text(currency.symbol)
                    .font(.headline)
                    .foregroundColor(colors.accent)
                    .frame(width: 36)

                Text(localization.localizedString(for: "currency.\(currency.code)"))
                    .foregroundColor(colors.textPrimary)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? colors.accent : colors.textMuted)
            }
            .padding()
            .background(colors.card)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? colors.accent : colors.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("currency.\(currency.code)")
    }
}
