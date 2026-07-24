//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 30.04.26.
//
import SwiftUI
import SwiftData


struct ClientsListView: View {
    
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var appState: AppState
    
    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }
    
    
    @Query(sort: \Client.createdAt, order: .reverse)
    private var clients: [Client]
    
    
    @State private var searchText = ""
    @State private var showAddClient = false
    
    
    private var userClients: [Client] {
        
        guard let userID = appState.session.userID else {
            return []
        }
        
        return clients.filter {
            $0.userID == userID
        }
    }
    
    
    private var filteredClients: [Client] {
        
        guard !searchText.isEmpty else {
            return userClients
        }
        
        return userClients.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    
    var body: some View {
        
        NavigationStack {
            
            ZStack(alignment: .bottomTrailing) {
                
                
                colors.background
                    .ignoresSafeArea()
                
                
                VStack(spacing: 14) {
                    
                    
                    searchBar
                    
                    
                    ScrollView {

                        LazyVStack(spacing: 14) {

                            ForEach(filteredClients) { client in
                                
                                NavigationLink {
                                    ClientProfileView(client: client)
                                } label: {
                                    ClientRowView(client: client)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(colors.card)
                                        .cornerRadius(18)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                
                Button {
                    showAddClient = true
                    
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
            .navigationTitle("Clients")
            .sheet(isPresented: $showAddClient) {
                
                ClientFormView(
                    mode: .create
                )
            }
        }
    }
}
private extension ClientsListView {
    
    
    var searchBar: some View {
        
        HStack {
            
            Image(systemName: "magnifyingglass")
                .foregroundColor(colors.textSecondary)
            
            
            TextField(
                "Search clients...",
                text: $searchText
            )
            .foregroundColor(colors.textPrimary)
        }
        .padding()
        .background(colors.inputBackground)
        .cornerRadius(18)
        .padding(.horizontal)
    }
}
