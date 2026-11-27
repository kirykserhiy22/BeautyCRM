//
//  RefundSheet.swift
//  BeautyCRM
//
//  Повернення коштів за завершений запис: сума й причина. Аналітика рахує оплату мінус повернення.
//

import SwiftUI
import SwiftData


struct RefundSheet: View {

    let appointment: Appointment

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var currency: CurrencyManager

    @State private var amount: Decimal?
    @State private var reason = ""

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    private var paid: Decimal {
        appointment.finalPrice ?? appointment.totalFinalPrice
    }

    private var canSave: Bool {
        guard let amount else { return false }
        return amount > 0 && amount <= paid
    }

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(alignment: .leading, spacing: 18) {

                    Text(String(
                        format: localization.localizedString(for: "refund.paid"),
                        currency.format(paid)
                    ))
                    .font(.subheadline)
                    .foregroundColor(colors.textSecondary)

                    VStack(alignment: .leading, spacing: 8) {
                        FormSectionTitle(text: localization.localizedString(for: "refund.amount"), colors: colors)
                        MoneyField(placeholder: localization.localizedString(for: "refund.amountPlaceholder"), value: $amount)
                            .accessibilityIdentifier("refund.amount")
                        if let amount, amount > paid {
                            Text(localization.localizedString(for: "appointment.error.refundTooLarge"))
                                .font(.caption)
                                .foregroundColor(colors.danger)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        FormSectionTitle(text: localization.localizedString(for: "refund.reason"), colors: colors)
                        TextField(
                            localization.localizedString(for: "refund.reasonPlaceholder"),
                            text: $reason,
                            axis: .vertical
                        )
                        .lineLimit(1...4)
                        .padding()
                        .background(colors.card)
                        .cornerRadius(14)
                        .accessibilityIdentifier("refund.reason")
                    }

                    if let amount, amount > 0, amount <= paid {
                        HStack {
                            Text(localization.localizedString(for: "refund.kept"))
                                .font(.headline)
                            Spacer()
                            Text(currency.format(paid - amount))
                                .font(.title3.bold())
                        }
                    }

                    Button {
                        save(amount)
                    } label: {
                        Text(localization.localizedString(for: "common.save"))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canSave ? colors.buttonPrimary : colors.buttonSecondary)
                            .foregroundColor(canSave ? .white : colors.textSecondary)
                            .cornerRadius(14)
                    }
                    .disabled(!canSave)
                    .accessibilityIdentifier("refund.save")

                    if appointment.refundAmount != nil {
                        Button(role: .destructive) {
                            save(nil)
                        } label: {
                            Text(localization.localizedString(for: "refund.remove"))
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .keyboardDoneButton()
            .background(colors.background.ignoresSafeArea())
            .navigationTitle(localization.localizedString(for: "refund.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localization.localizedString(for: "common.cancel")) { dismiss() }
                }
            }
        }
        .onAppear {
            amount = appointment.refundAmount
            reason = appointment.refundReason ?? ""
        }
    }

    private func save(_ value: Decimal?) {
        switch AppointmentEngine.refund(appointment: appointment, amount: value, reason: reason) {
        case .success:
            context.saveReportingErrors()
            dismiss()
        case .failure:
            break
        }
    }
}
