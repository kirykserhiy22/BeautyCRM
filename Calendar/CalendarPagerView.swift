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

    var workingHours: DayTimeScale = .defaultWorkingHours
    
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
                        workingHours: workingHours,
                        selectedDay: $selectedDay,
                        selectedDates: $selectedDates,
                        isEditingDayOff: isEditingDayOff
                    )
                    .padding(.horizontal)
                    .tag(offset)
                }
            }
            .frame(height: 420)
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .onAppear {
            // Показати місяць вибраного дня (а не скидати вибір на сьогодні):
            // календар з'являється знову після розгортання з тижня
            baseDate = Date()
            monthIndex = monthOffset(of: selectedDay)
        }
        .onChange(of: selectedDay) {
            // Якщо день вибрали в іншому місяці (напр. гортаючи тижні) — перейти до нього
            let offset = monthOffset(of: selectedDay)
            if offset != monthIndex {
                monthIndex = offset
            }
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

    private func monthOffset(of date: Date) -> Int {
        let calendar = Calendar.current
        let base = calendar.dateComponents([.year, .month], from: baseDate)
        let target = calendar.dateComponents([.year, .month], from: date)
        let offset = ((target.year ?? 0) - (base.year ?? 0)) * 12
            + ((target.month ?? 0) - (base.month ?? 0))
        return min(max(offset, -60), 60)
    }
    
    private func month(for offset: Int) -> Date {
        Calendar.current.date(
            byAdding: .month,
            value: offset,
            to: baseDate
        )!
    }
}



// MARK: - WEEK STRIP

// Календар, згорнутий в один тиждень. Показується, коли список записів
// прокручують вгору. Тижні гортаються вбік, дотик до назви місяця розгортає календар.
struct CalendarWeekStrip: View {

    let appointments: [Appointment]
    let dayOffs: [DayOff]

    @Binding var selectedDay: Date

    var workingHours: DayTimeScale = .defaultWorkingHours

    let onExpand: () -> Void

    @State private var weekIndex = 0
    @State private var baseWeekStart = Date()

    private let columns = Array(
        repeating: GridItem(.flexible()),
        count: 7
    )

    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
    }

    var body: some View {

        VStack(spacing: 12) {

            CalendarHeaderView(
                selectedDate: selectedDay,
                onPrev: { weekIndex -= 1 },
                onNext: { weekIndex += 1 },
                onTitleTap: onExpand
            )
            .padding(.horizontal)

            CalendarWeekdayHeaderView()
                .padding(.horizontal)

            TabView(selection: $weekIndex) {

                ForEach(-260...260, id: \.self) { offset in

                    weekRow(startingAt: weekStart(for: offset))
                        .padding(.horizontal)
                        .tag(offset)
                }
            }
            .frame(height: 66)
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .onAppear {
            baseWeekStart = startOfWeek(selectedDay)
            weekIndex = 0
        }
        .onChange(of: weekIndex) { oldIndex, newIndex in
            // Гортання тижня переносить вибір на той самий день тижня
            if let moved = calendar.date(
                byAdding: .weekOfYear,
                value: newIndex - oldIndex,
                to: selectedDay
            ) {
                selectedDay = moved
            }
        }
    }

    private func weekRow(startingAt start: Date) -> some View {

        let days = (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: start)
        }

        return LazyVGrid(columns: columns, spacing: 8) {

            ForEach(days, id: \.self) { date in

                CalendarDayCell(
                    date: date,
                    isSelected: calendar.isDate(date, inSameDayAs: selectedDay),
                    appointments: appointments,
                    dayOffs: dayOffs,
                    scale: DayTimeScale.forMonth(
                        date,
                        appointments: appointments,
                        workingHours: workingHours
                    ),
                    onTap: { selectedDay = date },
                    isEditingDayOff: false,
                    selectedDates: .constant([])
                )
            }
        }
    }

    private func startOfWeek(_ date: Date) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start
            ?? calendar.startOfDay(for: date)
    }

    private func weekStart(for offset: Int) -> Date {
        calendar.date(byAdding: .weekOfYear, value: offset, to: baseWeekStart)
            ?? baseWeekStart
    }
}
