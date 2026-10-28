//
//  ProfessionPickerView.swift
//  BeautyCRM
//

import SwiftUI


// Вибір спеціалізації. Один компонент для трьох місць: крок реєстрації,
// екран для старих акаунтів і Налаштування.
// Нічого сам не зберігає — лише змінює `selection`; зберігає той, хто його показує.
struct ProfessionPickerView: View {

    @Binding var selection: Profession?

    // Заголовок і підзаголовок над картками (можна сховати, якщо екран має свій)
    var showsHeader = true

    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }


    var body: some View {

        VStack(alignment: .leading, spacing: 16) {

            if showsHeader {

                VStack(alignment: .leading, spacing: 6) {

                    Text(localization.localizedString(for: "profession.picker.title"))
                        .font(.title2.bold())
                        .foregroundColor(colors.textPrimary)

                    Text(localization.localizedString(for: "profession.picker.subtitle"))
                        .font(.subheadline)
                        .foregroundColor(colors.textSecondary)
                }
            }

            // Нова професія в enum з'являється тут сама
            ForEach(Profession.allCases) { profession in
                card(for: profession)
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
    }


    // MARK: - CARD

    private func card(for profession: Profession) -> some View {

        let config = profession.config
        let isSelected = selection == profession

        return Button {

            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selection = profession
            }

        } label: {

            HStack(spacing: 14) {

                config.icon.image
                    .font(.title3)
                    .foregroundColor(isSelected ? colors.background : colors.accent)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(isSelected ? colors.accent : colors.accent.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 4) {

                    Text(localization.localizedString(for: config.titleKey))
                        .font(.headline)
                        .foregroundColor(colors.textPrimary)

                    Text(localization.localizedString(for: config.examplesKey))
                        .font(.caption)
                        .foregroundColor(colors.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? colors.accent : colors.textMuted)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(colors.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        isSelected ? colors.accent : colors.border,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1)
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}


// MARK: - PREVIEWS

#Preview("Нічого не обрано") {
    @Previewable @State var selection: Profession? = nil
    ProfessionPickerView(selection: $selection)
        .padding()
        .environmentObject(ThemeManager())
        .environmentObject(LocalizationManager())
}

#Preview("Обрано: перукар") {
    @Previewable @State var selection: Profession? = .hairStylist
    ProfessionPickerView(selection: $selection)
        .padding()
        .environmentObject(ThemeManager())
        .environmentObject(LocalizationManager())
}

#Preview("Обрано: нігті") {
    @Previewable @State var selection: Profession? = .nailArtist
    ProfessionPickerView(selection: $selection)
        .padding()
        .environmentObject(ThemeManager())
        .environmentObject(LocalizationManager())
}

#Preview("Обрано: вії й брови, темна") {
    @Previewable @State var selection: Profession? = .lashBrowArtist
    ProfessionPickerView(selection: $selection)
        .padding()
        .environmentObject(ThemeManager())
        .environmentObject(LocalizationManager())
        .preferredColorScheme(.dark)
}

#Preview("Без заголовка") {
    @Previewable @State var selection: Profession? = .hairStylist
    ProfessionPickerView(selection: $selection, showsHeader: false)
        .padding()
        .environmentObject(ThemeManager())
        .environmentObject(LocalizationManager())
}
