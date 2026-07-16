//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 03.05.26.
//

import SwiftUI
import SwiftData

struct CalendarScreen: View {
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var theme: ThemeManager
    
    @Query private var appointments: [Appointment]
    
    @State private var selectedDate = Date()
    @State private var showCreate = false
    
    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }
    
    var body: some View {
        
        ZStack(alignment: .bottomTrailing) {
            
            VStack {
                
                CalendarPagerView(
                    appointments: appointments,
                    selectedDay: $selectedDate
                )
                
                Divider()
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredAppointments) { appt in
                            AppointmentRow(appt: appt)
                        }
                    }
                    .padding()
                }
            }
            
            // 🔥 FLOATING BUTTON
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
            .padding()
        }
        .navigationTitle("Calendar")
        
        .sheet(isPresented: $showCreate) {
            AppointmentFormView(initialDate: selectedDate)
        }
        
        .onAppear {
            selectedDate = Date()
            NotificationCenter.default.post(name: .resetCalendar, object: nil)
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
