//
//  ClientSortSheet.swift
//  BeautyCRM
//
//  Вибір сортування клієнтів: За іменем · За візитом · За датою додавання.
//

import SwiftUI


struct ClientSortSheet: View {

    @Binding var selection: String

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(alignment: .leading, spacing: 18) {

                    ForEach(ClientSort.Group.allCases, id: \.self) { group in

                        VStack(alignment: .leading, spacing: 8) {

                            Text(localization.localizedString(for: group.titleKey))
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(colors.textSecondary)
                                .padding(.horizontal, 4)

                            VStack(spacing: 0) {
                                let options = ClientSort.allCases.filter { $0.group == group }
                                ForEach(Array(options.enumerated()), id: \.element) { index, option in
                                    if index > 0 {
                                        Divider().overlay(colors.divider).padding(.leading, 52)
                                    }
                                    row(option)
                                }
                            }
                            .background(colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                }
                .padding()
            }
            .background(colors.background.ignoresSafeArea())
            .navigationTitle(localization.localizedString(for: "clients.sort.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(localization.localizedString(for: "common.done")) { dismiss() }
                }
            }
        }
    }

    private func row(_ option: ClientSort) -> some View {

        let isSelected = selection == option.rawValue

        return Button {
            selection = option.rawValue
            dismiss()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: option.icon)
                    .font(.body)
                    .foregroundColor(isSelected ? colors.accent : colors.textSecondary)
                    .frame(width: 24)
                Text(localization.localizedString(for: option.titleKey))
                    .font(.body)
                    .foregroundColor(isSelected ? colors.accent : colors.textPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(colors.accent)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
