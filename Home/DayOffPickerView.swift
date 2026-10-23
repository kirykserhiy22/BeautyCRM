//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 17.05.26.
//

import SwiftUI
import SwiftData

struct DayOffPickerView: View {

    // MARK: - ENV

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var theme: ThemeManager
    

    // MARK: - DATA

    @Query(filter: #Predicate<DayOff> { $0.deletedAt == nil })
    private var dayOffs: [DayOff]

    // MARK: - UI

    @State private var selectedDates: Set<Date> = []
    // MARK: - THEME

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    // MARK: - BODY

    var body: some View {

        NavigationStack {

            VStack(spacing: 20) {

                CalendarPagerView(
                    appointments: [],
                    dayOffs: [],
                    selectedDay: .constant(Date()),
                    selectedDates: $selectedDates,
                    isEditingDayOff: true
                )

                Button {

                    save()

                } label: {

                    Text("common.save")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(colors.buttonPrimary)
                        .cornerRadius(16)
                }
                .padding(.horizontal)
            }
            .padding(.top)
            .navigationTitle("dayOff.title")
            .onAppear {
                loadExisting()
            }
        }
    }

    // MARK: - SAVE
    private func loadExisting() {

        guard let userID = appState.session.userID else { return }

        let calendar = Calendar.current

        let existing = dayOffs.filter { $0.userID == userID }

        selectedDates = Set(
            existing.map {
                calendar.startOfDay(for: $0.date)
            }
        )
    }

    private func save() {

        guard let userID = appState.session.userID else { return }

        let calendar = Calendar.current

        let existing = dayOffs.filter { $0.userID == userID }

        let existingDates = Set(existing.map {
            calendar.startOfDay(for: $0.date)
        })

        let newDates = Set(selectedDates.map {
            calendar.startOfDay(for: $0)
        })

        // 1. DELETE only removed
        for item in existing {
            let day = calendar.startOfDay(for: item.date)
            if !newDates.contains(day) {
                item.markDeleted()
            }
        }

        // 2. ADD only new
        for date in newDates {
            if !existingDates.contains(date) {
                context.insert(
                    DayOff(userID: userID, date: date)
                )
            }
        }

        try? context.save()
        dismiss()
    }
}
