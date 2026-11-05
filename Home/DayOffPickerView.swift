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

        let existing = dayOffs.filter { $0.userID == userID }

        selectedDates = Set(
            existing.compactMap {
                DayOff.date(fromKey: $0.dayKey)
            }
        )
    }

    private func save() {

        guard let userID = appState.session.userID else { return }

        let existing = dayOffs.filter { $0.userID == userID }

        let existingKeys = Set(existing.map(\.dayKey))

        let newKeys = Dictionary(
            selectedDates.map { (DayOff.key(for: $0), $0) },
            uniquingKeysWith: { first, _ in first }
        )

        // 1. DELETE only removed
        for item in existing where newKeys[item.dayKey] == nil {
            item.markDeleted()
        }

        // 2. ADD only new
        for (key, date) in newKeys where !existingKeys.contains(key) {
            context.insert(
                DayOff(userID: userID, date: date)
            )
        }

        if context.saveReportingErrors() {
            dismiss()
        }
    }
}
