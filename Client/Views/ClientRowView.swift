//
//  ClientRowView.swift
//  BeautyCRM
//
//  Рядок списку клієнтів: ім'я і скільки разів клієнт уже приходив.
//  Контакти видно в картці клієнта, тут вони лише займали б місце.
//

import SwiftUI

struct ClientRowView: View {

    let client: Client

    // Завершені візити
    let visits: Int

    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    var body: some View {

        HStack(spacing: 14) {

            Circle()
                .fill(colors.accent)
                .frame(width: 46, height: 46)
                .overlay(
                    Text(String(client.name.prefix(1)))
                        .font(.headline)
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {

                Text(client.name)
                    .font(.headline)
                    .foregroundColor(colors.textPrimary)
                    .lineLimit(1)

                Text(visitsText)
                    .font(.subheadline)
                    .foregroundColor(colors.textSecondary)
            }

            Spacer()
        }
        .padding()
    }

    private var visitsText: String {

        visits == 0
            ? localization.localizedString(for: "clients.noVisitsYet")
            : CountFormatting.visits(visits, locale: localization.locale)
    }
}
