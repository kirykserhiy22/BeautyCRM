//
//  DashboardAppointmentCard.swift
//  BeautyCRM
//
//  Головна картка: хто наступний і коли.
//

import SwiftUI

struct DashboardAppointmentCard: View {

    let appointment: Appointment
    let title: String
    let services: String
    let timeText: String
    let statusText: String
    let statusColor: Color
    let phoneURL: URL?

    @EnvironmentObject var theme: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 10) {

            HStack(alignment: .firstTextBaseline) {

                Text(LocalizedStringKey(title))
                    .font(.subheadline)
                    .foregroundColor(colors.textSecondary)

                Spacer()

                Text(statusText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(statusColor)
                    .multilineTextAlignment(.trailing)
            }

            Text(appointment.clientName)
                .font(.title.bold())
                .foregroundColor(colors.textPrimary)

            if !services.isEmpty {
                Text(services)
                    .font(.subheadline)
                    .foregroundColor(colors.textSecondary)
            }

            Text(timeText)
                .font(.title3.weight(.semibold))
                .foregroundColor(colors.textPrimary)

            HStack(spacing: 10) {

                NavigationLink {
                    AppointmentDetailScreen(appointment: appointment)
                } label: {
                    AuthButtonLabel(
                        title: "home.open",
                        background: colors.buttonPrimary,
                        foreground: .white
                    )
                }
                .accessibilityIdentifier("home.open")

                if let phoneURL {
                    Link(destination: phoneURL) {
                        Image(systemName: "phone.fill")
                            .font(.headline)
                            .foregroundColor(colors.textPrimary)
                            .frame(width: 54, height: 54)
                            .background(colors.buttonSecondary)
                            .cornerRadius(16)
                    }
                    .accessibilityLabel(Text("clients.phone"))
                }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(colors.card)
        )
        // Фірмова картка вишнева в обох режимах iPhone
        .environment(
            \.colorScheme,
            theme.currentTheme.followsSystemAppearance ? .dark : colorScheme
        )
    }
}


// Коли наступного запису немає: день завершено або вільний
struct DashboardMessageCard: View {

    var title: String? = nil
    let message: String

    @EnvironmentObject var theme: ThemeManager

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 8) {

            if let title {
                Text(LocalizedStringKey(title))
                    .font(.subheadline)
                    .foregroundColor(colors.textSecondary)
            }

            Text(LocalizedStringKey(message))
                .font(.title3.bold())
                .foregroundColor(colors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(colors.card)
        )
    }
}


// Запис з Головної: той самий рядок, що в календарі, одразу розгорнутий
struct AppointmentDetailScreen: View {

    let appointment: Appointment

    @EnvironmentObject var theme: ThemeManager
    @State private var expandedID: UUID?

    var body: some View {

        ScrollView {
            AppointmentRow(
                appt: appointment,
                expandedAppointmentID: $expandedID
            )
            .padding()
        }
        .background(theme.colors(for: theme.currentTheme).background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            expandedID = appointment.id
        }
    }
}
