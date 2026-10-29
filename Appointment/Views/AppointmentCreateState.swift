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

    // MARK: - editing

    // Ціни послуг, уже погоджені в записі (serviceID → ціна).
    // Фіксована ціна береться звідси, а не з поточного прайсу.
    var agreedPrices: [UUID: Decimal] = [:]

    // Послуги запису, яких уже немає в прайсі: лишаються як є
    var retainedItems: [AppointmentServiceItem] = []

    // MARK: - derived

    var selectedServiceIDs: Set<UUID> {
        Set(selectedServices.map { $0.id } + retainedItems.map { $0.serviceID })
    }

    func price(for service: Service) -> Decimal {
        switch service.pricingType {
        case .fixed:
            return agreedPrices[service.id] ?? service.price ?? 0
        case .variable:
            return customPrices[service.id] ?? 0
        }
    }

    var computedPlannedTotal: Decimal {
        selectedServices.reduce(0) { $0 + price(for: $1) }
            + retainedItems.reduce(0) { $0 + $1.plannedPrice }
    }
}
