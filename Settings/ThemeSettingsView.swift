//
//  ThemeSettingsView.swift
//  BeautyCRM
//
//  Вигляд: як в iPhone, світлий або темний. Тема одна — фірмова Dark Cherry.
//

import SwiftUI

struct ThemeSettingsView: View {

    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 20) {

                modePicker

                HStack(spacing: 12) {
                    preview(.light)
                    preview(.dark)
                }

                Text(localization.localizedString(for: "settings.appearance.description"))
                    .font(.subheadline)
                    .foregroundColor(colors.textSecondary)
            }
            .padding()
        }
        .background(colors.background)
        .navigationTitle(localization.localizedString(for: "settings.appearance"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // Той самий фірмовий перемикач, що й в Аналітиці
    private var modePicker: some View {

        HStack(spacing: 2) {

            ForEach(AppearanceMode.allCases) { mode in

                let isSelected = theme.appearance == mode

                Button {
                    theme.setAppearance(mode)
                } label: {
                    Text(localization.localizedString(for: mode.titleKey))
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(isSelected ? .white : colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(isSelected ? colors.buttonPrimary : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityIdentifier("appearance.\(mode.rawValue)")
            }
        }
        .padding(3)
        .background(colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // Маленький зразок екрана: ті самі фірмові кольори в потрібному режимі
    private func preview(_ scheme: ColorScheme) -> some View {

        VStack(alignment: .leading, spacing: 8) {

            Text(localization.localizedString(for: scheme == .light ? "settings.appearance.light" : "settings.appearance.dark"))
                .font(.caption.weight(.semibold))
                .foregroundColor(colors.textPrimary)

            RoundedRectangle(cornerRadius: 6)
                .fill(colors.card)
                .frame(height: 28)

            RoundedRectangle(cornerRadius: 6)
                .fill(colors.buttonPrimary)
                .frame(width: 60, height: 12)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colors.background)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(colors.border))
        .environment(\.colorScheme, scheme)
    }
}
