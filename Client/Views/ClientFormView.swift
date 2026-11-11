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
    @State private var networks: [NetworkEntry] = []
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
                }
                .brandRows(colors)

                // Майстер сам вибирає, де клієнт: Instagram, Telegram, WhatsApp…
                Section(localization.localizedString(for: "clients.networks")) {

                    ForEach($networks) { $entry in
                        networkRow($entry)
                    }
                    .onDelete { networks.remove(atOffsets: $0) }

                    if let next = availableNetworks(excluding: nil).first {
                        Button {
                            addNetwork(next)
                        } label: {
                            Label(
                                localization.localizedString(for: "clients.network.add"),
                                systemImage: "plus"
                            )
                        }
                        .accessibilityIdentifier("client.network.add")
                    }
                }
                .brandRows(colors)

                Section(localization.localizedString(for: "clients.notes")) {

                    TextField(
                        localization.localizedString(for: "clients.notesPlaceholder"),
                        text: $notes,
                        axis: .vertical
                    )
                    .lineLimit(5)
                }
                .brandRows(colors)

                FormPrimaryButton(
                    title: buttonTitle,
                    isEnabled: !name.trimmingCharacters(in: .whitespaces).isEmpty,
                    colors: colors
                ) {
                    saveClient()
                }
            }
            .brandForm(colors)
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
            .navigationTitle(title)
            .onAppear {
                loadClientIfNeeded()
            }
        }
    }
}

// MARK: - SOCIAL NETWORKS

// Один рядок «соцмережа + нік чи номер»
fileprivate struct NetworkEntry: Identifiable {
    let id = UUID()
    var network: ContactNetwork
    var value: String
}

private extension ClientFormView {

    func networkRow(_ entry: Binding<NetworkEntry>) -> some View {

        HStack(spacing: 10) {

            Menu {
                ForEach(availableNetworks(excluding: entry.wrappedValue.id)) { network in
                    Button {
                        choose(network, for: entry)
                    } label: {
                        Text(network.title)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    ContactNetworkIcon(network: entry.wrappedValue.network, size: 18)
                    Text(entry.wrappedValue.network.title)
                    Image(systemName: "chevron.down")
                        .font(.caption2.bold())
                }
                .foregroundColor(colors.accent)
                .fixedSize()
            }
            .accessibilityIdentifier("client.network.picker")

            TextField(
                localization.localizedString(for: entry.wrappedValue.network.placeholderKey),
                text: entry.value
            )
            .keyboardType(entry.wrappedValue.network.usesPhoneNumber ? .phonePad : .default)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        }
    }

    // Соцмережі, яких ще немає в інших рядках (одна соцмережа — один рядок)
    func availableNetworks(excluding entryID: UUID?) -> [ContactNetwork] {
        let used = Set(networks.filter { $0.id != entryID }.map(\.network))
        return ContactNetwork.allCases.filter { !used.contains($0) }
    }

    func addNetwork(_ network: ContactNetwork) {
        networks.append(NetworkEntry(network: network, value: prefill(for: network)))
    }

    func choose(_ network: ContactNetwork, for entry: Binding<NetworkEntry>) {
        let wasPhoneBased = entry.wrappedValue.network.usesPhoneNumber
        entry.wrappedValue.network = network

        // Нік і номер — різні речі: при зміні типу поле не лишається з чужим значенням
        if wasPhoneBased != network.usesPhoneNumber || entry.wrappedValue.value.isEmpty {
            entry.wrappedValue.value = prefill(for: network)
        }
    }

    // Для WhatsApp і Viber одразу підставляємо телефон клієнта
    func prefill(for network: ContactNetwork) -> String {
        network.usesPhoneNumber ? phone.trimmingCharacters(in: .whitespacesAndNewlines) : ""
    }

    func networkValue(_ network: ContactNetwork) -> String? {
        let value = networks
            .first { $0.network == network }?
            .value
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
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

            // Найчастіше клієнти приходять з Instagram — один порожній рядок одразу
            if networks.isEmpty {
                networks = [NetworkEntry(network: .instagram, value: "")]
            }

        case .edit(let client):

            name = client.name
            phone = client.phone ?? ""
            notes = client.notes ?? ""

            networks = ContactNetwork.allCases.compactMap { network in
                network.value(of: client).map { NetworkEntry(network: network, value: $0) }
            }
        }
    }
    
    // Схожий клієнт — не заборона, а питання: майстер вирішує сам
    private func saveClient(allowDuplicate: Bool = false) {

        guard let userID = appState.session.userID else {
            return
        }

        if !allowDuplicate {
            do {
                if let existing = try ClientManager.possibleDuplicate(
                    name: name,
                    phone: phone,
                    instagram: networkValue(.instagram),
                    telegram: networkValue(.telegram),
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
        let notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        let client: Client

        switch mode {

        // CREATE

        case .create:

            client = Client(
                userID: userID,
                name: name,
                phone: phone.isEmpty ? nil : phone,
                notes: notes.isEmpty ? nil : notes
            )

            context.insert(client)

        // EDIT

        case .edit(let existing):

            client = existing
            client.name = name
            client.phone = phone.isEmpty ? nil : phone
            client.notes = notes.isEmpty ? nil : notes
        }

        // Прибраний рядок соцмережі очищає й поле в картці
        for network in ContactNetwork.allCases {
            network.set(networkValue(network), on: client)
        }

        // SAVE — форма закривається лише після успішного збереження

        if context.saveReportingErrors() {
            dismiss()
        }
    }
}
