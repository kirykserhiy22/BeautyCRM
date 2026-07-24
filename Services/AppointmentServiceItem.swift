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

    var serviceID: UUID
    var serviceName: String

    var plannedPrice: Double

    // FINAL OVERRIDE (editable only in FINALIZE state)
    var finalPrice: Double?

    var isDeleted: Bool = false

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
