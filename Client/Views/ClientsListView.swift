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
    @State private var clientToOpen: Client?
    // Клієнт, якого майстер свайпом хоче видалити, — чекає підтвердження
    @State private var clientToDelete: Client?
    // Скільки в нього майбутніх записів — вони скасуються разом із клієнтом
    @State private var upcomingToCancel = 0

    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<Client> { $0.deletedAt == nil },
        sort: \Client.createdAt,
        order: .reverse
    )
    private var clients: [Client]

    @Query private var appointments: [Appointment]

    // Скільки завершених візитів у кожного клієнта — один прохід по записах
    private var visitCounts: [UUID: Int] {
        appointments
            .filter { $0.status == .completed }
            .reduce(into: [:]) { $0[$1.clientID, default: 0] += 1 }
    }

    @State private var searchText = ""
    @State private var showAddClient = false
    // «+» — ввести вручну чи вибрати з контактів
    @State private var showAddChoice = false
    @State private var importedCount: Int?

    // Сортування (запам'ятовується) і екран вибору
    @AppStorage("clients.sort") private var sortRaw = ClientSort.nameAscending.rawValue
    @State private var showSort = false

    private var sort: ClientSort {
        ClientSort(rawValue: sortRaw) ?? .nameAscending
    }

    // «Найближчі» — у кого запис протягом тижня (лише без пошуку)
    private var upcoming: [(client: Client, start: Date)] {
        guard searchText.isEmpty else { return [] }
        return ClientSorting.upcoming(userClients, appointments: appointments)
    }

    private var userClients: [Client] {

        guard let userID = appState.session.userID else {
            return []
        }

        return clients.filter {
            $0.userID == userID
        }
    }

    private var filteredClients: [Client] {

        let found = searchText.isEmpty
            ? userClients
            : userClients.filter { $0.name.localizedCaseInsensitiveContains(searchText) }

        return ClientSorting.sorted(
            found,
            by: sort,
            lastVisits: ClientSorting.lastVisits(appointments),
            locale: localization.locale
        )
    }

    var body: some View {

        NavigationStack {

            ZStack(alignment: .bottomTrailing) {

                colors.background
                    .ignoresSafeArea()

                VStack(spacing: 14) {

                    header

                    searchBar

                    // List — щоб працював системний свайп «Видалити»
                    List {

                        let visitCounts = visitCounts
                        let upcoming = upcoming

                        if !upcoming.isEmpty {
                            sectionTitle("clients.section.upcoming")
                            ForEach(upcoming, id: \.client.id) { item in
                                Button {
                                    clientToOpen = item.client
                                } label: {
                                    upcomingRow(item.client, start: item.start)
                                }
                                .buttonStyle(.plain)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                            sectionTitle("clients.section.all")
                        }

                        ForEach(filteredClients) { client in
                            Button {
                                clientToOpen = client
                            } label: {
                                ClientRowView(client: client, visits: visitCounts[client.id] ?? 0)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(colors.card)
                                    .cornerRadius(18)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(EdgeInsets(top: 7, leading: 16, bottom: 7, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                // Без role: .destructive — рядок не зникає, поки майстер не підтвердить
                                Button {
                                    askDelete(client)
                                } label: {
                                    Label(
                                        localization.localizedString(for: "common.delete"),
                                        systemImage: "trash"
                                    )
                                }
                                .tint(colors.buttonDestructive)
                                .accessibilityIdentifier("clients.swipeDelete")
                            }
                        }

                        if filteredClients.isEmpty {
                            Group {
                                if userClients.isEmpty {
                                    EmptyStateView(
                                        systemImage: "person.2",
                                        titleKey: "empty.clients.title",
                                        messageKey: "empty.clients.message"
                                    )
                                } else {
                                    EmptyStateView(
                                        systemImage: "magnifyingglass",
                                        titleKey: "empty.search.title",
                                        messageKey: "empty.search.message"
                                    )
                                }
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }

                        // Місце під плаваючою кнопкою
                        Color.clear
                            .frame(height: 64)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .scrollDismissesKeyboard(.interactively)
                }


                Button {
                        showAddChoice = true
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
                    .accessibilityIdentifier("floating.add")
                    .padding()
            }
            .keyboardDoneButton()
            .navigationTitle(localization.localizedString(for: "clients.title"))
            // Заголовок із кількістю клієнтів малює header
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showAddClient) {
                ClientFormView(mode: .create)
            }
            .confirmationDialog(
                localization.localizedString(for: "clients.add.title"),
                isPresented: $showAddChoice,
                titleVisibility: .visible
            ) {
                Button(localization.localizedString(for: "clients.add.manual")) {
                    showAddClient = true
                }
                Button(localization.localizedString(for: "clients.add.contacts")) {
                    ContactPickerPresenter.shared.present { picked in
                        guard let userID = appState.session.userID else { return }
                        importedCount = ContactImport.create(picked, userID: userID, context: modelContext)
                    }
                }
                Button(localization.localizedString(for: "common.cancel"), role: .cancel) { }
            }
            .alert(
                String(format: localization.localizedString(for: "clients.add.imported"), importedCount ?? 0),
                isPresented: Binding(get: { importedCount != nil }, set: { if !$0 { importedCount = nil } })
            ) {
                Button(localization.localizedString(for: "common.ok"), role: .cancel) { }
            }
            .navigationDestination(item: $clientToOpen) { client in
                ClientProfileView(client: client)
            }
            .confirmationDialog(
                String(
                    format: localization.localizedString(for: "clients.deleteOne.title"),
                    clientToDelete?.name ?? ""
                ),
                isPresented: Binding(
                    get: { clientToDelete != nil },
                    set: { if !$0 { clientToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                // Є майбутні записи — кнопки кажуть прямо, що вони скасуються
                Button(
                    localization.localizedString(
                        for: upcomingToCancel > 0 ? "clients.delete.cancelAndDelete" : "common.delete"
                    ),
                    role: .destructive
                ) {
                    deleteConfirmed()
                }
                .accessibilityIdentifier("clients.delete.confirm")

                Button(
                    localization.localizedString(
                        for: upcomingToCancel > 0 ? "clients.delete.keep" : "common.cancel"
                    ),
                    role: .cancel
                ) {
                    clientToDelete = nil
                }
            } message: {
                if upcomingToCancel > 0 {
                    Text(
                        String(
                            format: localization.localizedString(for: "clients.delete.upcomingMessage"),
                            upcomingToCancel
                        )
                    )
                } else {
                    Text(localization.localizedString(for: "clients.deleteOne.message"))
                }
            }
        }
    }
}

private extension ClientsListView {

    var header: some View {

        HStack(alignment: .firstTextBaseline, spacing: 10) {

            Text(localization.localizedString(for: "clients.title"))
                .font(.largeTitle.bold())
                .foregroundColor(colors.textPrimary)

            if !userClients.isEmpty {
                Text("\(userClients.count)")
                    .font(.title2)
                    .foregroundColor(colors.textSecondary)
            }

            Spacer()

            if userClients.count > 1 {
                Button {
                    showSort = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(colors.accent)
                        .frame(width: 40, height: 40)
                }
                .accessibilityLabel(localization.localizedString(for: "clients.sort.title"))
                .accessibilityIdentifier("clients.sort")
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .sheet(isPresented: $showSort) {
            ClientSortSheet(selection: $sortRaw)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private func sectionTitle(_ key: String) -> some View {
        Text(localization.localizedString(for: key))
            .font(.footnote.weight(.semibold))
            .textCase(.uppercase)
            .foregroundColor(colors.textSecondary)
            .padding(.top, 6)
            .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 0, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }

    // «Найближчі»: ім'я й коли запис («Завтра, 10:00»)
    private func upcomingRow(_ client: Client, start: Date) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(colors.accent.opacity(0.18))
                .frame(width: 38, height: 38)
                .overlay(
                    Text(String(client.name.prefix(1)))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(colors.accent)
                )
            Text(client.name)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(colors.textPrimary)
                .lineLimit(1)
            Spacer()
            Text(whenText(start))
                .font(.subheadline)
                .foregroundColor(colors.accent)
                .monospacedDigit()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 14).fill(colors.cardSecondary))
        .contentShape(Rectangle())
        .accessibilityIdentifier("clients.upcoming")
    }

    private func whenText(_ date: Date) -> String {
        let calendar = Calendar.current
        let time = AppFormatting.clock(date)
        if calendar.isDateInToday(date) {
            return localization.localizedString(for: "clients.when.today") + ", " + time
        }
        if calendar.isDateInTomorrow(date) {
            return localization.localizedString(for: "clients.when.tomorrow") + ", " + time
        }
        return AppFormatting.template("EEEdMMM", date, locale: localization.locale) + ", " + time
    }

    var searchBar: some View {

        HStack {

            Image(systemName: "magnifyingglass")
                .foregroundColor(colors.textSecondary)

            TextField(
                localization.localizedString(for: "clients.search"),
                text: $searchText
            )
            .foregroundColor(colors.textPrimary)
            // «Пошук» на клавіатурі ховає її — результати вже на екрані
            .submitLabel(.search)
            .autocorrectionDisabled()
            .accessibilityIdentifier("clients.search")
        }
        .padding()
        .background(colors.inputBackground)
        .cornerRadius(18)
        .padding(.horizontal)
    }
   

    // Свайп → питання. Майбутні записи рахуємо заздалегідь, щоб сказати про них прямо
    func askDelete(_ client: Client) {
        upcomingToCancel = (try? ClientManager.upcomingAppointments(
            clientIDs: [client.id],
            context: modelContext
        ).count) ?? 0
        clientToDelete = client
    }

    func deleteConfirmed() {
        guard let client = clientToDelete else {
            return
        }
        ClientManager.delete(client: client, context: modelContext)
        modelContext.saveReportingErrors()
        clientToDelete = nil
    }
}
