//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 14.05.26.
//
import SwiftUI

struct CalendarMonthGrid: View {

    let selectedDate: Date
    let appointments: [Appointment]
    let dayOffs: [DayOff]

    @Binding var selectedDay: Date
    @Binding var selectedDates: Set<Date>

    let isEditingDayOff: Bool

    private let columns = Array(
        repeating: GridItem(.flexible()),
        count: 7
    )

    var body: some View {

        let days = CalendarMonthBuilder.buildMonth(for: selectedDate)

        LazyVGrid(columns: columns, spacing: 8) {

            ForEach(Array(days.enumerated()), id: \.offset) { _, date in

                if let date {

                    CalendarDayCell(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDay),
                        appointments: appointments,
                        dayOffs: dayOffs,
                        onTap: {
                            handleTap(date)
                        },
                        isEditingDayOff: isEditingDayOff,
                        selectedDates: $selectedDates
                    )

                } else {
                    Color.clear
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                }
            }
        }
    }

    private func handleTap(_ date: Date) {

        let day = Calendar.current.startOfDay(for: date)

        guard isEditingDayOff else {
            selectedDay = date
            return
        }

        if selectedDates.contains(day) {
            selectedDates.remove(day)
        } else {
            selectedDates.insert(day)
        }
    }

    private func toggleDayOff(_ date: Date) {
        if selectedDates.contains(Calendar.current.startOfDay(for: date)) {
            selectedDates.remove(Calendar.current.startOfDay(for: date))
        } else {
            selectedDates.insert(Calendar.current.startOfDay(for: date))
        }
    }
}
