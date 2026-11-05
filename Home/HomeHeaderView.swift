//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 15.07.26.
//
import SwiftUI

struct HomeHeaderView: View {

    let firstName: String

    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager
    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 6) {

            Text(title)
                .font(.title.bold())
                .foregroundColor(colors.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Text(formattedDate)
                .font(.subheadline)
                .foregroundColor(colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // Без імені (старий профіль) — просто назва додатку
    private var title: String {

        let name = firstName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !name.isEmpty else {
            return Constants.appName
        }

        let hour = Calendar.current.component(.hour, from: Date())

        return String(
            format: localization.localizedString(for: HomeTiming.greetingKey(hour: hour)),
            locale: localization.locale,
            name
        )
    }

    private var formattedDate: String {
        AppFormatting.homeDate(
            Date(),
            locale: localization.locale
        )
    }
}
