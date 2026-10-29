//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 03.05.26.
//

import Foundation
import SwiftData

enum AppointmentStatus: String, Codable {
    case active
    case completed
    case cancelled
    case archived


    // Дозволені переходи між статусами — одне місце для всього додатку
    // (екрани, а пізніше синхронізація і веб-версія):
    //   active    → completed, cancelled
    //   cancelled → active (відновити), archived (приховати)
    // Завершений і прихований записи — кінцеві.
    func canChange(to newStatus: AppointmentStatus) -> Bool {
        switch (self, newStatus) {
        case (.active, .completed),
             (.active, .cancelled),
             (.cancelled, .active),
             (.cancelled, .archived):
            return true
        default:
            return false
        }
    }
}

@Model
final class Appointment: SyncTrackable {

    var id: UUID
    var userID: String

    var clientID: UUID
    var clientName: String

    var services: [AppointmentServiceItem]

    var startDate: Date
    var duration: Int
    var notes: String?
    var status: AppointmentStatus

    var createdAt: Date
    var completedAt: Date?

    // CACHE ONLY (НЕ business truth)
    var finalPrice: Decimal?

    // MARK: - SYNC

    var workspaceID: UUID? = nil
    var updatedAt: Date? = nil
    var deletedAt: Date? = nil
    
    
    
    init(
        userID: String,
        clientID: UUID,
        clientName: String,
        startDate: Date,
        duration: Int,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.userID = userID
        self.clientID = clientID
        self.clientName = clientName

        self.services = []

        self.startDate = startDate
        self.duration = duration
        self.status = .active

        self.notes = notes
        self.createdAt = Date()
    }
}
extension Appointment {
    
    var endDate: Date {
        Calendar.current.date(byAdding: .minute, value: duration, to: startDate) ?? startDate
    }
    var totalPlannedPrice: Decimal {
        services.reduce(0) { $0 + $1.plannedPrice }
    }

    var totalFinalPrice: Decimal {
        services.reduce(0) {
            $0 + ($1.finalPrice ?? $1.plannedPrice)
        }
    }}
