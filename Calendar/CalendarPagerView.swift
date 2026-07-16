//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 14.05.26.
//
import SwiftUI

struct CalendarPagerView: View {
    
    let appointments: [Appointment]
    @Binding var selectedDay: Date
    
    @State private var monthIndex: Int = 0
    private let baseDate = Date()
    
    var body: some View {
        
        VStack(spacing: 12) {
            
            CalendarHeaderView(
                selectedDate: month(for: monthIndex),
                onPrev: { monthIndex -= 1 },
                onNext: { monthIndex += 1 }
            )
            
            TabView(selection: $monthIndex) {
                
                ForEach(-60...60, id: \.self) { offset in
                    
                    CalendarMonthGrid(
                        selectedDate: month(for: offset),
                        appointments: appointments,
                        selectedDay: $selectedDay
                    )
                    .tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .onReceive(NotificationCenter.default.publisher(for: .resetCalendar)) { _ in
            monthIndex = 0
        }
    }
    
    private func month(for offset: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: offset, to: baseDate)!
    }
}
extension Notification.Name {
    static let resetCalendar = Notification.Name("resetCalendar")
}
