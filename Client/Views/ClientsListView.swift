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
    @EnvironmentObject var localization: LocalizationManager
    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }
    @State private var selectedClientIDs: Set<UUID> = []
    @State private var clientToOpen: Client?
    @State private var showDeleteConfirmation = false

    @Environment(\.modelContext) private var modelContext

    private var isSelectionMode: Bool {
        !selectedClientIDs.isEmpty
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
                                ClientRowView(client: client)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        selectedClientIDs.contains(client.id)
                                            ? colors.accent.opacity(0.18)
                                            : colors.card
                                    )
                                    .cornerRadius(18)
                                    .overlay(alignment: .trailing) {
                                        if selectedClientIDs.contains(client.id) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(colors.accent)
                                                .padding(.trailing, 14)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if isSelectionMode {
                                            toggleSelection(for: client)
                                        } else {
                                            clientToOpen = client
                                        }
                                    }
                                    .onLongPressGesture(minimumDuration: 0.5) {
                                        if !isSelectionMode {
                                            toggleSelection(for: client)
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }

                if isSelectionMode {
                    HStack(spacing: 16) {
                        Button {
                            selectedClientIDs.removeAll()
                        } label: {
                            Text(localization.localizedString(for: "common.cancel"))
                        }

                        Spacer()

                        Text("\(selectedClientIDs.count)")
                            .font(.headline)

                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label(
                                localization.localizedString(for: "common.delete"),
                                systemImage: "trash"
                            )
                        }
                    }
                    .padding()
                    .background(colors.card)
                    .cornerRadius(18)
                    .padding()
                } else {
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
            .navigationTitle(localization.localizedString(for: "clients.title"))
            .sheet(isPresented: $showAddClient) {
                ClientFormView(mode: .create)
            }
            .navigationDestination(item: $clientToOpen) { client in
                ClientProfileView(client: client)
            }
            .confirmationDialog(
                localization.localizedString(for: "clients.deleteConfirmationTitle"),
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(
                    localization.localizedString(for: "common.delete"),
                    role: .destructive
                ) {
                    deleteSelectedClients()
                }

                Button(
                    localization.localizedString(for: "common.cancel"),
                    role: .cancel
                ) {}
            } message: {
                Text(
                    localization.localizedString(for: "clients.deleteConfirmationMessage")
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
                localization.localizedString(for: "clients.search"),
                text: $searchText
            )
            .foregroundColor(colors.textPrimary)
        }
        .padding()
        .background(colors.inputBackground)
        .cornerRadius(18)
        .padding(.horizontal)
    }
   

        func toggleSelection(for client: Client) {
            if selectedClientIDs.contains(client.id) {
                selectedClientIDs.remove(client.id)
            } else {
                selectedClientIDs.insert(client.id)
            }
        }

        func deleteSelectedClients() {
            let clientsToDelete = userClients.filter {
                selectedClientIDs.contains($0.id)
            }

            for client in clientsToDelete {
                modelContext.delete(client)
            }

            do {
                try modelContext.save()
                selectedClientIDs.removeAll()
            } catch {
                print("Delete clients error:", error)
            }
        }
    }

