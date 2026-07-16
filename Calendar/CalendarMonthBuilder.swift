//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 14.05.26.
//

import Foundation

struct CalendarMonthBuilder {
    
    static func buildMonth(
        for date: Date
    ) -> [Date?] {
        
        let calendar = Calendar.current
        
        guard let monthInterval =
                calendar.dateInterval(
                    of: .month,
                    for: date
                ),
              let firstWeekday =
                calendar.dateComponents(
                    [.weekday],
                    from: monthInterval.start
                ).weekday
        else {
            return []
        }
        
        let startOffset =
        (firstWeekday + 5) % 7
        
        let days =
        calendar.range(
            of: .day,
            in: .month,
            for: date
        )?.count ?? 0
        
        var result: [Date?] = []
        
        for _ in 0..<startOffset {
            result.append(nil)
        }
        
        for day in 1...days {
            
            if let date =
                calendar.date(
                    byAdding: .day,
                    value: day - 1,
                    to: monthInterval.start
                ) {
                
                result.append(date)
            }
        }
        
        return result
    }
}
