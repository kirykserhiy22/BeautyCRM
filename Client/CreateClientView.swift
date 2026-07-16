//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 30.04.26.
//
import SwiftUI
import SwiftData

struct CreateClientView: View {
    
    @Environment(\.modelContext) private var context
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    var prefilledName: String = ""
    
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var instagram: String = ""
    
    var body: some View {
        
        NavigationStack {
            
            Form {
                
                Section("Client Info") {
                    
                    TextField("Name", text: $name)
                    TextField("Phone", text: $phone)
                    TextField("Instagram", text: $instagram)
                }
                
                Button("Save") {
                    saveClient()
                }
                .disabled(name.isEmpty)
            }
            .navigationTitle("New Client")
            .onAppear {
                if name.isEmpty {
                    name = prefilledName
                }
            }
        }
    }
    
    // MARK: - SAVE
    
    private func saveClient() {
        
        guard let userID = appState.session.userID else { return }
        
        let client = Client(
            userID: userID,
            name: name,
            phone: phone.isEmpty ? nil : phone,
            instagram: instagram.isEmpty ? nil : instagram
        )
        
        context.insert(client)
        
        do {
            try context.save()
            dismiss()
        } catch {
            print("Save error: \(error)")
        }
    }
}
