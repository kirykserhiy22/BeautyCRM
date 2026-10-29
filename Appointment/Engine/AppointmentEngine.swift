//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 03.05.26.
//

import Foundation
import SwiftData

enum AppointmentError: Error {
    case timeConflict
    case noClient
    case noServices
}

struct ConflictResult {
    let hasConflict: Bool
    let suggestedStart: Date?
    let suggestedEnd: Date?
}

final class AppointmentEngine {

    // MARK: - CONFLICT

    static func hasConflict(
        newStart: Date,
        newEnd: Date,
        existing: [Appointment],
        ignoring appointmentID: UUID? = nil
    ) -> Bool {

        for appt in existing {
            if appt.id == appointmentID { continue }
            guard appt.status == .active else { continue }

            if newStart < appt.endDate && newEnd > appt.startDate {
                return true
            }
        }

        return false
    }

    static func conflictResult(
        newStart: Date,
        duration: Int,
        existing: [Appointment],
        ignoring appointmentID: UUID? = nil
    ) -> ConflictResult {

        let newEnd = Calendar.current.date(
            byAdding: .minute,
            value: duration,
            to: newStart
        )!

        let active = existing
            .filter { $0.status == .active && $0.id != appointmentID }
            .sorted { $0.startDate < $1.startDate }

        let hasConflict = active.contains {
            newStart < $0.endDate && newEnd > $0.startDate
        }

        if !hasConflict {
            return ConflictResult(hasConflict: false, suggestedStart: nil, suggestedEnd: nil)
        }

        for i in 0..<active.count {
            let current = active[i]
            let slotStart = current.endDate

            let slotEnd: Date = (i + 1 < active.count)
                ? active[i + 1].startDate
                : Calendar.current.date(byAdding: .hour, value: 12, to: slotStart)!

            let free = Int(slotEnd.timeIntervalSince(slotStart) / 60)

            if free >= duration && slotStart >= newStart {
                return ConflictResult(
                    hasConflict: true,
                    suggestedStart: slotStart,
                    suggestedEnd: Calendar.current.date(
                        byAdding: .minute,
                        value: duration,
                        to: slotStart
                    )
                )
            }
        }

        return ConflictResult(hasConflict: true, suggestedStart: nil, suggestedEnd: nil)
    }

    // MARK: - CREATE

    static func createAppointment(
        context: ModelContext,
        userID: String,
        client: Client,
        services: [Service],
        selectedServiceIDs: Set<UUID>,
        customPrices: [UUID: Decimal],
        startDate: Date,
        duration: Int,
        notes: String,
        existingAppointments: [Appointment]
    ) -> Result<Appointment, AppointmentError> {

        let endDate = Calendar.current.date(
            byAdding: .minute,
            value: duration,
            to: startDate
        )!

        if hasConflict(newStart: startDate, newEnd: endDate, existing: existingAppointments) {
            return .failure(.timeConflict)
        }

        let selected = services.filter { selectedServiceIDs.contains($0.id) }

        guard !selected.isEmpty else {
            return .failure(.noServices)
        }

        let items = selected.map {
            AppointmentServiceItem(
                serviceID: $0.id,
                serviceName: $0.name,
                plannedPrice: ($0.pricingType == .fixed)
                    ? ($0.price ?? 0)
                    : (customPrices[$0.id] ?? 0),
                duration: nil
            )
        }

        let appointment = Appointment(
            userID: userID,
            clientID: client.id,
            clientName: client.name,
            startDate: startDate,
            duration: duration,
            notes: notes
        )

        appointment.services = items
        context.insert(appointment)

        return .success(appointment)
    }

    // MARK: - UPDATE
    

    static func updateAppointment(
        appointment: Appointment,
        client: Client,
        services: [Service],
        selectedServiceIDs: Set<UUID>,
        customPrices: [UUID: Decimal],
        startDate: Date,
        duration: Int,
        notes: String,
        existingAppointments: [Appointment]
    ) -> Result<Void, AppointmentError> {

        let endDate = Calendar.current.date(
            byAdding: .minute,
            value: duration,
            to: startDate
        )!

        if hasConflict(
            newStart: startDate,
            newEnd: endDate,
            existing: existingAppointments,
            ignoring: appointment.id
        ) {
            return .failure(.timeConflict)
        }

        // Послуги, що вже є в записі, лишаються з погодженою ціною —
        // навіть якщо їх змінили чи видалили в прайсі.
        // Змінна ціна оновлюється лише тим, що майстер ввів у формі.
        let kept: [AppointmentServiceItem] = appointment.services
            .filter { selectedServiceIDs.contains($0.serviceID) }
            .map { item in
                let service = services.first { $0.id == item.serviceID }
                if service?.pricingType == .variable,
                   let custom = customPrices[item.serviceID] {
                    item.plannedPrice = custom
                }
                return item
            }

        let keptIDs = Set(kept.map(\.serviceID))

        // Нові послуги — з поточного прайсу
        let added = services
            .filter { selectedServiceIDs.contains($0.id) && !keptIDs.contains($0.id) }
            .map {
                AppointmentServiceItem(
                    serviceID: $0.id,
                    serviceName: $0.name,
                    plannedPrice: ($0.pricingType == .fixed)
                        ? ($0.price ?? 0)
                        : (customPrices[$0.id] ?? 0),
                    duration: nil
                )
            }

        guard !(kept.isEmpty && added.isEmpty) else {
            return .failure(.noServices)
        }

        appointment.services = kept + added

        appointment.clientID = client.id
        appointment.clientName = client.name
        appointment.startDate = startDate
        appointment.duration = duration
        appointment.notes = notes

        return .success(())
    }

    // MARK: - COMPLETE

    static func complete(
        appointment: Appointment,
        finalServicePrices: [UUID: Decimal]
    ) {

        var total: Decimal = 0

        for index in appointment.services.indices {

            let serviceID =
                appointment.services[index].serviceID

            let final =
                finalServicePrices[serviceID]
                ?? appointment.services[index].plannedPrice

            appointment.services[index].finalPrice = final

            total += final
        }

        appointment.finalPrice = total
        appointment.status = .completed
        appointment.completedAt = Date()
    }

    // MARK: - CANCEL

    static func cancel(appointment: Appointment) {
        appointment.status = .cancelled
    }
    
}
