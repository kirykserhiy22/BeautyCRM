//
//  Untitled 3.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 14.05.26.
//
import SwiftUI
import SwiftData

struct CalendarDayCell: View {

    @Environment(\.modelContext) private var context
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var theme: ThemeManager

    let date: Date
    let isSelected: Bool
    let appointments: [Appointment]
    let dayOffs: [DayOff]

    let onTap: () -> Void
    let isEditingDayOff: Bool

    @Binding var selectedDates: Set<Date>

    private let calendar = Calendar.current

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    // MARK: - STATE

    private var isPersistedDayOff: Bool {
        dayOffs.contains {
            calendar.isDate($0.date, inSameDayAs: date)
        }
    }

    

    // MARK: - BODY

    var body: some View {

        Button(action: onTap) {

            VStack(spacing: 6) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(colors.textPrimary)

                DayOccupancyBar(
                    appointments: appointments,
                    day: date
                )
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
        }
        .buttonStyle(.plain)
        .background(background)
        .overlay(selectionRing)
        .highPriorityGesture(
            LongPressGesture(minimumDuration: 0.6)
                .onEnded { _ in
                    if !isEditingDayOff {
                        toggleDayOff()
                    }
                }
        )
    }

    // MARK: - LONG PRESS (DAY OFF TOGGLE)

   

    private func toggleDayOff() {

        let day = calendar.startOfDay(for: date)

        guard let userID = appState.session.userID else { return }

        if let existing = dayOffs.first(where: {
            $0.userID == userID &&
            calendar.isDate($0.date, inSameDayAs: day)
        }) {
            existing.markDeleted()
        } else {
            context.insert(DayOff(userID: userID, date: day))
        }

        try? context.save()
    }

    // MARK: - UI

    private var background: some View {

        RoundedRectangle(cornerRadius: 12)
            .fill(backgroundColor)
    }

    private var backgroundColor: Color {

        if isEditingDayOff {

            return selectedDates.contains(calendar.startOfDay(for: date))
                ? .green.opacity(0.28)
                : .clear
        }

        if isPersistedDayOff {
            return .green.opacity(0.20)
        }

        return isSelected
            ? colors.accent.opacity(0.25)
            : .clear
    }


    // 🔵 ОЦЕ ПОВЕРТАЄ ТЕ САМЕ "СИНЄ ОБВЕДЕННЯ"

    private var selectionRing: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                !isEditingDayOff && isSelected
                    ? colors.accent
                    : Color.clear,
                lineWidth: 2
            )
    }
}
