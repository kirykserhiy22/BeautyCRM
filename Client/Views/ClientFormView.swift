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
    // Ім'я наявного клієнта, схожого на цього (показуємо попередження)
    @State private var possibleDuplicateName: String?

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
                localization.localizedString(for: "clients.possibleDuplicate.title"),
                isPresented: Binding(
                    get: { possibleDuplicateName != nil },
                    set: { if !$0 { possibleDuplicateName = nil } }
                )
            ) {
                Button(localization.localizedString(for: "clients.possibleDuplicate.save")) {
                    saveClient(allowDuplicate: true)
                }
                Button(localization.localizedString(for: "common.cancel"), role: .cancel) {}
            } message: {
                Text(
                    String(
                        format: localization.localizedString(for: "clients.possibleDuplicate.message"),
                        possibleDuplicateName ?? ""
                    )
                )
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

    var editingClientID: UUID? {
        if case .edit(let client) = mode {
            return client.id
        }
        return nil
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
    
    // Схожий клієнт — не заборона, а питання: майстер вирішує сам
    private func saveClient(allowDuplicate: Bool = false) {

        guard let userID = appState.session.userID else {
            print("NO SESSION USER ID")
            return
        }

        if !allowDuplicate {
            do {
                if let existing = try ClientManager.possibleDuplicate(
                    name: name,
                    phone: phone,
                    instagram: instagram,
                    telegram: telegram,
                    userID: userID,
                    excluding: editingClientID,
                    context: context
                ) {
                    possibleDuplicateName = existing.name
                    return
                }
            } catch {
                SaveErrorReporter.report(error)
                return
            }
        }

        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let phone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let instagram = instagram.trimmingCharacters(in: .whitespacesAndNewlines)
        let telegram = telegram.trimmingCharacters(in: .whitespacesAndNewlines)
        let notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

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

        // SAVE — форма закривається лише після успішного збереження

        if context.saveReportingErrors() {
            dismiss()
        }
    }
}
