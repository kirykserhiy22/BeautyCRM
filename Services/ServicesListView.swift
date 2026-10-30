//
//  ServicesListView.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 03.05.26.
//


import SwiftUI
import SwiftData

struct ServicesListView: View {
    
    // MARK: - ENV
    @EnvironmentObject var currency: CurrencyManager
    @Environment(\.modelContext) private var context
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager
    
    // MARK: - DATA
    
    @Query(
        filter: #Predicate<Service> { $0.deletedAt == nil },
        sort: \Service.createdAt,
        order: .reverse
    )
    private var services: [Service]

    @EnvironmentObject var appState: AppState
    
    private var userServices: [Service] {

        guard let userID = appState.session.userID else {
            return []
        }

        return services.filter {
            $0.userID == userID
        }
    }
    // MARK: - UI
    
    @State private var showCreate = false
    @State private var selectedService: Service?
    
    // для розгортання карточок
    @State private var expandedServiceID: UUID?
    
    // MARK: - THEME
    
    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }
    
    // MARK: - BODY
    
    var body: some View {
        
        NavigationStack {
            
            ZStack(alignment: .bottomTrailing) {
                
                
                
                ScrollView {
                    
                    LazyVStack(spacing: 14) {
                        
                        ForEach(userServices, id: \.id) { service in
                            
                            serviceCard(service)
                        }
                    }
                    .padding()
                }
                
                // FLOATING BUTTON
                
                Button {
                    showCreate = true
                } label: {
                    
                    Image(systemName: "plus")
                        .font(.title2.bold())
                        .foregroundColor(colors.background)
                        .padding()
                        .background(colors.floatingButton)
                        .clipShape(Circle())
                        .shadow(
                            color: colors.shadow,
                            radius: 8,
                            y: 4
                        )
                }
                .padding()
            }
            .navigationTitle("services.title")
            
            // CREATE
            
            .sheet(isPresented: $showCreate) {
                
                CreateServiceView()
                    .environmentObject(theme)
            }
            
            // EDIT
            
            .sheet(item: $selectedService) { service in
                
                EditServiceView(service: service)
                    .environmentObject(theme)
            }
        }
    }
}

// MARK: - COMPONENTS

private extension ServicesListView {
    
    func serviceCard(
        _ service: Service
    ) -> some View {
        
        let isExpanded = expandedServiceID == service.id
        
        return VStack(
            alignment: .leading,
            spacing: 14
        ) {
            
            // HEADER
            
            Button {
                
                withAnimation(
                    .spring(
                        response: 0.3,
                        dampingFraction: 0.82
                    )
                ) {
                    
                    if expandedServiceID == service.id {
                        expandedServiceID = nil
                    } else {
                        expandedServiceID = service.id
                    }
                }
                
            } label: {
                
                HStack(alignment: .top) {
                    
                    VStack(
                        alignment: .leading,
                        spacing: 6
                    ) {
                        
                        Text(service.name)
                            .font(.headline)
                            .foregroundColor(colors.textPrimary)
                        
                        Text(priceText(service))
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
            
            // EXPANDED CONTENT
            
            if isExpanded {
                
                VStack(spacing: 14) {
                    
                    Divider()
                        .overlay(colors.divider)
                    
                    HStack(spacing: 12) {
                        
                        // EDIT
                        
                        Button {
                            
                            selectedService = service
                            
                        } label: {
                            
                            Label("services.edit", systemImage: "pencil")
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(colors.accent)
                        
                        // DELETE
                        
                        Button(
                            role: .destructive
                        ) {
                            
                            delete(service)
                            
                        } label: {
                            
                            Label("services.delete", systemImage: "trash")
                            .frame(maxWidth: .infinity)
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
        .cornerRadius(22)
        .shadow(
            color: colors.shadow,
            radius: 6,
            y: 3
        )
    }
}

// MARK: - LOGIC

private extension ServicesListView {
    
    func delete(
        _ service: Service
    ) {
        
        service.markDeleted()
        
        context.saveReportingErrors()
    }
    
    func priceText(
        _ service: Service
    ) -> String {
        
        
        switch service.pricingType {
            
        case .fixed:
            
            return currency.format(
                service.price ?? 0
            )
            
        case .variable:
            return localization.localizedString(
                for: "services.variablePrice"
            )
        }
    }
}
