//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 03.05.26.
//

import Foundation

final class AppointmentEngine {
    
    static func hasConflict(
        newStart: Date,
        newEnd: Date,
        existing: [Appointment]
    ) -> Bool {
        
        for appt in existing {
            
            guard appt.status == .active else { continue }
            
            let overlap = newStart < appt.endDate &&
                          newEnd > appt.startDate
            
            if overlap { return true }
        }
        
        return false
    }
    
    static func complete(
        appointment: Appointment,
        finalPrice: Double
    ) {
        appointment.status = .completed
        appointment.finalPrice = finalPrice
        appointment.completedAt = Date()
    }
}
