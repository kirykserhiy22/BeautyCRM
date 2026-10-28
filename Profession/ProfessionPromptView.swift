//
//  ProfessionPromptView.swift
//  BeautyCRM
//

import SwiftUI


// Повноекранний вибір для старих акаунтів без спеціалізації.
// Показується один раз; закрити можна тільки після вибору.
struct ProfessionPromptView: View {

    let onContinue: (Profession) -> Void

    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager

    @State private var selection: Profession?

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }


    var body: some View {

        VStack(spacing: 16) {

            ScrollView {
                ProfessionPickerView(selection: $selection)
                    .padding()
                    .padding(.top, 24)
            }

            Button {
                if let selection {
                    onContinue(selection)
                }
            } label: {
                Text(localization.localizedString(for: "profession.prompt.continue"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(colors.accent)
            .disabled(selection == nil)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(colors.background.ignoresSafeArea())
        .interactiveDismissDisabled()
    }
}


#Preview {
    ProfessionPromptView { _ in }
        .environmentObject(ThemeManager())
        .environmentObject(LocalizationManager())
}
