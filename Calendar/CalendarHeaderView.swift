//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 14.05.26.
//

import SwiftUI

struct CalendarHeaderView: View {
    
    let selectedDate: Date
    let onPrev: () -> Void
    let onNext: () -> Void
    
    @EnvironmentObject var theme: ThemeManager
    
    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }
    
    var body: some View {
        HStack {
            
            Button(action: onPrev) {
                Image(systemName: "chevron.left")
            }
            
            Spacer()
            
            Text(monthTitle)
                .font(.title2.bold())
            
            Spacer()
            
            Button(action: onNext) {
                Image(systemName: "chevron.right")
            }
        }
        .foregroundColor(colors.textPrimary)
    }
    
    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }
}
