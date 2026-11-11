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
    @EnvironmentObject var localization: LocalizationManager

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    private struct Contact: Identifiable {
        let id: String
        let icon: String
        let label: String
        let url: URL?
    }

    private var contacts: [Contact] {

        var result: [Contact] = []

        if let phone = client.phone {
            result.append(Contact(id: "phone", icon: "phone.fill", label: phone, url: ContactLinks.phone(phone)))
        }

        if let instagram = client.instagram {
            result.append(Contact(id: "instagram", icon: "camera.fill", label: "Instagram \(instagram)", url: ContactLinks.instagram(instagram)))
        }

        if let telegram = client.telegram {
            result.append(Contact(id: "telegram", icon: "paperplane.fill", label: "Telegram \(telegram)", url: ContactLinks.telegram(telegram)))
        }

        return result
    }

    var body: some View {

        if !contacts.isEmpty {

            HStack(spacing: 14) {

                ForEach(contacts) { contact in
                    contactButton(contact)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // Довгий дотик — скопіювати номер чи нік, щоб продиктувати або вставити
    @ViewBuilder
    private func contactButton(_ contact: Contact) -> some View {

        let circle = Image(systemName: contact.icon)
            .font(.title3)
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
                UIPasteboard.general.string = copyText(for: contact)
            } label: {
                Label(copyText(for: contact), systemImage: "doc.on.doc")
            }
        }
    }

    private func copyText(for contact: Contact) -> String {

        switch contact.id {
        case "instagram": return client.instagram ?? ""
        case "telegram": return client.telegram ?? ""
        default: return client.phone ?? ""
        }
    }
}
