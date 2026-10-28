//
//  Untitled 2.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 15.07.26.
//

import SwiftUI

struct QuickActionsSection: View {

    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var profession: ProfessionManager

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }


    var body: some View {

        VStack(alignment: .leading, spacing: 12) {

            Text("home.quickActions")
                .font(.headline)
                .foregroundColor(colors.textPrimary)


            HStack(spacing: 12) {

                NavigationLink {
                    ClientFormView(mode: .create)

                } label: {
                    actionCard(
                        title: "home.addClients",
                        icon: Image(systemName: "person.3")
                    )
                }


                NavigationLink {
                    ServicesListView()

                } label: {
                    // Іконка послуг залежить від спеціалізації майстра
                    actionCard(
                        title: "home.services",
                        icon: profession.config.serviceIcon.image
                    )
                }
            }


            HStack(spacing: 12) {

                NavigationLink {

                    AppointmentFormView()

                } label: {

                    actionCard(
                        title: "home.appointments",
                        icon: Image(systemName: "calendar")
                    )
                }


                NavigationLink {

                    DayOffPickerView()

                } label: {

                    actionCard(
                        title: "home.dayOff",
                        icon: Image(systemName: "moon")
                    )
                }
            }
        }
    }



    private func actionCard(
        title: String,
        icon: Image
    ) -> some View {

        VStack {

            icon
                .font(.title2)
                .foregroundColor(colors.accent)
                


            Text(LocalizedStringKey(title))
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
