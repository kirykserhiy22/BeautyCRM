//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 03.05.26.
//
import SwiftUI
import SwiftData

struct CreateAppointmentView: View {
    init(initialDate: Date = Date()) {
        _date = State(initialValue: initialDate)
    }
    
    // MARK: - ENV
    
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    // MARK: - DATA
    
    @Query private var clients: [Client]
    @Query private var services: [Service]
    @Query private var appointments: [Appointment]
    
    // MARK: - CLIENT
    
    @State private var selectedClient: Client?
    @State private var clientSearch = ""
    @State private var showClientCreate = false
    @State private var showSuggestions = false
    
    // MARK: - SERVICES
    
    @State private var selectedServiceIDs: Set<UUID> = []
    @State private var customPrices: [UUID: Double] = [:]
    
    @State private var showServicePicker = false
    
    // MARK: - APPOINTMENT
    
    @State private var date: Date
    @State private var duration = 60
    @State private var notes = ""
    
    // MARK: - UI
    
    @State private var errorMessage = ""
    
    // MARK: - BODY
    
    var body: some View {
        
        NavigationStack {
            
            ScrollView {
                
                VStack(spacing: 24) {
                    
                    // CLIENT
                    
                    VStack(alignment: .leading, spacing: 10) {
                        
                        Text("Client")
                            .font(.headline)
                        
                        TextField(
                            "Enter client name",
                            text: $clientSearch
                        )
                        .onChange(of: clientSearch) {
                            showSuggestions = true
                        }
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(14)
                        
                        // SUGGESTIONS
                        
                        if showSuggestions && !clientSearch.isEmpty {
                            
                            VStack(spacing: 6) {
                                
                                ForEach(filteredClients.prefix(5)) { client in
                                    
                                    Button {
                                        selectedClient = client
                                        clientSearch = client.name
                                        showSuggestions = false
                                        
                                    } label: {
                                        
                                        HStack {
                                            
                                            VStack(alignment: .leading) {
                                                
                                                Text(client.name)
                                                    .foregroundColor(.primary)
                                                
                                                if let phone = client.phone {
                                                    Text(phone)
                                                        .font(.caption)
                                                        .foregroundColor(.gray)
                                                }
                                            }
                                            
                                            Spacer()
                                        }
                                        .padding()
                                        .background(Color.gray.opacity(0.05))
                                        .cornerRadius(12)
                                    }
                                }
                                
                                // CREATE NEW CLIENT
                                
                                if filteredClients.isEmpty {
                                    
                                    Button {
                                        showClientCreate = true
                                        
                                    } label: {
                                        
                                        HStack {
                                            
                                            Image(systemName: "plus.circle.fill")
                                            
                                            Text("Create \"\(clientSearch)\"")
                                            
                                            Spacer()
                                        }
                                        .padding()
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
                    }
                    .sheet(isPresented: $showClientCreate) {
                        CreateClientView(prefilledName: clientSearch)
                    }
                    
                    // SERVICES
                    
                    VStack(alignment: .leading, spacing: 12) {
                        
                        Text("Services")
                            .font(.headline)
                        
                        Button {
                            showServicePicker = true
                        } label: {
                            
                            HStack {
                                
                                Image(systemName: "plus")
                                
                                Text("Add services")
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(14)
                        }
                        
                        // SELECTED SERVICES
                        
                        if !selectedServices.isEmpty {
                            
                            VStack(spacing: 10) {
                                
                                ForEach(selectedServices) { service in
                                    
                                    VStack(spacing: 8) {
                                        
                                        HStack {
                                            
                                            Text(service.name)
                                                .font(.subheadline.weight(.medium))
                                            
                                            Spacer()
                                            
                                            if service.pricingType == .fixed {
                                                
                                                Text(
                                                    "\(service.price ?? 0, specifier: "%.0f") €"
                                                )
                                                .foregroundColor(.gray)
                                                
                                            } else {
                                                
                                                TextField(
                                                    "Price",
                                                    value: Binding(
                                                        get: {
                                                            customPrices[service.id] ?? 0
                                                        },
                                                        set: {
                                                            customPrices[service.id] = $0
                                                        }
                                                    ),
                                                    format: .number
                                                )
                                                .keyboardType(.decimalPad)
                                                .frame(width: 90)
                                                .textFieldStyle(.roundedBorder)
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(Color.gray.opacity(0.06))
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                    
                    // TOTAL
                    
                    VStack(spacing: 6) {
                        
                        Text("Total")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text("\(totalPrice, specifier: "%.2f") €")
                            .font(.system(size: 34, weight: .bold))
                    }
                    .padding(.top, 8)
                    
                    // DATE
                    
                    VStack(alignment: .leading, spacing: 12) {
                        
                        Text("Date & Time")
                            .font(.headline)
                        
                        DatePicker(
                            "Start",
                            selection: $date
                        )
                        
                        Stepper(
                            "Duration: \(duration) min",
                            value: $duration,
                            in: 15...240,
                            step: 15
                        )
                    }
                    
                    // NOTES
                    
                    VStack(alignment: .leading, spacing: 8) {
                        
                        Text("Notes")
                            .font(.headline)
                        
                        TextField(
                            "Optional notes...",
                            text: $notes,
                            axis: .vertical
                        )
                        .lineLimit(4)
                        .padding()
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(14)
                    }
                    
                    // ERROR
                    
                    if !errorMessage.isEmpty {
                        
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.subheadline)
                    }
                    
                    // BUTTON
                    
                    Button {
                        createAppointment()
                    } label: {
                        
                        Text("Create Appointment")
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
                .padding()
            }
            .navigationTitle("New Appointment")
            
            
            
            // SERVICE PICKER
            
            .sheet(isPresented: $showServicePicker) {
                
                ServicePickerView(
                    selectedIDs: $selectedServiceIDs,
                    customPrices: $customPrices
                )
            }
        }
    }
}

// MARK: - EXTENSIONS
private extension CreateAppointmentView {
    
    var filteredClients: [Client] {
        
        if clientSearch.isEmpty {
            return []
        }
        
        return clients.filter {
            $0.name
                .lowercased()
                .contains(clientSearch.lowercased())
        }
    }
}
private extension CreateAppointmentView {
    
    var selectedServices: [Service] {
        services.filter {
            selectedServiceIDs.contains($0.id)
        }
    }
    
    var totalPrice: Double {
        
        AppointmentEngine.calculateTotal(
            services: services,
            selectedIDs: selectedServiceIDs,
            customPrices: customPrices
        )
    }
    
    var isValid: Bool {
        
        guard selectedClient != nil else {
            return false
        }
        
        guard !selectedServiceIDs.isEmpty else {
            return false
        }
        
        let endDate = Calendar.current.date(
            byAdding: .minute,
            value: duration,
            to: date
        )!
        
        return !AppointmentEngine.hasConflict(
            newStart: date,
            newEnd: endDate,
            existing: appointments
        )
    }
    
    
    func createAppointment() {
        
        guard let userID = appState.session.userID,
              let client = selectedClient
        else {
            return
        }
        
        let result = AppointmentEngine.createAppointment(
            context: context,
            userID: userID,
            client: client,
            services: services,
            selectedServiceIDs: selectedServiceIDs,
            customPrices: customPrices,
            startDate: date,
            duration: duration,
            notes: notes,
            existingAppointments: appointments
        )
        
        switch result {
            
        case .success:
            dismiss()
            
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
}
