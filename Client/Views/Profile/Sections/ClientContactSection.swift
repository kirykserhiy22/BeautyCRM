//
//  ClientContactSection.swift
//  BeautyCRM
//
//  Круглі кнопки зв'язку з клієнтом: лише ті, що заповнені в картці.
//

import SwiftUI

struct ClientContactSection: View {

    let client: Client

    @EnvironmentObject var theme: ThemeManager

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    private struct Contact: Identifiable {
        let id: String
        let network: ContactNetwork?   // nil — телефон
        let value: String
        let url: URL?

        var label: String {
            network.map { "\($0.title) \(value)" } ?? value
        }
    }

    private var contacts: [Contact] {

        var result: [Contact] = []

        if let phone = client.phone {
            result.append(Contact(id: "phone", network: nil, value: phone, url: ContactLinks.phone(phone)))
        }

        for network in ContactNetwork.allCases {
            if let value = network.value(of: client) {
                result.append(Contact(id: network.rawValue, network: network, value: value, url: network.url(for: value)))
            }
        }

        return result
    }

    var body: some View {

        if !contacts.isEmpty {

            // На вузькому екрані шість кнопок не влізуть у рядок — тоді гортаються
            ViewThatFits(in: .horizontal) {

                buttons

                ScrollView(.horizontal, showsIndicators: false) {
                    buttons
                        .padding(.horizontal, 2)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var buttons: some View {

        HStack(spacing: 12) {
            ForEach(contacts) { contact in
                contactButton(contact)
            }
        }
    }

    // Довгий дотик — скопіювати номер чи нік, щоб продиктувати або вставити
    @ViewBuilder
    private func contactButton(_ contact: Contact) -> some View {

        let circle = icon(for: contact)
            .foregroundColor(contact.url == nil ? colors.textSecondary : colors.accent)
            .frame(width: 52, height: 52)
            .background(Circle().fill(colors.card))

        Group {
            if let url = contact.url {
                Link(destination: url) { circle }
            } else {
                circle
            }
        }
        .accessibilityLabel(contact.label)
        .accessibilityIdentifier("client.contact.\(contact.id)")
        .contextMenu {
            Button {
                UIPasteboard.general.string = contact.value
            } label: {
                Label(contact.label, systemImage: "doc.on.doc")
            }
        }
    }

    @ViewBuilder
    private func icon(for contact: Contact) -> some View {

        if let network = contact.network {
            ContactNetworkIcon(network: network)
        } else {
            Image(systemName: "phone.fill")
                .font(.title3)
        }
    }
}
