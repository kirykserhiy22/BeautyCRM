//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 23.05.26.
//

import SwiftUI
import SwiftData

struct ClientFormView: View {

    // MARK: - MODE

    let mode: ClientFormMode
    var prefilledName: String = ""
    

    // MARK: - ENV

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var theme: ThemeManager

    // MARK: - FORM

    @State private var name = ""
    @State private var phone = ""
    @State private var instagram = ""
    @State private var telegram = ""
    @State private var notes = ""
    @State private var showDuplicateNameAlert = false

    // MARK: - THEME

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    // MARK: - BODY

    var body: some View {

        NavigationStack {

            Form {

                Section(localization.localizedString(for: "clients.info")) {

                    TextField(localization.localizedString(for: "clients.name"), text: $name)

                    TextField(localization.localizedString(for: "clients.phone"), text: $phone)
                        .keyboardType(.phonePad)

                    TextField(localization.localizedString(for: "clients.instagram"), text: $instagram)

                    TextField(localization.localizedString(for: "clients.telegram"), text: $telegram)
                }

                Section(localization.localizedString(for: "clients.notes")) {

                    TextField(
                        localization.localizedString(for: "clients.notesPlaceholder"),
                        text: $notes,
                        axis: .vertical
                    )
                    .lineLimit(5)
                }

                Section {

                    Button {

                        saveClient()

                    } label: {

                        Text(buttonTitle)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert(
                localization.localizedString(for: "clients.duplicateNameTitle"),
                isPresented: $showDuplicateNameAlert
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(localization.localizedString(for: "clients.duplicateNameMessage"))
            }
            .background(colors.secondaryBackground)
            .navigationTitle(title)
            .onAppear {
                loadClientIfNeeded()
            }
        }
        .background(colors.secondaryBackground)
    }
}

// MARK: - HELPERS

private extension ClientFormView {

    var title: String {

        switch mode {

        case .create:
            return localization.localizedString(for: "clients.newTitle")

        case .edit:
            return localization.localizedString(for: "clients.editTitle")
        }
    }

    var buttonTitle: String {

        switch mode {

        case .create:
            return localization.localizedString(for: "clients.createButton")

        case .edit:
            return localization.localizedString(for: "clients.saveChanges")
        }
    }

    func loadClientIfNeeded() {

        switch mode {

        case .create:

            if name.isEmpty {
                name = prefilledName
            }

        case .edit(let client):

            name = client.name
            phone = client.phone ?? ""
            instagram = client.instagram ?? ""
            telegram = client.telegram ?? ""
            notes = client.notes ?? ""
        }
    }
    
    func hasDuplicateName(_ name: String, userID: String) throws -> Bool {
        let normalizedName = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)

        var descriptor = FetchDescriptor<Client>(
            predicate: #Predicate { client in
                client.userID == userID
            }
        )

        descriptor.fetchLimit = 500

        let clients = try context.fetch(descriptor)

        let currentClientID: UUID?
        if case .edit(let client) = mode {
            currentClientID = client.id
        } else {
            currentClientID = nil
        }

        return clients.contains { client in
            guard client.id != currentClientID else { return false }

            let existingName = client.name
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)

            return existingName == normalizedName
        }
    }

    private func saveClient() {

        do {
            guard let userID = appState.session.userID else {
                print("NO SESSION USER ID")
                return
            }

            do {
                if try hasDuplicateName(name, userID: userID) {
                    showDuplicateNameAlert = true
                    return
                }
            } catch {
                print("Duplicate client check error:", error)
                return
            }

            switch mode {
                

            // CREATE

            case .create:

                

                let client = Client(
                    userID: userID,
                    name: name,
                    phone: phone.isEmpty ? nil : phone,
                    instagram: instagram.isEmpty ? nil : instagram,
                    telegram: telegram.isEmpty ? nil : telegram,
                    notes: notes.isEmpty ? nil : notes
                )

                context.insert(client)

            // EDIT

            case .edit(let client):

                client.name = name
                client.phone = phone.isEmpty ? nil : phone
                client.instagram = instagram.isEmpty ? nil : instagram
                client.telegram = telegram.isEmpty ? nil : telegram
                client.notes = notes.isEmpty ? nil : notes
            }

            // SAVE

            try context.save()

            dismiss()

        } catch {

            print("Save client error:", error)
        }
    }
}
