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

        switch localization.languageCode {

        case "uk":
            formatter.locale = Locale(identifier: "uk_UA")

        case "de":
            formatter.locale = Locale(identifier: "de_DE")

        case "pl":
            formatter.locale = Locale(identifier: "pl_PL")

        case "cs":
            formatter.locale = Locale(identifier: "cs_CZ")

        default:
            formatter.locale = Locale(identifier: "en_US")
        }


        formatter.dateFormat = "LLLL yyyy"

        return formatter.string(
            from: selectedDate
        )
    }
}
