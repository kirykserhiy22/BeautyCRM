//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 03.05.26.
//
import SwiftUI
import SwiftData

struct AppointmentFormView: View {
    @EnvironmentObject var currency: CurrencyManager
    @EnvironmentObject var localization: LocalizationManager
    @FocusState private var isClientFieldFocused: Bool

    let mode: AppointmentFormMode

    init(
        mode: AppointmentFormMode = .create,
        initialDate: Date = Date()
    ) {
        self.mode = mode

        _date = State(initialValue: initialDate)

        _serviceState = State(
            initialValue: AppointmentCreateState(
                client: nil,
                selectedServices: [],
                customPrices: [:],
                startDate: initialDate,
                duration: 60,
                notes: ""
            )
        )
    }

    // MARK: - ENV

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var theme: ThemeManager

    // MARK: - DATA

    @Query(filter: #Predicate<Client> { $0.deletedAt == nil })
    private var clients: [Client]
    @Query(filter: #Predicate<Service> { $0.deletedAt == nil })
    private var services: [Service]
    @Query private var appointments: [Appointment]

    // MARK: - CLIENT

    @State private var selectedClient: Client?
    @State private var clientSearch = ""
    @State private var showClientCreate = false
    @State private var showSuggestions = false

    // MARK: - SERVICES

    @State private var serviceState: AppointmentCreateState
    @State private var showServicePicker = false

    // MARK: - APPOINTMENT

    @State private var date: Date
    @State private var duration = 60
    @State private var notes = ""

    // MARK: - UI

    @State private var errorMessage = ""

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }
    
    
    
    
    private var userClients: [Client] {

        guard let userID = appState.session.userID else {
            print("NO USER")
            return []
        }

        return clients.filter {
            $0.userID == userID
        }
    }


    private var userServices: [Service] {

        guard let userID = appState.session.userID else {
            return []
        }

        return services.filter {
            $0.userID == userID
        }
    }


    private var userAppointments: [Appointment] {

        guard let userID = appState.session.userID else {
            return []
        }

        return appointments.filter {
            $0.userID == userID
        }
    }


    // MARK: - BODY

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(spacing: 24) {

                    clientSection

                    servicesSection

                    totalSection

                    dateTimeSection

                    notesSection

                    if !errorMessage.isEmpty {
                        errorSection
                    }

                    actionButton
                }
                .padding()
            }
            .background(colors.secondaryBackground)
            .navigationTitle(modeTitle)
            .onAppear {
                loadAppointmentIfNeeded()
            }
            .sheet(isPresented: $showServicePicker) {

                ServicePickerView(
                    selectedIDs: Binding(
                        get: {
                            Set(serviceState.selectedServices.map { $0.id })
                        },
                        set: { newIDs in
                            serviceState.selectedServices = userServices.filter {
                                newIDs.contains($0.id)
                            }
                        }
                    ),
                    customPrices: $serviceState.customPrices
                )
                .environmentObject(appState)
                .environmentObject(theme)
            }
        }
    }
}

// MARK: - CLIENT SECTION

private extension AppointmentFormView {

