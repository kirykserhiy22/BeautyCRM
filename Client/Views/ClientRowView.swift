//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 03.05.26.
//

import SwiftUI

struct ClientRowView: View {
    
    let client: Client
    
    @EnvironmentObject var theme: ThemeManager
    
    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }
    
    var body: some View {
        
        HStack(spacing: 14) {
            
            Circle()
                .fill(colors.accent)
                .frame(width: 46, height: 46)
                .overlay(
                    Text(String(client.name.prefix(1)))
                        .font(.headline)
                        .foregroundColor(.white)
                )
            
            VStack(
                alignment: .leading,
                spacing: 5
            ) {
                
                Text(client.name)
                    .font(.headline)
                    .foregroundColor(colors.textPrimary)
                
                if let phone = client.phone {
                    
                    Text(phone)
                        .font(.caption)
                        .foregroundColor(colors.textSecondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundColor(colors.textSecondary)
        }
        .padding()
    }
}
