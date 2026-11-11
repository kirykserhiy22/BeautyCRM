//
//  ClientNotesSection.swift
//  BeautyCRM
//

import SwiftUI

struct ClientNotesSection: View {

    let notes: String

    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 8) {

            Text(localization.localizedString(for: "clients.notes"))
                .font(.headline)
                .foregroundColor(colors.textPrimary)

            Text(notes)
                .foregroundColor(colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(colors.card)
                .cornerRadius(20)
        }
    }
}
