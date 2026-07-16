//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 30.04.26.
//
import SwiftUI
import SwiftData

struct ClientsListView: View {
    
    @Environment(\.modelContext) private var context
    
    @Query(sort: \Client.createdAt, order: .reverse)
    private var clients: [Client]
    @EnvironmentObject var theme: ThemeManager
    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }
    @State private var searchText: String = ""
    @State private var showAddClient: Bool = false
    
    var filteredClients: [Client] {
        guard !searchText.isEmpty else { return clients }
        return clients.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        
        NavigationStack {
            
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                VStack {
                    
                    // 🔍 SEARCH
                    TextField("Search clients...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    
                    // 📋 LIST
                    List(filteredClients) { client in
                        
                        NavigationLink {
                            ClientProfileView(client: client)
                        } label: {
                            ClientRowView(client: client)
                        }
                    }
                    .listStyle(.plain)
                }
                
                // ➕ FLOATING BUTTON
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        
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
                }
            }
            .navigationTitle("Clients")
            .sheet(isPresented: $showAddClient) {
                CreateClientView()
            }
        }
    }
}
