//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 03.05.26.
//
import SwiftUI
import SwiftData

struct AppointmentRow: View {
    @EnvironmentObject var currencyManager: CurrencyManager
    @EnvironmentObject var localization: LocalizationManager
    @Environment(\.modelContext) private var context
    
    let appt: Appointment
    let expandedAppointmentID: Binding<UUID?>
    // MARK: - UI
    
    var isExpanded: Bool {
        expandedAppointmentID.wrappedValue == appt.id
    }
    
    @State private var showEdit = false
    @State private var showComplete = false
    @State private var showNotes = false
    @State private var showCancelConfirm = false
    @State private var showRestoreConflict = false
    @State private var finalServicePrices: [UUID: String] = [:]
    @State private var completionItems: [CompletionServiceItem] = []
    
    @EnvironmentObject var theme: ThemeManager
    
    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }
    func loadServices() {

        let services = Array(appt.services)

        completionItems = services.map {
            CompletionServiceItem(
                serviceID: $0.serviceID,
                serviceName: $0.serviceName,
                plannedPrice: $0.finalPrice ?? $0.plannedPrice
            )
        }

        finalServicePrices = Dictionary(
            uniqueKeysWithValues:
                completionItems.map {
                    (
                        $0.serviceID,
                        AppFormatting.moneyInput($0.plannedPrice)
                    )
                }
        )
    }
    
    // MARK: - BODY
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 14) {
            
            // HEADER
            
            Button {

                withAnimation(
                    .spring(
                        response: 0.28,
                        dampingFraction: 0.82
                    )
                ) {

                    if !isExpanded {
                        loadServices()
                    }

                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {

                        if expandedAppointmentID.wrappedValue == appt.id {
                            expandedAppointmentID.wrappedValue = nil
                        } else {
                            expandedAppointmentID.wrappedValue = appt.id
                        }
                    }
                }

            } label: {
                
                HStack(alignment: .top) {
                    
                    VStack(
                        alignment: .leading,
                        spacing: 6
                    ) {
                        
                        Text(appt.clientName)
                            .font(.headline)
                            .foregroundColor(colors.textSecondary)
                        
                        Text(
                            appt.services
                                .map { $0.serviceName }
                                .joined(separator: " + ")
                        )
                        .font(.subheadline)
                        .foregroundColor(colors.textSecondary)
                        
                        HStack(spacing: 6) {
                            
                            Image(systemName: "clock")
                                .foregroundColor(colors.textSecondary)
                            
                            Text(
                                "\(time(appt.startDate)) - \(time(appt.endDate))"
                            )
                            .font(.caption)
                            .foregroundColor(colors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(
                        alignment: .trailing,
                        spacing: 10
                    ) {
                        
                        Text(statusText)
                            .font(.caption.bold())
                            .foregroundColor(statusColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(colors.card)
                            .cornerRadius(10)
                        
                        Image(
                            systemName: isExpanded
                            ? "chevron.up"
                            : "chevron.down"
                        )
                        .font(.caption.bold())
                        .foregroundColor(colors.textSecondary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .animation(
                .spring(
                    response: 0.35,
                    dampingFraction: 0.85
                ),
                value: isExpanded
            )
            
            // EXPANDED
            
            if isExpanded {
                
                VStack(spacing: 16) {
                    
                    Divider()
                    
                    VStack(
                        alignment: .leading,
                        spacing: 10
                    ) {
                        
                        HStack(spacing: 8) {
                            
                            Image(systemName: "eurosign.circle")
                                .foregroundColor(colors.textSecondary)
                            
                            Text(
                                currencyManager.format(displayPrice(appt))
                            )
                            .font(.subheadline)
                            .foregroundColor(colors.textPrimary)
                            Spacer()
                            
                            if hasNotes {
                                
                                Image(systemName: "info.circle")
                                    .foregroundColor(colors.textSecondary)
                            }
                        }
                        
                        if let notes = appt.notes,
                           !notes.trimmingCharacters(
                                in: .whitespacesAndNewlines
                           ).isEmpty {
                            
                            Text(notes)
                                .font(.caption)
                                .foregroundColor(colors.textSecondary)
                                .frame(
                                    maxWidth: .infinity,
                                    alignment: .leading
                                )
                        }
                    }
                    
                    
                    // ACTIONS

                    VStack(spacing: 10) {

                        // Перший ряд кнопок

                        HStack(spacing: 10) {

                            if appt.status == .active {

                                Button {
                                    showComplete = true
                                } label: {
                                    Label(
                                        localization.localizedString(for: "appointment.complete"),
                                        systemImage: "checkmark.circle.fill"
                                    )
                                    .frame(maxWidth: .infinity)
                                    .multilineTextAlignment(.center)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                                .frame(maxWidth: .infinity)

                                Button {
                                    showEdit = true
                                } label: {
                                    Label(
                                        localization.localizedString(for: "appointment.edit"),
                                        systemImage: "pencil"
                                    )
                                    .frame(maxWidth: .infinity)
                                    .multilineTextAlignment(.center)
                                }
                                .buttonStyle(.bordered)
                                .frame(maxWidth: .infinity)
                            }
                        }

                        // Другий ряд — скасування або архівування

                        if appt.status == .active {

                            // Скасування — лише після підтвердження
                            Button {
                                showCancelConfirm = true
                            } label: {
                                Label(
                                    localization.localizedString(for: "appointment.cancel"),
                                    systemImage: "xmark.circle"
                                )
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                            .frame(maxWidth: .infinity)

                        } else if appt.status == .cancelled {

                            HStack(spacing: 10) {

                                // Повернути випадково скасований запис
                                Button {
                                    restore()
                                } label: {
                                    Label(
                                        localization.localizedString(for: "appointment.restore"),
                                        systemImage: "arrow.uturn.backward.circle"
                                    )
                                    .frame(maxWidth: .infinity)
                                    .multilineTextAlignment(.center)
                                }
                                .buttonStyle(.bordered)
                                .tint(colors.accent)
                                .frame(maxWidth: .infinity)

                                Button {
                                    AppointmentEngine.archive(appointment: appt)
                                    context.saveReportingErrors()
                                } label: {
                                    Label(
                                        localization.localizedString(for: "appointment.hide"),
                                        systemImage: "archivebox"
                                    )
                                    .frame(maxWidth: .infinity)
                                    .multilineTextAlignment(.center)
                                }
                                .buttonStyle(.bordered)
                                .tint(.gray)
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 2)

                    }
                
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(
                            with: .move(edge: .top)
                        ),
                        removal: .opacity
                    )
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(colors.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(colors.border, lineWidth: 1)
        )
        .shadow(color: colors.shadow, radius: 6, y: 2)

        // CANCEL CONFIRMATION

        .confirmationDialog(
            localization.localizedString(for: "appointment.cancelConfirm.title"),
            isPresented: $showCancelConfirm,
            titleVisibility: .visible
        ) {
            Button(
                localization.localizedString(for: "appointment.cancelConfirm.confirm"),
                role: .destructive
            ) {
                AppointmentEngine.cancel(appointment: appt)
                context.saveReportingErrors()
            }

            Button(
                localization.localizedString(for: "appointment.cancelConfirm.keep"),
                role: .cancel
            ) { }
        } message: {
            Text(localization.localizedString(for: "appointment.cancelConfirm.message"))
        }

        // RESTORE CONFLICT

        .alert(
            localization.localizedString(for: "appointment.restoreConflict.title"),
            isPresented: $showRestoreConflict
        ) {
            Button(localization.localizedString(for: "common.ok"), role: .cancel) { }
        } message: {
            Text(localization.localizedString(for: "appointment.restoreConflict.message"))
        }

        // NOTES
        
        .alert(
            localization.localizedString(for: "appointment.notesTitle"),
            isPresented: $showNotes
        ) {
            
            Button(
                "OK",
                role: .cancel
            ) { }
            
        } message: {
            
            Text(appt.notes ?? "")
        }
        
        // COMPLETE SHEET
        
        .sheet(
            isPresented: $showComplete,
            onDismiss: {
                completionItems = []
                finalServicePrices = [:]
            }
        ) {
            
            NavigationStack {
                
                ScrollView {
                    
                    VStack(
                        alignment: .leading,
                        spacing: 20
                    ) {
                        
                        Text(
                            localization.localizedString(for: "appointment.finalizeServices")
                        )
                        .font(.title2.bold())
                        
                        LazyVStack(spacing: 16) {
                            
                            ForEach(
                                completionItems,
                                id: \.serviceID
                            ) { item in
                                
                                VStack(
                                    alignment: .leading,
                                    spacing: 8
                                ) {
                                    
                                    Text(item.serviceName)
                                        .font(.headline)
                                    
                                    TextField(
                                        localization.localizedString(for: "appointment.price"),
                                        text: Binding(
                                            get: {
                                                finalServicePrices[
                                                    item.serviceID
                                                ] ?? ""
                                            },
                                            set: {
                                                finalServicePrices[
                                                    item.serviceID
                                                ] = $0
                                            }
                                        )
                                    )
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(
                                                isPriceInvalid(item.serviceID) ? colors.danger : .clear,
                                                lineWidth: 1.5
                                            )
                                    )

                                    if isPriceInvalid(item.serviceID) {
                                        Text(localization.localizedString(for: "money.invalid"))
                                            .font(.caption)
                                            .foregroundColor(colors.danger)
                                    }
                                }
                                .padding()
                                .background(colors.card)
                                .cornerRadius(16)
                            }
                        }
                        
                        
                        Divider()
                        
                        HStack {
                            
                            Text(localization.localizedString(for: "appointment.total"))
                                .font(.headline)
                            
                            Spacer()
                            
                            Text(
                                currencyManager.format(finalTotal)
                            )
                            .font(.title3.bold())
                        }
                        
                        Button {
                            
                            // Сюди доходимо лише з правильними сумами (кнопка інакше неактивна)
                            let mapped = finalServicePrices.compactMapValues {
                                AppFormatting.parseMoney($0)
                            }
                            
                            AppointmentEngine.complete(
                                appointment: appt,
                                finalServicePrices: mapped
                            )
                            
                            context.saveReportingErrors()
                            
                            showComplete = false
                            
                        } label: {
                            
                            Text(localization.localizedString(for: "appointment.confirm"))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(canConfirmCompletion ? Color.green : Color.gray.opacity(0.4))
                                .foregroundColor(.white)
                                .cornerRadius(14)
                        }
                        .disabled(!canConfirmCompletion)
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        
        // EDIT
        
        .sheet(isPresented: $showEdit) {
            
            AppointmentFormView(
                mode: .edit(appt)
            )
        }
    }
}

// MARK: - HELPERS


private extension AppointmentRow {

    // Відновлення скасованого запису: якщо його час уже зайняли — пояснюємо чому ні
    func restore() {

        let userID = appt.userID
        let descriptor = FetchDescriptor<Appointment>(
            predicate: #Predicate { $0.userID == userID }
        )
        let existing = (try? context.fetch(descriptor)) ?? []

        switch AppointmentEngine.restore(appointment: appt, existingAppointments: existing) {

        case .success:
            context.saveReportingErrors()

        case .failure(.timeConflict):
            showRestoreConflict = true

        case .failure:
            break
        }
    }

    var statusText: String {

        switch appt.status {

        case .active:
            return localization.localizedString(for: "appointment.status.active")

        case .completed:
            return localization.localizedString(for: "appointment.status.completed")

        case .cancelled:
            return localization.localizedString(for: "appointment.status.cancelled")

        case .archived:
            return localization.localizedString(for: "appointment.status.archived")
        }
    }
    
    var statusColor: Color {
        
        switch appt.status {
            
        case .active:
            return .blue
            
        case .completed:
            return .green
            
        case .cancelled:
            return .red
            
        case .archived:
            return .gray
        }
    }
    
    private func displayPrice(_ appt: Appointment) -> Decimal {
        
        if appt.status == .completed {
            
            return appt.finalPrice
            ?? appt.services.reduce(0) {
                $0 + ($1.finalPrice ?? $1.plannedPrice)
            }
        }
        
        return appt.services.reduce(0) {
            $0 + $1.plannedPrice
        }
    }
    
    var hasNotes: Bool {
        
        guard let notes = appt.notes else {
            return false
        }
        
        return !notes
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty
    }
    
    func time(_ date: Date) -> String {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        return formatter.string(from: date)
    }
    
    // Порожньо або не сума — не можна завершити (раніше ставало 0 €)
    func isPriceInvalid(_ serviceID: UUID) -> Bool {
        AppFormatting.parseMoney(finalServicePrices[serviceID] ?? "") == nil
    }

    var canConfirmCompletion: Bool {
        completionItems.allSatisfy { !isPriceInvalid($0.serviceID) }
    }

    var finalTotal: Decimal {
        
        finalServicePrices.values.reduce(Decimal(0)) {
            $0 + (AppFormatting.parseMoney($1) ?? 0)
        }
    }
}
