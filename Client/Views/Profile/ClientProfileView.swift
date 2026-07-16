//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 03.05.26.
//

import SwiftUI

struct ClientProfileView: View {
    
    @EnvironmentObject var theme: ThemeManager
    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }
    let client: Client
    
    var body: some View {
        
        ScrollView {
            
            VStack(spacing: 20) {
                
                // 🔵 HEADER
                VStack {
                    Circle()
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text(String(client.name.prefix(1)))
                                .font(.title)
                                .foregroundColor(.white)
                        )
                    
                    Text(client.name)
                        .font(.title2)
                        .bold()
                }
                
                // 📞 CONTACT
                VStack(alignment: .leading, spacing: 8) {
                    
                    if let phone = client.phone {
                        Text("📞 \(phone)")
                    }
                    
                    if let instagram = client.instagram {
                        Text("📸 \(instagram)")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                
                // 📊 ANALYTICS (placeholder)
                VStack {
                    Text("Analytics")
                        .font(.headline)
                    
                    HStack {
                        VStack {
                            Text("0")
                            Text("Visits")
                        }
                        
                        VStack {
                            Text("0")
                            Text("Completed")
                        }
                        
                        VStack {
                            Text("0")
                            Text("Revenue")
                        }
                    }
                }
                .padding()
                .background(colors.card)
                .cornerRadius(12)
                
                // 🖼 PHOTO GRID (placeholder)
                VStack(alignment: .leading) {
                    Text("Photos")
                        .font(.headline)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ]) {
                        
                        ForEach(0..<3, id: \.self) { _ in
                            Rectangle()
                                .frame(height: 100)
                                .cornerRadius(10)
                        }
                        
                        Button {
                            // add photo later
                        } label: {
                            Rectangle()
                                .frame(height: 100)
                                .overlay(
                                    Image(systemName: "plus")
                                )
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Client Profile")
        
    }
}
