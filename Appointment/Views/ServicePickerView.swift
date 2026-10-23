//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 03.05.26.
//

import SwiftUI
import SwiftData

struct ServicePickerView: View {
    
    // MARK: - ENV
    @EnvironmentObject var currencyManager: CurrencyManager
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var appState: AppState
    
    // MARK: - DATA
    
    @Query private var services: [Service]
    private var userServices: [Service] {

        guard let userID = appState.session.userID else {
            return []
        }

        return services.filter {
            $0.userID == userID
        }
    }
    
    @Binding var selectedIDs: Set<UUID>
    @Binding var customPrices: [UUID: Decimal]
    
    // MARK: - UI
    
    @State private var search = ""
    @State private var showCreateService = false
    @State private var serviceNameForCreation = ""
    
    // MARK: - THEME
    
    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }
    
    // MARK: - BODY
    
    var body: some View {
        
        NavigationStack {
            
            ZStack {
                
                                
                VStack(spacing: 0) {
                    
                    // SEARCH
                    
                    searchBar
                    addServiceButton
                    
                    // CONTENT
                    
                    ScrollView {
                        
                        LazyVStack(
                            spacing: 12
                        ) {
                            
                            ForEach(
                                filteredServices,
                                id: \.id
                            ) { service in
                                
                                serviceCard(service)
                            }
                            
                            // CREATE NEW SERVICE
                            
                            if filteredServices.isEmpty &&
                                !search.isEmpty {
                                
                                createServiceCard
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(
                localization.localizedString(for: "services.selectTitle")
            )
            .toolbar {
                
                ToolbarItem(
                    placement: .topBarTrailing
                ) {
                    
                    Button(
                        localization.localizedString(for: "services.done")
                    ) {
                        dismiss()
                    }
                    .foregroundColor(colors.accent)
                }
            }
            .sheet(isPresented: $showCreateService) {
                
                CreateServiceView(
                    prefilledName: serviceNameForCreation
                ) { newService in
                    
                    // auto select
                    
                    selectedIDs.insert(newService.id)
                    
                    // variable service
                    
                    if newService.pricingType == .variable {
                        customPrices[newService.id] = 0
                    }
                    
                    // clear search
                    
                    search = ""
                }
                .environmentObject(theme)
            }
        }
    }
}

// MARK: - COMPONENTS

private extension ServicePickerView {
    var addServiceButton: some View {

        Button {

            serviceNameForCreation = ""
            showCreateService = true

        

        } label: {

            HStack {

                Image(systemName: "plus.circle.fill")

                Text(
                    localization.localizedString(for: "services.addNew")
                )

                Spacer()

            }
            .font(.subheadline.weight(.medium))
            .foregroundColor(colors.accent)
            .padding()
            .background(colors.card)
            .cornerRadius(14)
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }
    
    var searchBar: some View {
        
        HStack(spacing: 10) {
            
            Image(systemName: "magnifyingglass")
                .foregroundColor(colors.textMuted)
            
            TextField(
                localization.localizedString(for: "services.searchPlaceholder"),
                text: $search
            )
            .foregroundColor(colors.textPrimary)
        }
        .padding()
        .background(colors.inputBackground)
        .cornerRadius(16)
        .padding()
    }
    
    func serviceCard(
        _ service: Service
    ) -> some View {
        
        Button {
            
            toggle(service)
            
        } label: {
            
            HStack(spacing: 14) {
                
                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {
                    
                    Text(service.name)
                        .font(.headline)
                        .foregroundColor(colors.textPrimary)
                    
                    Text(priceText(service))
                        .font(.caption)
                        .foregroundColor(colors.textSecondary)
                }
                
                Spacer()
                
                if selectedIDs.contains(service.id) {
                    
                    Image(
                        systemName:
                            "checkmark.circle.fill"
                    )
                    .font(.title3)
                    .foregroundColor(colors.accent)
                }
            }
            .padding()
            .background(colors.card)
            .cornerRadius(18)
            .shadow(
                color: colors.shadow,
                radius: 4,
                y: 2
            )
        }
        .buttonStyle(.plain)
    }
    
    var createServiceCard: some View {
        
        Button {

            serviceNameForCreation = search
            showCreateService = true

        } label: {
            
            HStack(spacing: 12) {
                
                Image(
                    systemName:
                        "plus.circle.fill"
                )
                .foregroundColor(colors.accent)
                
                Text(
                    String(
                        format: localization.localizedString(for: "services.createNamed"),
                        locale: localization.locale,
                        search
                    )
                )
                .foregroundColor(colors.textPrimary)
                
                Spacer()
            }
            .padding()
            .background(colors.card)
            .cornerRadius(18)
            .shadow(
                color: colors.shadow,
                radius: 4,
                y: 2
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - LOGIC

private extension ServicePickerView {
    
    var filteredServices: [Service] {

        if search.isEmpty {
            return userServices
        }

        return userServices.filter {
            $0.name
                .lowercased()
                .contains(search.lowercased())
        }
    }
    
    func toggle(
        _ service: Service
    ) {
        
        if selectedIDs.contains(service.id) {
            
            selectedIDs.remove(service.id)
            
            customPrices.removeValue(
                forKey: service.id
            )
            
        } else {
            
            selectedIDs.insert(service.id)
            
            if service.pricingType == .variable {
                
                customPrices[service.id] = 0
            }
        }
    }
    
    func priceText(
        _ service: Service
    ) -> String {
        
        switch service.pricingType {
            
        case .fixed:
            
            return currencyManager.format(service.price ?? 0)
            
        case .variable:
            return localization.localizedString(
                for: "services.variablePrice"
            )
        }
    }
}
