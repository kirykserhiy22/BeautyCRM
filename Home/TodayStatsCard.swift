import SwiftUI

struct TodayStatsCard: View {

    let totalAppointments: Int
    let completedAppointments: Int
    let remainingAppointments: Int

    @EnvironmentObject var theme: ThemeManager

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 16) {

            Text("TODAY")
                .font(.caption.weight(.bold))
                .foregroundColor(colors.textSecondary)

            HStack(spacing: 16) {

                statView(
                    value: totalAppointments,
                    title: "Appointments"
                )

                Divider()

                statView(
                    value: completedAppointments,
                    title: "Completed"
                )

                Divider()

                statView(
                    value: remainingAppointments,
                    title: "Remaining"
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
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

    @ViewBuilder
    private func statView(
        value: Int,
        title: String
    ) -> some View {

        VStack(spacing: 6) {

            Text("\(value)")
                .font(.title.bold())
                .foregroundColor(colors.textPrimary)

            Text(title)
                .font(.caption)
                .foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    TodayStatsCard(
        totalAppointments: 5,
        completedAppointments: 2,
        remainingAppointments: 3
    )
    .padding()
    .environmentObject(ThemeManager())
}