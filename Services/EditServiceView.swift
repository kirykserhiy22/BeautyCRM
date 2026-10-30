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
    @Bindable var service: Service
    @EnvironmentObject var theme: ThemeManager
    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }
    var body: some View {
        
        NavigationStack {
            
            Form {
                
                TextField("services.name", text: $service.name)
                
                if service.pricingType == .fixed {
                    MoneyField(
                        placeholder: localization.localizedString(for: "services.price"),
                        value: $service.price
                    )
                }
                
                Toggle("services.variablePrice", isOn: Binding(
                    get: { service.pricingType == .variable },
                    set: { isOn in
                        service.pricingType = isOn ? .variable : .fixed
                    }
                ))
                
                Button("services.save") {
                    if context.saveReportingErrors() {
                        dismiss()
                    }
                }
                // Фіксована послуга без правильної ціни не зберігається
                .disabled(service.pricingType == .fixed && service.price == nil)
            }
            .navigationTitle("services.editTitle")
        }
    }
}
