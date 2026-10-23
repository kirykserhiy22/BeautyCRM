//
//  Untitled 2.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 23.05.26.
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

        VStack(alignment: .leading, spacing: 12) {

            Label(
                localization.localizedString(for: "clients.clientNotes"),
                systemImage: "note.text"
            )
            .font(.headline)

            Text(notes)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
        }
        .padding()
        .background(colors.card)
        .cornerRadius(22)
    }
}
