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
}

@Model
final class Appointment {
    
    var id: UUID
    
    // OWNER
    var userID: String
    
    // CLIENT SNAPSHOT
    var clientID: UUID
    var clientName: String
    
    // SERVICE SNAPSHOT
    var serviceName: String
    var servicePrice: Double
    
    // TIME
    var startDate: Date
    var duration: Int
    
    // STATUS
    var status: AppointmentStatus
    
    // 💰 MONEY MODEL
    var plannedPrice: Double
    var finalPrice: Double?
    
    // NOTES
    var notes: String?
    
    // META
    var createdAt: Date
    var completedAt: Date?
    
    init(
        userID: String,
        clientID: UUID,
        clientName: String,
        serviceName: String,
        servicePrice: Double,
        startDate: Date,
        duration: Int,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.userID = userID
        self.clientID = clientID
        self.clientName = clientName
        self.serviceName = serviceName
        self.servicePrice = servicePrice
        self.plannedPrice = servicePrice
        self.finalPrice = nil
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
}
