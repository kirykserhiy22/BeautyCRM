//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 14.05.26.
//
import SwiftUI

struct CalendarPagerView: View {
    
    let appointments: [Appointment]
    let dayOffs: [DayOff]
    
    @Binding var selectedDay: Date
    @Binding var selectedDates: Set<Date>
    let isEditingDayOff: Bool
    
    @State private var monthIndex: Int = 0
    @State private var baseDate: Date = Date()
    
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        
        VStack(spacing: 12) {
            
            CalendarHeaderView(
                selectedDate: month(for: monthIndex),
                onPrev: { monthIndex -= 1 },
                onNext: { monthIndex += 1 }
            )
            .padding(.horizontal)
            
            CalendarWeekdayHeaderView()
                .padding(.horizontal)
            
            TabView(selection: $monthIndex) {
                
                ForEach(-60...60, id: \.self) { offset in
                    
                    CalendarMonthGrid(
                        selectedDate: month(for: offset),
                        appointments: appointments,
                        dayOffs: dayOffs,
                        selectedDay: $selectedDay,
                        selectedDates: $selectedDates,
                        isEditingDayOff: isEditingDayOff
                    )
                    .tag(offset)
                }
            }
            .frame(height: 420)
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .onAppear {
            resetToToday()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                resetToToday()
            }
        }
    }
    
    // MARK: - RESET
    
    private func resetToToday() {
        let now = Date()
        baseDate = now
        monthIndex = 0
        selectedDay = now
    }
    
    // MARK: - MONTH
    
    private func month(for offset: Int) -> Date {
        Calendar.current.date(
            byAdding: .month,
            value: offset,
            to: baseDate
        )!
    }
}
