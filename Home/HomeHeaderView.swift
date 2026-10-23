//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 15.07.26.
//
import SwiftUI

struct HomeHeaderView: View {

    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager
    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 6) {

            Text("BeautyBook")
                .font(.largeTitle.bold())
                .foregroundColor(colors.textPrimary)

            Text(formattedDate)
                .font(.headline)
                .foregroundColor(colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var formattedDate: String {
        AppFormatting.homeDate(
            Date(),
            locale: localization.locale
        )
    }
}

#Preview {
    HomeHeaderView()
        .environmentObject(ThemeManager())
}
