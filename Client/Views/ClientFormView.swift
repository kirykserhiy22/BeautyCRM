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

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var theme: ThemeManager

    // MARK: - FORM

    @State private var name = ""
    @State private var phone = ""
    @State private var instagram = ""
    @State private var telegram = ""
    @State private var notes = ""

    // MARK: - THEME

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    // MARK: - BODY

    var body: some View {

        NavigationStack {

            Form {

                Section("Client Info") {

                    TextField("Name", text: $name)

                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)

                    TextField("Instagram", text: $instagram)

                    TextField("Telegram", text: $telegram)
                }

                Section("Notes") {

                    TextField(
                        "Client notes...",
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
            .navigationTitle(title)
            .onAppear {
                loadClientIfNeeded()
            }
        }
    }
}

// MARK: - HELPERS

private extension ClientFormView {

    var title: String {

        switch mode {

        case .create:
            return "New Client"

        case .edit:
            return "Edit Client"
        }
    }

    var buttonTitle: String {

        switch mode {

        case .create:
            return "Create Client"

        case .edit:
            return "Save Changes"
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

    private func saveClient() {

        do {

            switch mode {

            // CREATE

            case .create:

                guard let userID = appState.session.userID else {

                    print("NO SESSION USER ID")

                    return
                }

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
