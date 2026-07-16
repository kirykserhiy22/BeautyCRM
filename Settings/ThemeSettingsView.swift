//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 13.05.26.
//

import SwiftUI

struct ThemeSettingsView: View {

    @EnvironmentObject var theme: ThemeManager

    var body: some View {

        VStack(spacing: 16) {

            Text("Theme")
                .font(.title2.bold())

            ForEach(AppTheme.allCases, id: \.self) { themeCase in

                ThemePreviewCard(
                    theme: themeCase,
                    isSelected: theme.currentTheme == themeCase
                ) {
                    theme.currentTheme = themeCase
                    ThemeStorage().save(themeCase)
                }
            }

            Spacer()
        }
        .padding()
    }
}
