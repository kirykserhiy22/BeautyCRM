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
    @Query private var dayOffs: [DayOff]
    
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
    
    var body: some View {
        
        ZStack(alignment: .bottomTrailing) {
            
            
            
            VStack {
                
                CalendarPagerView(
                    appointments: userAppointments,
                    dayOffs: userDayOffs,          // 👈 НЕ пустий масив
                    selectedDay: $selectedDate,
                    selectedDates: $selectedDates,
                    isEditingDayOff: false
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
            AppointmentFormView(initialDate: selectedDate)
        }
        .onAppear {
            selectedDate = Date()
        }
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
