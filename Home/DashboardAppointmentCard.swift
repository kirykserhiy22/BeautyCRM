//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 15.07.26.
//
import SwiftUI

struct DashboardAppointmentCard: View {

    let title: String
    let clientName: String
    let services: String
    let dateText: String
    let timeText: String
    let statusText: String
    let accentColor: Color

    var titleIsLocalized = false
    var clientNameIsLocalized = false
    var statusIsLocalized = false

    @EnvironmentObject var theme: ThemeManager

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }


    var body: some View {

        VStack(alignment: .leading, spacing: 16) {

            // MARK: - HEADER

            Group {
                if titleIsLocalized {
                    Text(LocalizedStringKey(title)).textCase(.uppercase)
                } else {
                    Text(title.uppercased())
                }
            }
            .font(.caption.weight(.bold))
            .foregroundColor(colors.textSecondary)

            // MARK: - CLIENT

            Group {
                if clientNameIsLocalized {
                    Text(LocalizedStringKey(clientName))
                } else {
                    Text(clientName)
                }
            }
            .font(.title2.bold())
            .foregroundColor(colors.textPrimary)


            // MARK: - SERVICES

            if !services.isEmpty {

                Text(services)
                    .font(.subheadline)
                    .foregroundColor(colors.textSecondary)
            }
            // MARK: - DATE
            if !dateText.isEmpty {
                Text(dateText)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(colors.textSecondary)
            }
            // MARK: - TIME

            Text(timeText)
                .font(.headline)
                .foregroundColor(colors.textPrimary)


            // MARK: - STATUS

            HStack(spacing: 6) {

                Circle()
                    .fill(accentColor)
                    .frame(
                        width: 8,
                        height: 8
                    )


                Group {
                    if statusIsLocalized {
                        Text(LocalizedStringKey(statusText))
                    } else {
                        Text(statusText)
                    }
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(accentColor)
            }

        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colors.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(colors.border, lineWidth: 1)
        )
        .shadow(
            color: colors.shadow,
            radius: 6,
            y: 2
        )
    }
}


#Preview {

    DashboardAppointmentCard(
        title: "Current Appointment",
        clientName: "Anna Johnson",
        services: "Hair Coloring • Haircut",
        dateText: "Tomorrow",
        timeText: "10:00 – 11:30",
        statusText: "In Progress",
        accentColor: .green
    )
    .padding()
    .environmentObject(ThemeManager())
}
