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
                        String(format: "%.0f", $0.plannedPrice)
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
                                "\(displayPrice(appt), specifier: "%.0f") \(currencyManager.symbol)"
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
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        
                        HStack(spacing: 12) {
                            
                            // COMPLETE
                            
                            if appt.status == .active {
                                
                                Button {
                                    showComplete = true
                                } label: {
                                    Label("Complete", systemImage: "checkmark.circle.fill")
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                            }
                            
                            // EDIT
                            
                            if appt.status == .active {
                                
                                Button {
                                    showEdit = true
                                    
                                } label: {
                                    
                                    Label(
                                        "Edit",
                                        systemImage: "pencil"
                                    )
                                }
                                .buttonStyle(.bordered)
                            }
                            
                            // CANCEL
                            
                            if appt.status == .active {
                                
                                Button {
                                    
                                    AppointmentEngine.cancel(
                                        appointment: appt
                                    )
                                    
                                    try? context.save()
                                    
                                } label: {
                                    
                                    Label(
                                        "Cancel",
                                        systemImage: "xmark.circle"
                                    )
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                            }
                            
                            // ARCHIVE
                            
                            if appt.status == .cancelled {
                                
                                Button {
                                    
                                    appt.status = .archived
                                    
                                    try? context.save()
                                    
                                } label: {
                                    
                                    Label(
                                        "Hide",
                                        systemImage: "archivebox"
                                    )
                                }
                                .buttonStyle(.bordered)
                                .tint(.gray)
                            }
                        }
                        .padding(.vertical, 2)
                    }
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
        
        // NOTES
        
        .alert(
            "Notes",
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
                        
                        Text("Finalize Services")
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
                                        "Price",
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
                                }
                                .padding()
                                .background(colors.card)
                                .cornerRadius(16)
                            }
                        }
                        
                        
                        Divider()
                        
                        HStack {
                            
                            Text("Total")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text(
                                "\(finalTotal, specifier: "%.0f") \(currencyManager.symbol)"
                            )
                            .font(.title3.bold())
                        }
                        
                        Button {
                            
                            let mapped =
                            Dictionary(
                                uniqueKeysWithValues:
                                    finalServicePrices.map {
                                        (
                                            $0.key,
                                            Double($0.value) ?? 0
                                        )
                                    }
                            )
                            
                            AppointmentEngine.complete(
                                appointment: appt,
                                finalServicePrices: mapped
                            )
                            
                            try? context.save()
                            
                            showComplete = false
                            
                        } label: {
                            
                            Text("Confirm")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                        }
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
    
    var statusText: String {
        
        switch appt.status {
            
        case .active:
            return "ACTIVE"
            
        case .completed:
            return "DONE"
            
        case .cancelled:
            return "CANCELLED"
            
        case .archived:
            return "ARCHIVED"
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
    
    private func displayPrice(_ appt: Appointment) -> Double {
        
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
    
    var finalTotal: Double {
        
        finalServicePrices.values.reduce(0) {
            $0 + (Double($1) ?? 0)
        }
    }
}
