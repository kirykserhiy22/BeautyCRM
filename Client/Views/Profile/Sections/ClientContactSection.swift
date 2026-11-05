//
//  Untitled 4.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 23.05.26.
//

import SwiftUI

struct ClientContactSection: View {

    let client: Client

    @EnvironmentObject var theme: ThemeManager

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    var body: some View {

        VStack(spacing: 14) {

            if let phone = client.phone {

                contactLink(
                    url: ContactLinks.phone(phone),
                    icon: "phone.fill",
                    title: phone
                )
            }

            if let instagram = client.instagram {

                contactLink(
                    url: ContactLinks.instagram(instagram),
                    icon: "camera.fill",
                    title: instagram
                )
            }

            if let telegram = client.telegram {

                contactLink(
                    url: ContactLinks.telegram(telegram),
                    icon: "paperplane.fill",
                    title: telegram
                )
            }
        }
    }
}

// MARK: - COMPONENTS

private extension ClientContactSection {

    // Якщо посилання зібрати не вдалось, рядок показується без переходу
    @ViewBuilder
    func contactLink(
        url: URL?,
        icon: String,
        title: String
    ) -> some View {

        if let url {
            Link(destination: url) {
                contactRow(icon: icon, title: title, hasLink: true)
            }
        } else {
            contactRow(icon: icon, title: title, hasLink: false)
        }
    }

    func contactRow(
        icon: String,
        title: String,
        hasLink: Bool
    ) -> some View {

        HStack(spacing: 14) {

            Image(systemName: icon)
                .frame(width: 24)

            Text(title)

            Spacer()

            if hasLink {
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(colors.textSecondary)
            }
        }
        .foregroundColor(colors.textPrimary)
        .padding()
        .background(colors.card)
        .cornerRadius(18)
    }
}
