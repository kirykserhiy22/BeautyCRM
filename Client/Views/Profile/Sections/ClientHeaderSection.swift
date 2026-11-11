//
//  ClientHeaderSection.swift
//  BeautyCRM
//
//  Шапка картки клієнта: аватар, ім'я і відколи клієнт у базі.
//

import SwiftUI
import SwiftData

struct ClientHeaderSection: View {

    let client: Client

    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager
    @Query private var appointments: [Appointment]

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    var body: some View {

        VStack(spacing: 6) {

            avatar
                .padding(.bottom, 6)

            Text(client.name)
                .font(.title2.bold())
                .foregroundColor(colors.textPrimary)
                .multilineTextAlignment(.center)

            Text(
                String(
                    format: localization.localizedString(for: "clients.since"),
                    // «MMMM» дає родовий відмінок: «з листопада», «od listopada»
                    AppFormatting.pattern(
                        "MMMM yyyy",
                        ClientAnalyticsCalculator.clientSince(client: client, appointments: appointments),
                        locale: localization.locale
                    )
                )
            )
            .font(.subheadline)
            .foregroundColor(colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var avatar: some View {

        ZStack {

            Circle()
                .fill(colors.cardSecondary)
                .frame(width: 92, height: 92)

            Text(String(client.name.prefix(1)))
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(colors.accent)
        }
    }
}
