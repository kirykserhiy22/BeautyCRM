//
//  MoneyField.swift
//  BeautyCRM
//
//  Поле для суми. Читає введене через AppFormatting.parseMoney:
//  неправильний текст підсвічується червоним і дає nil, а не 0.
//

import SwiftUI


struct MoneyField: View {

    let placeholder: String

    // nil — поле порожнє або там не сума
    @Binding var value: Decimal?

    @EnvironmentObject var theme: ThemeManager

    @State private var text = ""

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    var body: some View {

        TextField(placeholder, text: $text)
            .keyboardType(.decimalPad)
            .textFieldStyle(.roundedBorder)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Self.isInvalid(text) ? colors.danger : .clear, lineWidth: 1.5)
            )
            .onAppear {
                text = value.map { AppFormatting.moneyInput($0) } ?? ""
            }
            .onChange(of: text) {
                value = AppFormatting.parseMoney(text)
            }
    }


    // Щось введено, але це не сума
    static func isInvalid(_ text: String) -> Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && AppFormatting.parseMoney(text) == nil
    }
}
