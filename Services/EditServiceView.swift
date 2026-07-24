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
    
    @Bindable var service: Service
    @EnvironmentObject var theme: ThemeManager
    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }
    var body: some View {
        
        NavigationStack {
            
            Form {
                
                TextField("Service name", text: $service.name)
                
                if service.pricingType == .fixed {
                    TextField("Price", value: $service.price, format: .number)
                }
                
                Toggle("Variable price", isOn: Binding(
                    get: { service.pricingType == .variable },
                    set: { isOn in
                        service.pricingType = isOn ? .variable : .fixed
                    }
                ))
                
                Button("Save") {
                    try? context.save()
                    dismiss()
                }
            }
            .navigationTitle("Edit Service")
        }
    }
}
