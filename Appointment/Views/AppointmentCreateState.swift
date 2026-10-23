//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 20.05.26.
import Foundation

struct AppointmentCreateState {

    var client: Client?
    var selectedServices: [Service]
    var customPrices: [UUID: Decimal]

    var startDate: Date
    var duration: Int
    var notes: String

    // MARK: - derived

    var selectedServiceIDs: Set<UUID> {
        Set(selectedServices.map { $0.id })
    }

    var computedPlannedTotal: Decimal {
        selectedServices.reduce(0) { sum, service in
            switch service.pricingType {
            case .fixed:
                return sum + (service.price ?? 0)
            case .variable:
                return sum + (customPrices[service.id] ?? 0)
            }
        }
    }
}
