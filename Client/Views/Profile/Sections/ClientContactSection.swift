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

                Link(
                    destination: URL(
                        string: "tel://\(phone)"
                    )!
                ) {

                    contactRow(
                        icon: "phone.fill",
                        title: phone
                    )
                }
            }

            if let instagram = client.instagram {

                Link(
                    destination: URL(
                        string: "https://instagram.com/\(instagram)"
                    )!
                ) {

                    contactRow(
                        icon: "camera.fill",
                        title: "\(instagram)"
                    )
                }
            }

            if let telegram = client.telegram {

                Link(
                    destination: URL(
                        string: "https://t.me/\(telegram)"
                    )!
                ) {

                    contactRow(
                        icon: "paperplane.fill",
                        title: "\(telegram)"
                    )
                }
            }
        }
    }
}

// MARK: - COMPONENTS

private extension ClientContactSection {

    func contactRow(
        icon: String,
        title: String
    ) -> some View {

        HStack(spacing: 14) {

            Image(systemName: icon)
                .frame(width: 24)

            Text(title)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundColor(colors.textSecondary)
        }
        .foregroundColor(colors.textPrimary)
        .padding()
        .background(colors.card)
        .cornerRadius(18)
    }
}