    var clientSection: some View {

        VStack(alignment: .leading, spacing: 10) {

            Text(localization.localizedString(for: "appointment.client"))
                .font(.headline)

            
            TextField(
                localization.localizedString(for: "appointment.clientNamePlaceholder"),
                text: $clientSearch
            )
            .focused($isClientFieldFocused)
            .onChange(of: clientSearch) { oldValue, newValue in

                guard oldValue != newValue else {
                    return
                }

                switch mode {

                case .create:
                    showSuggestions = true

                case .edit(let appointment):

                    if newValue == appointment.clientName {
                        return
                    }

                    showSuggestions = true
                }
            }
            .textFieldStyle(.plain)
            .padding()
            .background(colors.card)
            .cornerRadius(14)


            if showSuggestions && !clientSearch.isEmpty {

                VStack(spacing: 6) {

                    ForEach(
                        Array(filteredClients.prefix(5)),
                        id: \.id
                    ) { client in

                        Button {

                            selectedClient = client
                            clientSearch = client.name

                            showSuggestions = false

                            UIApplication.shared.sendAction(
                                #selector(UIResponder.resignFirstResponder),
                                to: nil,
                                from: nil,
                                for: nil
                            )

                        } label: {

                            HStack {

                                VStack(
                                    alignment: .leading,
                                    spacing: 4
                                ) {

                                    Text(client.name)
                                        .foregroundColor(colors.textPrimary)

                                    if let phone = client.phone {

                                        Text(phone)
                                            .font(.caption)
                                            .foregroundColor(colors.textSecondary)
                                    }
                                }

                                Spacer()
                            }
                            .padding()
                            .background(colors.card)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }

                    if filteredClients.isEmpty {

                        Button {
                            showClientCreate = true
                        } label: {

                            HStack {

                                Image(systemName: "plus.circle.fill")

                                Text(
                                    String(
                                        format: localization.localizedString(for: "appointment.createClient"),
                                        locale: localization.locale,
                                        clientSearch
                                    )
                                )

                                Spacer()
                            }
                            .padding()
                            .background(colors.cardSecondary)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .sheet(isPresented: $showClientCreate) {

            ClientFormView(
                mode: .create,
                prefilledName: clientSearch
            )
        }
    }
}

// MARK: - SERVICES SECTION

private extension AppointmentFormView {

    var servicesSection: some View {

        VStack(alignment: .leading, spacing: 12) {

            Text(localization.localizedString(for: "appointment.services"))
                .font(.headline)

            Button {
                showServicePicker = true
            } label: {

                HStack {
                    Image(systemName: "plus")
                    Text(localization.localizedString(for: "appointment.addServices"))
                    Spacer()
                }
                .padding()
                .background(colors.card)
                .cornerRadius(14)
            }

            if !serviceState.selectedServices.isEmpty || !serviceState.retainedItems.isEmpty {

                VStack(spacing: 10) {

                    // Послуги, видалені з прайсу: лишаються з погодженою ціною,
                    // прибрати можна лише вручну
                    ForEach(serviceState.retainedItems, id: \.id) { item in

                        HStack {

                            Text(item.serviceName)
                                .font(.subheadline.weight(.medium))

                            Spacer()

                            Text(currency.format(item.plannedPrice))
                                .foregroundColor(colors.textSecondary)

                            Button {
                                serviceState.retainedItems.removeAll { $0.id == item.id }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(colors.textSecondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding()
                        .background(colors.card)
                        .cornerRadius(12)
                    }

                    ForEach(serviceState.selectedServices, id: \.id) { service in

                        VStack(spacing: 8) {

                            HStack {

                                Text(service.name)
                                    .font(.subheadline.weight(.medium))

                                Spacer()

                                if service.pricingType == .fixed {

                                    Text(
                                     currency.format(serviceState.price(for: service))
                                    )
                                    .foregroundColor(colors.textSecondary)
                                    

                                } else {

                                    // Порожньо або не сума — ключ зникає, і запис не збережеться
                                    MoneyField(
                                        placeholder: localization.localizedString(for: "appointment.price"),
                                        value: Binding(
                                            get: {
                                                serviceState.customPrices[service.id]
                                            },
                                            set: {
                                                serviceState.customPrices[service.id] = $0
                                            }
                                        )
                                    )
                                    .frame(width: 100)
                                }
                            }
                        }
                        .padding()
                        .background(colors.card)
                        .cornerRadius(12)
                    }
                }

                if hasMissingPrice {
                    Text(localization.localizedString(for: "appointment.error.missingPrice"))
                        .font(.caption)
                        .foregroundColor(colors.danger)
                }
            }
        }
    }
}

// MARK: - TOTAL SECTION

private extension AppointmentFormView {

    var totalSection: some View {

        VStack(spacing: 6) {

            Text(localization.localizedString(for: "appointment.total"))
                .font(.subheadline)
                .foregroundColor(colors.textSecondary)

            Text(
             currency.format(
                serviceState.computedPlannedTotal
             )
            )
            .font(.system(size: 34, weight: .bold))
        }
        .padding(.top, 8)
    }
}

// MARK: - DATE SECTION

private extension AppointmentFormView {

    var dateTimeSection: some View {

        VStack(alignment: .leading, spacing: 12) {

            Text(localization.localizedString(for: "appointment.dateTime"))
                .font(.headline)

            DatePicker(
                localization.localizedString(for: "appointment.start"),
                selection: $date
            )

            Stepper(
                String(
                    format: localization.localizedString(for: "appointment.duration"),
                    locale: localization.locale,
                    duration
                ),
                value: $duration,
                in: 15...600,
                step: 15
            )
            if conflictInfo.hasConflict {

                VStack(alignment: .leading, spacing: 6) {

                    Label(
                        localization.localizedString(for: "appointment.timeOccupied"),
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .foregroundColor(.red)

                    if let start = conflictInfo.suggestedStart,
                       let end = conflictInfo.suggestedEnd {

                        Text(
                            String(
                                format: localization.localizedString(for: "appointment.nearestFreeSlot"),
                                locale: localization.locale,
                                time(start),
                                time(end)
                            )
                        )
                        .font(.caption)
                        .foregroundColor(colors.textSecondary)
                    }
                }
            }
        }
    }
}

// MARK: - NOTES SECTION

private extension AppointmentFormView {

    var notesSection: some View {

        VStack(alignment: .leading, spacing: 8) {

            Text(localization.localizedString(for: "appointment.notes"))
                .font(.headline)

            TextField(
                localization.localizedString(for: "appointment.notesPlaceholder"),
                text: $notes,
                axis: .vertical
            )
            .lineLimit(4)
            .padding()
            .background(colors.card)
            .cornerRadius(14)
        }
    }
}

// MARK: - ERROR SECTION

private extension AppointmentFormView {

    var errorSection: some View {

        Text(errorMessage)
            .foregroundColor(.red)
            .font(.subheadline)
    }
}

// MARK: - ACTION BUTTON

private extension AppointmentFormView {

    var actionButton: some View {

        Button {
            saveAppointment()
        } label: {

            Text(buttonTitle)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    isValid
                    ? Color.blue
                    : Color.gray.opacity(0.3)
                )
                .foregroundColor(.white)
                .cornerRadius(16)
        }
        .disabled(!isValid)
    }

    var buttonTitle: String {

        switch mode {

        case .create:
            return localization.localizedString(for: "appointment.createButton")

        case .edit:
            return localization.localizedString(for: "appointment.saveChanges")
        }
    }
}

// MARK: - HELPERS


private extension AppointmentFormView {

    var filteredClients: [Client] {

        if clientSearch.isEmpty {
            return []
        }

        return userClients.filter {
            $0.name
                .lowercased()
                .contains(clientSearch.lowercased())
        }
    }

    var totalPrice: Decimal {
        serviceState.computedPlannedTotal
    }

    private var conflictInfo: ConflictResult {

        AppointmentEngine.conflictResult(
            newStart: date,
            duration: duration,
            existing: userAppointments,
            ignoring: editingAppointmentID
        )
    }

    private var editingAppointmentID: UUID? {

        switch mode {

        case .create:
            return nil

        case .edit(let appointment):
            return appointment.id
        }
    }

    var isValid: Bool {

        guard selectedClient != nil else {
            return false
        }

        guard !serviceState.selectedServiceIDs.isEmpty else {
            return false
        }

        guard !hasMissingPrice else {
            return false
        }

        return !conflictInfo.hasConflict
    }

    // Є послуга зі змінною ціною без введеної суми
    var hasMissingPrice: Bool {
        AppointmentEngine.hasMissingPrice(
            services: serviceState.selectedServices,
            selectedServiceIDs: serviceState.selectedServiceIDs,
            customPrices: serviceState.customPrices
        )
    }

    func saveAppointment() {

        guard let userID = appState.session.userID,
              let client = selectedClient
        else {
            return
        }

        switch mode {

        case .create:

            let result = AppointmentEngine.createAppointment(
                context: context,
                userID: userID,
                client: client,
                services: userServices,
                selectedServiceIDs: serviceState.selectedServiceIDs,
                customPrices: serviceState.customPrices,
                startDate: date,
                duration: duration,
                notes: notes,
                existingAppointments: userAppointments
            )

            switch result {

            case .success:
                // Зберігаємо одразу, а не «колись автоматично»
                if context.saveReportingErrors() {
                    dismiss()
                }

            case .failure(let error):
                errorMessage = localization.localizedString(for: error.localizationKey)
            }

        case .edit(let appointment):

            let result = AppointmentEngine.updateAppointment(
                appointment: appointment,
                client: client,
                services: userServices,
                selectedServiceIDs: serviceState.selectedServiceIDs,
                customPrices: serviceState.customPrices,
                startDate: date,
                duration: duration,
                notes: notes,
                existingAppointments: userAppointments
            )

            switch result {

            case .success:
                // Зберігаємо одразу, а не «колись автоматично»
                if context.saveReportingErrors() {
                    dismiss()
                }

            case .failure(let error):
                errorMessage = localization.localizedString(for: error.localizationKey)
            }
        }
    }

    var modeTitle: String {
        switch mode {
        case .create:
            return localization.localizedString(for: "appointment.createTitle")

        case .edit:
            return localization.localizedString(for: "appointment.editTitle")
        }
    }

    func loadAppointmentIfNeeded() {

        guard case .edit(let appointment) = mode else {
            return
        }

        clientSearch = appointment.clientName
        showSuggestions = false

        selectedClient = userClients.first {
            $0.id == appointment.clientID
        }

        serviceState.selectedServices = appointment.services.compactMap { item in
            userServices.first { $0.id == item.serviceID }
        }

        // Послуги, яких уже немає в прайсі, не губляться
        serviceState.retainedItems = appointment.services.filter { item in
            !userServices.contains { $0.id == item.serviceID }
        }

        // Погоджені ціни запису — і для фіксованих, і для змінних послуг
        let prices = Dictionary(
            appointment.services.map { ($0.serviceID, $0.plannedPrice) },
            uniquingKeysWith: { first, _ in first }
        )
        serviceState.agreedPrices = prices
        serviceState.customPrices = prices

        date = appointment.startDate
        duration = appointment.duration
        notes = appointment.notes ?? ""
    }

    func time(_ date: Date) -> String {

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        return formatter.string(from: date)
    }
}
