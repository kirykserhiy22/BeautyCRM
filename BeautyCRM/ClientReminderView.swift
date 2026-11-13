//
//  ClientReminderView.swift
//  BeautyCRM
//
//  «Нагадати клієнту»: готовий текст за шаблоном (можна змінити перед
//  надсиланням) і вибір месенджера. Після надсилання запис позначається.
//

import SwiftUI
import SwiftData
import UIKit


// Текст нагадування для конкретного запису — спільний для вікна й попереднього перегляду
@MainActor
enum ClientReminderText {

    static func defaultTemplate(_ localization: LocalizationManager) -> String {
        localization.localizedString(for: "clientMessage.template")
    }

    static func template(profile: UserProfile?, localization: LocalizationManager) -> String {
        let saved = profile?.reminderTemplate?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return saved.isEmpty ? defaultTemplate(localization) : saved
    }

    static func signature(profile: UserProfile?) -> String? {
        let saved = profile?.reminderSignature?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return saved.isEmpty ? profile?.firstName : saved
    }

    static func values(
        clientName: String,
        start: Date,
        services: [String],
        price: String,
        address: String?,
        localization: LocalizationManager
    ) -> ClientMessageTemplate.Values {
        [
            // Звертаємось на ім'я, без прізвища
            .name: clientName.split(separator: " ").first.map(String.init) ?? clientName,
            .date: AppFormatting.pattern(
                localization.localizedString(for: "clientMessage.dateFormat"),
                start,
                locale: localization.locale
            ),
            .time: AppFormatting.clock(start),
            .services: services.joined(separator: ", "),
            .price: price,
            .address: address ?? ""
        ]
    }

    static func text(
        appointment: Appointment,
        profile: UserProfile?,
        localization: LocalizationManager,
        currency: CurrencyManager
    ) -> String {
        ClientMessageTemplate.render(
            template: template(profile: profile, localization: localization),
            values: values(
                clientName: appointment.clientName,
                start: appointment.startDate,
                services: appointment.services.map(\.serviceName),
                price: currency.format(appointment.totalPlannedPrice),
                address: profile?.reminderAddress,
                localization: localization
            ),
            signature: signature(profile: profile)
        )
    }
}


struct ClientReminderView: View {

    let appointment: Appointment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var currency: CurrencyManager
    @EnvironmentObject var appState: AppState

    @Query private var profiles: [UserProfile]
    @Query(filter: #Predicate<Client> { $0.deletedAt == nil })
    private var clients: [Client]

    @State private var text = ""
    @State private var didLoad = false
    @State private var showShare = false

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    private var profile: UserProfile? {
        profiles.first { $0.authUserID == appState.session.userID }
    }

    private var client: Client? {
        clients.first { $0.id == appointment.clientID }
    }

    private var contact: ClientMessageChannel.Contact {
        ClientMessageChannel.Contact(
            phone: client?.phone,
            telegram: client?.telegram,
            viber: client?.viber,
            whatsapp: client?.whatsapp
        )
    }

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(alignment: .leading, spacing: 16) {

                    FormSectionTitle(
                        text: localization.localizedString(for: "clientMessage.sendVia"),
                        colors: colors
                    )

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                        ForEach(ClientMessageChannel.allCases) { channel in
                            Button {
                                send(via: channel)
                            } label: {
                                VStack(spacing: 6) {
                                    channelIcon(channel)
                                    Text(channel.title)
                                        .font(.caption)
                                        .foregroundColor(colors.textPrimary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(colors.card)
                                .cornerRadius(14)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("clientReminder.\(channel.rawValue)")
                        }
                    }

                    Button {
                        showShare = true
                    } label: {
                        Label(localization.localizedString(for: "clientMessage.other"), systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundColor(colors.accent)
                            .background(colors.card)
                            .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("clientReminder.other")

                    FormSectionTitle(
                        text: localization.localizedString(for: "clientMessage.text"),
                        colors: colors
                    )

                    TextEditor(text: $text)
                        .scrollContentBackground(.hidden)
                        .foregroundColor(colors.textPrimary)
                        .frame(minHeight: 170)
                        .padding(10)
                        .background(colors.card)
                        .cornerRadius(14)
                        .accessibilityIdentifier("clientReminder.text")

                    Text(localization.localizedString(for: "clientMessage.pasteHint"))
                        .font(.footnote)
                        .foregroundColor(colors.textSecondary)
                        .padding(.horizontal, 4)

                    if let sent = appointment.clientReminderSentAt {
                        Label(sentText(sent), systemImage: "checkmark.circle")
                            .font(.footnote)
                            .foregroundColor(colors.success)
                            .padding(.horizontal, 4)
                    }
                }
                .padding()
            }
            .background(colors.background)
            .tint(colors.accent)
            .navigationTitle(appointment.clientName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localization.localizedString(for: "common.cancel")) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                guard !didLoad else { return }
                didLoad = true
                text = ClientReminderText.text(
                    appointment: appointment,
                    profile: profile,
                    localization: localization,
                    currency: currency
                )
            }
            .sheet(isPresented: $showShare) {
                ShareSheet(items: [text]) { completed in
                    if completed {
                        markSent()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func channelIcon(_ channel: ClientMessageChannel) -> some View {
        switch channel {
        case .telegram: ContactNetworkIcon(network: .telegram, size: 22)
        case .viber: ContactNetworkIcon(network: .viber, size: 22)
        case .whatsapp: ContactNetworkIcon(network: .whatsapp, size: 22)
        case .sms:
            Image(systemName: "message.fill")
                .font(.system(size: 18))
                .foregroundColor(colors.accent)
                .frame(width: 22, height: 22)
        }
    }

    private func sentText(_ date: Date) -> String {
        String(
            format: localization.localizedString(for: "clientMessage.sent"),
            AppFormatting.pattern("d MMM, HH:mm", date, locale: localization.locale)
        )
    }

    private func send(via channel: ClientMessageChannel) {

        guard let link = channel.link(text: text, contact: contact) else {
            showShare = true
            return
        }

        if link.needsPaste {
            UIPasteboard.general.string = text
        }

        UIApplication.shared.open(link.url) { opened in
            if opened {
                markSent()
                dismiss()
            } else {
                // Месенджер не встановлено — звичайне меню «Поділитися»
                showShare = true
            }
        }
    }

    private func markSent() {
        appointment.clientReminderSentAt = Date()
        _ = context.saveReportingErrors()
    }
}


// Системне меню «Поділитися» з відповіддю, чи щось надіслано
private struct ShareSheet: UIViewControllerRepresentable {

    let items: [Any]
    let onFinish: (Bool) -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, _ in
            onFinish(completed)
        }
        return controller
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
