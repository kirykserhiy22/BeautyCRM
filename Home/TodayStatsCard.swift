//
//  TodayStatsCard.swift
//  BeautyCRM
//
//  Прогрес дня: скільки записів уже завершено.
//

import SwiftUI

struct TodayStatsCard: View {

    let totalAppointments: Int
    let completedAppointments: Int

    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 10) {

            HStack {

                Text("home.dateToday")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(colors.textPrimary)

                Spacer()

                Text(
                    String(
                        format: localization.localizedString(for: "home.progress"),
                        locale: localization.locale,
                        completedAppointments,
                        totalAppointments
                    )
                )
                .font(.subheadline)
                .foregroundColor(colors.textSecondary)
            }

            HStack(spacing: 4) {
                ForEach(0..<totalAppointments, id: \.self) { index in
                    Capsule()
                        .fill(index < completedAppointments ? colors.buttonPrimary : colors.buttonSecondary)
                        .frame(height: 6)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(colors.card)
        )
    }
}
