//
//  ContactNetwork.swift
//  BeautyCRM
//
//  Соцмережі й месенджери клієнта: назва, значок, поле в моделі й посилання.
//  Новий месенджер додається тут одним `case` (і полем у `Client`).
//

import SwiftUI

enum ContactNetwork: String, CaseIterable, Identifiable {

    case instagram
    case telegram
    case whatsapp
    case viber
    case messenger

    var id: String { rawValue }

    // Назви брендів не перекладаються
    var title: String {
        switch self {
        case .instagram: return "Instagram"
        case .telegram: return "Telegram"
        case .whatsapp: return "WhatsApp"
        case .viber: return "Viber"
        case .messenger: return "Messenger"
        }
    }

    // WhatsApp і Viber прив'язані до номера, решта — до ніка
    var usesPhoneNumber: Bool {
        self == .whatsapp || self == .viber
    }

    var placeholderKey: String {
        usesPhoneNumber ? "clients.network.number" : "clients.network.nick"
    }

    func value(of client: Client) -> String? {
        switch self {
        case .instagram: return client.instagram
        case .telegram: return client.telegram
        case .whatsapp: return client.whatsapp
        case .viber: return client.viber
        case .messenger: return client.messenger
        }
    }

    func set(_ value: String?, on client: Client) {
        switch self {
        case .instagram: client.instagram = value
        case .telegram: client.telegram = value
        case .whatsapp: client.whatsapp = value
        case .viber: client.viber = value
        case .messenger: client.messenger = value
        }
    }

    func url(for value: String) -> URL? {
        switch self {
        case .instagram: return ContactLinks.instagram(value)
        case .telegram: return ContactLinks.telegram(value)
        case .whatsapp: return ContactLinks.whatsapp(value)
        case .viber: return ContactLinks.viber(value)
        case .messenger: return ContactLinks.messenger(value)
        }
    }
}


// Простий одноколірний значок у стилі додатку (логотипів брендів в iOS немає)
struct ContactNetworkIcon: View {

    let network: ContactNetwork
    var size: CGFloat = 22

    var body: some View {

        Group {
            switch network {

            case .instagram:
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.3)
                        .stroke(lineWidth: size * 0.1)
                    Circle()
                        .stroke(lineWidth: size * 0.1)
                        .frame(width: size * 0.42, height: size * 0.42)
                    Circle()
                        .frame(width: size * 0.12, height: size * 0.12)
                        .offset(x: size * 0.24, y: -size * 0.24)
                }
                .frame(width: size * 0.9, height: size * 0.9)

            case .telegram:
                Image(systemName: "paperplane.fill")
                    .font(.system(size: size * 0.85))

            case .whatsapp:
                bubble("bubble.left", inner: "phone.fill")

            case .viber:
                bubble("bubble.right", inner: "phone.fill")

            case .messenger:
                bubble("bubble.left", inner: "bolt.fill")
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func bubble(_ shape: String, inner: String) -> some View {
        ZStack {
            Image(systemName: shape)
                .font(.system(size: size * 0.95))
            Image(systemName: inner)
                .font(.system(size: size * 0.38, weight: .bold))
                .offset(y: -size * 0.05)
        }
    }
}
