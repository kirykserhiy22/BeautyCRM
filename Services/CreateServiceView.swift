//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 03.05.26.
//

import SwiftUI
import SwiftData

struct CreateServiceView: View {
    
    // MARK: - ENV
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var theme: ThemeManager
    
    // MARK: - INPUT
    
    let prefilledName: String
    
    let onCreated: ((Service) -> Void)?
    
    // MARK: - FORM
    
    @State private var name: String
    
    @State private var type: ServicePricingType = .fixed
    
    @State private var price = ""
    
    @State private var error = ""
    
    // MARK: - THEME
    
    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }
    
    // MARK: - INIT
    
    init(
        prefilledName: String = "",
        onCreated: ((Service) -> Void)? = nil
    ) {
        
        self.prefilledName = prefilledName
        self.onCreated = onCreated
        
        _name = State(
            initialValue: prefilledName
        )
    }
    
    // MARK: - BODY
    
    var body: some View {
        
        NavigationStack {
            
            VStack(spacing: 18) {
                
                // NAME
                
                TextField(
                    "Service name",
                    text: $name
                )
                .padding()
                .background(colors.card)
                .cornerRadius(14)
                
                // TYPE
                
                Picker(
                    "Type",
                    selection: $type
                ) {
                    
                    Text("Fixed")
                        .tag(ServicePricingType.fixed)
                    
                    Text("Variable")
                        .tag(ServicePricingType.variable)
                }
                .pickerStyle(.segmented)
                
                // PRICE
                
                if type == .fixed {
                    
                    TextField(
                        "Price",
                        text: $price
                    )
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(colors.card)
                    .cornerRadius(14)
                }
                
                // ERROR
                
                if !error.isEmpty {
                    
                    Text(error)
                        .foregroundColor(colors.danger)
                        .font(.caption)
                }
                
                Spacer()
                
                // SAVE
                
                Button {
                    
                    create()
                    
                } label: {
                    
                    Text("Save")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(colors.buttonPrimary)
                        .cornerRadius(16)
                }
            }
            .padding()
            .background(colors.background)
            .navigationTitle("New Service")
        }
    }
}

// MARK: - LOGIC

private extension CreateServiceView {
    
    func create() {
        
        guard ServiceEngine.validate(name: name) else {
            
            error = "Name required"
            return
        }
        
        guard let userID = appState.session.userID else {
            return
        }
        
        let service = Service(
            userID: userID,
            name: name,
            pricingType: type,
            price: type == .fixed
            ? Double(price)
            : nil
        )
        
        context.insert(service)
        
        try? context.save()
        
        // CALLBACK
        
        onCreated?(service)
        
        dismiss()
    }
}
