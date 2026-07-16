//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 20.05.26.
//
import Foundation
import SwiftData

@Model
final class AppointmentServiceItem {

    var id: UUID

    // SERVICE SNAPSHOT
    var serviceID: UUID
    var serviceName: String

    // PRICE SNAPSHOT
    var plannedPrice: Double
    var finalPrice: Double?

    // OPTIONAL DURATION
    var duration: Int?

    init(
        serviceID: UUID,
        serviceName: String,
        plannedPrice: Double,
        duration: Int? = nil
    ) {

        self.id = UUID()

        self.serviceID = serviceID
        self.serviceName = serviceName

        self.plannedPrice = plannedPrice
        self.finalPrice = nil

        self.duration = duration
    }
}
