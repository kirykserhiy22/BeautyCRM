//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 13.05.26.
//
import SwiftUI
import SwiftData

struct ServiceRow: View {

    // MARK: - ENVIRONMENT
    @EnvironmentObject var currencyManager: CurrencyManager
    @Environment(\.modelContext) private var context
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager

    // MARK: - DATA

    let service: Service
    let onEdit: () -> Void

    // MARK: - UI

    @State private var isExpanded = false

    // MARK: - THEME

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    // MARK: - BODY

    var body: some View {

        VStack(alignment: .leading, spacing: 14) {

            // HEADER

            Button {

                withAnimation(.spring(
                    response: 0.3,
                    dampingFraction: 0.82
                )) {
                    isExpanded.toggle()
                }

            } label: {

                HStack {

                    VStack(
                        alignment: .leading,
                        spacing: 6
                    ) {

                        Text(service.name)
                            .font(.headline)
                            .foregroundColor(colors.textPrimary)

                        Text(priceText)
                            .font(.subheadline)
                            .foregroundColor(colors.textSecondary)
                    }

                    Spacer()

                    Image(systemName:
                            isExpanded
                          ? "chevron.up"
                          : "chevron.down"
                    )
                    .font(.caption.bold())
                    .foregroundColor(colors.textSecondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // EXPANDED

            if isExpanded {

                VStack(spacing: 14) {

                    Divider()

                    HStack(spacing: 12) {

                        // EDIT

                        Button {

                            onEdit()

                        } label: {

                            Label("services.edit", systemImage: "pencil")
                        }
                        .buttonStyle(.bordered)

                        // DELETE

                        Button {

                            deleteService()

                        } label: {

                            Label("services.delete", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                        .tint(colors.buttonDestructive)
                    }
                }
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(
                            with: .move(edge: .top)
                        ),
                        removal: .opacity
                    )
                )
            }
        }
        .padding()
        .background(colors.card)
        .cornerRadius(18)
    }
}

// MARK: - HELPERS

private extension ServiceRow {

    var priceText: String {

        switch service.pricingType {

        case .fixed:
            return currencyManager.format(service.price ?? 0)

        case .variable:
            return localization.localizedString(
                for: "services.variablePrice"
            )
        }
    }

    func deleteService() {

        service.markDeleted()

        try? context.save()
    }
}
