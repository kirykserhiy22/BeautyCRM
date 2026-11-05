//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 03.05.26.
//

import SwiftUI
import SwiftData

struct EditServiceView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject var localization: LocalizationManager
    let service: Service
    @EnvironmentObject var theme: ThemeManager

    // Форма працює з копією: у прайс зміни потрапляють тільки після «Зберегти»
    @State private var name: String
    @State private var isVariable: Bool
    @State private var price: Decimal?

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    private var canSave: Bool {
        // Без назви, а у фіксованої послуги ще й без правильної ціни, не зберігається
        ServiceEngine.validate(name: name) && (isVariable || price != nil)
    }

    init(service: Service) {
        self.service = service
        _name = State(initialValue: service.name)
        _isVariable = State(initialValue: service.pricingType == .variable)
        _price = State(initialValue: service.price)
    }

    var body: some View {
        
        NavigationStack {
            
            Form {
                
                TextField("services.name", text: $name)
                
                if !isVariable {
                    MoneyField(
                        placeholder: localization.localizedString(for: "services.price"),
                        value: $price
                    )
                }
                
                Toggle("services.variablePrice", isOn: $isVariable)
                
                Button("services.save") {
                    save()
                }
                .disabled(!canSave)
            }
            .navigationTitle("services.editTitle")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func save() {
        service.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        service.pricingType = isVariable ? .variable : .fixed
        service.price = price

        if context.saveReportingErrors() {
            dismiss()
        }
    }
}
