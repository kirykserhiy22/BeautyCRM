//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 03.05.26.
//

import SwiftUI

struct ClientRowView: View {
    
    let client: Client
    
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
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 6)
    }
}
