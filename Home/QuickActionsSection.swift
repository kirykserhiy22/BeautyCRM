//
//  Untitled 2.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 15.07.26.
//

import SwiftUI

struct QuickActionsSection: View {

    @EnvironmentObject var theme: ThemeManager

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }


    var body: some View {

        VStack(alignment: .leading, spacing: 12) {

            Text("Quick actions")
                .font(.headline)
                .foregroundColor(colors.textPrimary)


            HStack(spacing: 12) {

                NavigationLink {
                    ClientsListView()

                } label: {
                    actionCard(
                        title: "Add Clients",
                        icon: "person.3"
                    )
                }


                NavigationLink {
                    ServicesListView()

                } label: {
                    actionCard(
                        title: "Services",
                        icon: "scissors"
                    )
                }
            }


            HStack(spacing: 12) {

                NavigationLink {

                    AppointmentFormView()

                } label: {

                    actionCard(
                        title: "Appointments",
                        icon: "calendar"
                    )
                }


                NavigationLink {

                    DayOffPickerView()

                } label: {

                    actionCard(
                        title: "Day Off",
                        icon: "moon"
                    )
                }
            }
        }
    }



    private func actionCard(
        title: String,
        icon: String
    ) -> some View {

        VStack {

            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(colors.accent)
                


            Text(title)
                .font(.caption)
                .foregroundColor(colors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(colors.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(colors.border, lineWidth: 1)
        )
        .shadow(
            color: colors.shadow,
            radius: 6,
            y: 2
        )
    }
}
