//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 03.05.26.
//

import SwiftUI
import SwiftData

struct CalendarScreen: View {
    @EnvironmentObject var localization: LocalizationManager
    @Environment(\.modelContext) private var context
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var theme: ThemeManager
    
    @Query private var appointments: [Appointment]
    @Query private var profiles: [UserProfile]
    @Query(filter: #Predicate<DayOff> { $0.deletedAt == nil })
    private var dayOffs: [DayOff]
    
    @State private var selectedDate = Date()
    @State private var selectedDates: Set<Date> = []   // 👈 ВАЖЛИВО
    @State private var showCreate = false
    @State private var expandedAppointmentID: UUID?

    // Календар згорнутий в один тиждень (коли список записів прокручено вгору)
    @State private var isCalendarCollapsed = false

    private let listSpace = "appointmentsList"
    
    private var userDayOffs: [DayOff] {
        guard let userID = appState.session.userID else { return [] }
        return dayOffs.filter { $0.userID == userID }
    }
    private var userAppointments: [Appointment] {

        guard let userID = appState.session.userID else {
            return []
        }

        return appointments.filter {
            $0.userID == userID
        }
    }
    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    private var workingHours: DayTimeScale {
        let profile = profiles.first {
            $0.authUserID == appState.session.userID
        }
        return .workingHours(profile)
    }
    
    var body: some View {
        
        ZStack(alignment: .bottomTrailing) {
            
            
            
            VStack(spacing: 0) {

                if isCalendarCollapsed {

                    CalendarWeekStrip(
                        appointments: userAppointments,
                        dayOffs: userDayOffs,
                        selectedDay: $selectedDate,
                        workingHours: workingHours,
                        onExpand: { setCalendarCollapsed(false) }
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))

                } else {

                    CalendarPagerView(
                        appointments: userAppointments,
                        dayOffs: userDayOffs,          // 👈 НЕ пустий масив
                        selectedDay: $selectedDate,
                        selectedDates: $selectedDates,
                        isEditingDayOff: false,
                        workingHours: workingHours
                    )
                    .transition(.opacity)
                }

                collapseHandle

                ScrollView {
                    LazyVStack(spacing: 12) {

                        if filteredAppointments.isEmpty {
                            emptyDayView
                        }

                        ForEach(filteredAppointments) { appt in
                            AppointmentRow(
                                appt: appt,
                                expandedAppointmentID: $expandedAppointmentID
                            )
                        }
                    }
                    .padding()
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: AppointmentListOffsetKey.self,
                                value: geo.frame(in: .named(listSpace)).minY
                            )
                        }
                    )
                }
                .coordinateSpace(name: listSpace)
                .onListScroll { offset in
                    handleListOffset(offset)
                }
            }
            Button {
                showCreate = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .foregroundColor(colors.background)
                    .padding()
                    .background(colors.floatingButton)
                    .clipShape(Circle())
                    .shadow(
                        color: colors.shadow,
                        radius: 8,
                        y: 4
                    )
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        .background(colors.background)
        .navigationTitle(localization.localizedString(for: "tab.calendar"))
        .sheet(isPresented: $showCreate) {
            AppointmentFormView(initialDate: newAppointmentDate)
        }
        .onAppear {
            selectedDate = Date()
        }
    }
    
    // MARK: - EMPTY DAY

    // Підказка, коли на вибраний день немає записів
    private var emptyDayView: some View {

        VStack(spacing: 12) {

            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 32))
                .foregroundColor(colors.textSecondary.opacity(0.6))

            Text(localization.localizedString(for: "calendar.emptyDay"))
                .font(.subheadline)
                .foregroundColor(colors.textSecondary)

            Button {
                showCreate = true
            } label: {
                Text(localization.localizedString(for: "calendar.addAppointment"))
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(colors.accent.opacity(0.12))
                    .foregroundColor(colors.accent)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }


    // MARK: - COLLAPSE

    // Смужка-ручка між календарем і списком: дотик згортає / розгортає календар
    private var collapseHandle: some View {

        Button {
            setCalendarCollapsed(!isCalendarCollapsed)
        } label: {
            Capsule()
                .fill(colors.textSecondary.opacity(0.35))
                .frame(width: 36, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // Прокрутка списку вгору згортає календар у тиждень;
    // потягнути список вниз на самому верху — розгортає назад
    private func handleListOffset(_ offset: CGFloat) {

        if !isCalendarCollapsed && offset < -24 {
            setCalendarCollapsed(true)
        } else if isCalendarCollapsed && offset > 48 {
            setCalendarCollapsed(false)
        }
    }

    private func setCalendarCollapsed(_ collapsed: Bool) {

        guard collapsed != isCalendarCollapsed else {
            return
        }

        withAnimation(.snappy(duration: 0.3)) {
            isCalendarCollapsed = collapsed
        }
    }

    // Час нового запису: сьогодні — найближча кругла година,
    // інший день — початок робочого дня (а не 00:00)
    private var newAppointmentDate: Date {

        let calendar = Calendar.current

        if calendar.isDateInToday(selectedDate) {
            return calendar.nextDate(
                after: Date(),
                matching: DateComponents(minute: 0),
                matchingPolicy: .nextTime
            ) ?? Date()
        }

        return calendar.date(
            byAdding: .minute,
            value: workingHours.startMinute,
            to: calendar.startOfDay(for: selectedDate)
        ) ?? selectedDate
    }

    private var filteredAppointments: [Appointment] {
        guard let userID = appState.session.userID else { return [] }
        
        return appointments.filter {
            $0.userID == userID &&
            $0.status != .archived &&
            Calendar.current.isDate($0.startDate, inSameDayAs: selectedDate)
        }
        .sorted { $0.startDate < $1.startDate }
    }
}



// Положення верху списку записів (від'ємне, коли список прокручено вгору)
private struct AppointmentListOffsetKey: PreferenceKey {

    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}



private extension View {

    // Повідомляє, наскільки список прокручено (від'ємне — прокручено вгору).
    // На iOS 18+ — через системне API прокрутки; на iOS 17 — через GeometryReader.
    @ViewBuilder
    func onListScroll(_ action: @escaping (CGFloat) -> Void) -> some View {

        if #available(iOS 18.0, *) {
            self.onScrollGeometryChange(for: CGFloat.self) { geometry in
                -(geometry.contentOffset.y + geometry.contentInsets.top)
            } action: { _, offset in
                action(offset)
            }
        } else {
            self.onPreferenceChange(AppointmentListOffsetKey.self) { offset in
                action(offset)
            }
        }
    }
}
