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

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 12) {

            Label(
                "Client Notes",
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
