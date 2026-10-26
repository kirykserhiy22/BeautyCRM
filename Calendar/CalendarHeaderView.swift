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

    // Дотик до назви місяця (напр. розгорнути календар із тижня)
    var onTitleTap: (() -> Void)? = nil
    
    @EnvironmentObject var localization: LocalizationManager
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
            
            if let onTitleTap {
                Button(action: onTitleTap) {
                    HStack(spacing: 6) {
                        Text(monthTitle)
                            .font(.title2.bold())
                        Image(systemName: "chevron.down")
                            .font(.caption.bold())
                    }
                }
            } else {
                Text(monthTitle)
                    .font(.title2.bold())
            }
            
            Spacer()
            
            Button(action: onNext) {
                Image(systemName: "chevron.right")
            }
        }
        .foregroundColor(colors.textPrimary)
    }
    
    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = localization.locale
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "LLLL yyyy"

        return formatter.string(from: selectedDate)
    }
}
