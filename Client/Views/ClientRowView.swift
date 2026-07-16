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
        
        HStack {
            
            // initials circle
            Circle()
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(client.name.prefix(1)))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading) {
                Text(client.name)
                    .font(.headline)
                
                if let phone = client.phone {
                    Text(phone)
                        .font(.caption)
                        .foregroundColor(colors.textSecondary)
                }
            }
        }
        .padding(.vertical, 6)
    }
}
