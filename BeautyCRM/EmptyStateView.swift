//
//  EmptyStateView.swift
//  BeautyCRM
//
//  Порожній екран: іконка, заголовок і підказка, що робити далі (#49).
//  Тексти — ключі Localizable.strings.
//

import SwiftUI


struct EmptyStateView: View {

    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager

    let systemImage: String
    let titleKey: String
    let messageKey: String

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    var body: some View {

        VStack(spacing: 12) {

            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundColor(colors.textSecondary.opacity(0.6))

            Text(localization.localizedString(for: titleKey))
                .font(.headline)
                .foregroundColor(colors.textPrimary)

            Text(localization.localizedString(for: messageKey))
                .font(.subheadline)
                .foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
        .padding(.vertical, 48)
    }
}
