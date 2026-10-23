//
//  UntClientPhotoGridSection.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 23.05.26.
//

import SwiftUI

struct ClientStatCard: View {

    let title: String
    let value: String
    let icon: String

    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager
    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 10) {

            Image(systemName: icon)
                .font(.title3)

            Text(value)
                .font(.title2.bold())

            Text(localization.localizedString(for: title))
                .font(.caption)
                .foregroundColor(colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(colors.card)
        .cornerRadius(20)
    }
}
