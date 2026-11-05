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

        HStack(alignment: .top, spacing: 8) {

            NavigationLink {
                AppointmentFormView()
            } label: {
                action(title: "home.action.appointment", icon: Image(systemName: "calendar.badge.plus"))
            }

            NavigationLink {
                ClientFormView(mode: .create)
            } label: {
                action(title: "home.action.client", icon: Image(systemName: "person.badge.plus"))
            }

            NavigationLink {
                ServicesListView()
            } label: {
                // Іконка послуг залежить від спеціалізації майстра
                action(title: "home.services", icon: profession.config.serviceIcon.image)
            }

            NavigationLink {
                DayOffPickerView()
            } label: {
                action(title: "home.dayOff", icon: Image(systemName: "moon"))
            }
        }
    }


    private func action(
        title: String,
        icon: Image
    ) -> some View {

        VStack(spacing: 6) {

            icon
                .font(.title3)
                .foregroundColor(colors.accent)
                .frame(width: 56, height: 56)
                .background(Circle().fill(colors.card))

            Text(LocalizedStringKey(title))
                .font(.caption)
                .foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity)
    }
}
