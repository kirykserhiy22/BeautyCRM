//
//  Untitled 5.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 23.05.26.
//
import SwiftUI

struct ClientHeaderSection: View {

    let client: Client

    @EnvironmentObject var theme: ThemeManager

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    var body: some View {
        

        VStack(spacing: 14) {

            avatar

            VStack(spacing: 4) {

                Text(client.name)
                    .font(.title2.bold())

                if client.isFavorite {

                    Label(
                        "VIP Client",
                        systemImage: "star.fill"
                    )
                    .font(.caption)
                    .foregroundColor(.yellow)
                }
            }
        }
    }
}

// MARK: - AVATAR

private extension ClientHeaderSection {

    var avatar: some View {

        ZStack {

            Circle()
                .fill(colors.cardSecondary)
                .frame(width: 92, height: 92)

            Text(
                String(client.name.prefix(1))
            )
            .font(.system(size: 34, weight: .bold))
            .foregroundColor(.white)
        }
    }
}
