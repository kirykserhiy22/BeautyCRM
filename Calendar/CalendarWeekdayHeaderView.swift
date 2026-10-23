//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 05.07.26.
//


import SwiftUI

struct CalendarWeekdayHeaderView: View {

    @EnvironmentObject var localization: LocalizationManager

    private let columns = Array(
        repeating: GridItem(.flexible()),
        count: 7
    )

    private var weekdays: [String] {
        AppFormatting.weekdayNames(
            locale: localization.locale
        )
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}
