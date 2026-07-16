//
//  Untitled 3.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 14.05.26.
//

import SwiftUI

struct CalendarDayCell: View {
    
    let date: Date
    
    let isSelected: Bool
    
    let appointments: [Appointment]
    
    let onTap: () -> Void
    
    @EnvironmentObject var theme: ThemeManager
    
    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }
    
    var body: some View {
        
        Button {
            onTap()
            
        } label: {
            
            VStack(spacing: 6) {
                
                Text(dayNumber)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(
                        isSelected
                        ? .white
                        : colors.textPrimary
                    )
                
                DayOccupancyBar(
                    segments: segments,
                    hasEarly: hasEarly,
                    hasLate: hasLate
                )
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                isSelected
                ? colors.accent
                : colors.card
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
