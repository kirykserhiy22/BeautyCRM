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
            
            
            
            VStack {
                
                CalendarPagerView(
                    appointments: userAppointments,
                    dayOffs: userDayOffs,          // 👈 НЕ пустий масив
                    selectedDay: $selectedDate,
                    selectedDates: $selectedDates,
                    isEditingDayOff: false,
                    workingHours: workingHours
                )
                
                Divider()
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredAppointments) { appt in
                            AppointmentRow(
                                appt: appt,
                                expandedAppointmentID: $expandedAppointmentID
                            )
                        }
                    }
                    .padding()
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
        .navigationTitle("Calendar")
        .sheet(isPresented: $showCreate) {
            AppointmentFormView(initialDate: newAppointmentDate)
        }
        .onAppear {
            selectedDate = Date()
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
