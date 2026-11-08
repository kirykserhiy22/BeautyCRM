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
    // Дія не дозволена для поточного статусу запису
    case invalidStatus
    // Для послуги зі змінною ціною не введено суму
    case missingPrice
    // Запис не можна перенести на час, що вже минув
    case pastTime


    // Ключ з Localizable.strings — текст перекладається на мову додатку
    var localizationKey: String {
        switch self {
        case .timeConflict:
            return "appointment.error.timeConflict"
        case .noClient:
            return "appointment.error.noClient"
        case .noServices:
            return "appointment.error.noServices"
        case .invalidStatus:
            return "appointment.error.invalidStatus"
        case .missingPrice:
            return "appointment.error.missingPrice"
        case .pastTime:
            return "appointment.error.pastTime"
        }
    }
}

// Обмін двох записів часом: запис кинули на інший
struct AppointmentSwapPlan {
    let moved: Appointment
    let movedStart: Date
    let other: Appointment
    let otherStart: Date
}

struct ConflictResult {
    let hasConflict: Bool
    let suggestedStart: Date?
    let suggestedEnd: Date?
}

final class AppointmentEngine {

    // MARK: - PRICES

    // Кожна вибрана послуга зі змінною ціною має мати введену суму
    // (0 дозволений, якщо його ввели свідомо — тоді він є в customPrices)
    static func hasMissingPrice(
        services: [Service],
        selectedServiceIDs: Set<UUID>,
        customPrices: [UUID: Decimal]
    ) -> Bool {
        services.contains {
            selectedServiceIDs.contains($0.id)
                && $0.pricingType == .variable
                && customPrices[$0.id] == nil
        }
    }

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

    // Час зайнятий — шукаємо найближче вільне вікно в той самий день:
    // лише в робочі години, і раніше, і пізніше бажаного часу (#37)
    static func conflictResult(
        newStart: Date,
        duration: Int,
        existing: [Appointment],
        ignoring appointmentID: UUID? = nil,
        workingHours: DayTimeScale = .defaultWorkingHours,
        now: Date = Date()
    ) -> ConflictResult {

        let calendar = Calendar.current

        let newEnd = calendar.date(
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

        let suggested = nearestFreeStart(
            to: newStart,
            duration: duration,
            active: active,
            workingHours: workingHours,
            now: now,
            calendar: calendar
        )

        return ConflictResult(
            hasConflict: true,
            suggestedStart: suggested,
            suggestedEnd: suggested.flatMap {
                calendar.date(byAdding: .minute, value: duration, to: $0)
            }
        )
    }

    private static func nearestFreeStart(
        to wanted: Date,
        duration: Int,
        active: [Appointment],
        workingHours: DayTimeScale,
        now: Date,
        calendar: Calendar
    ) -> Date? {

        let day = calendar.startOfDay(for: wanted)
        let needed = TimeInterval(duration * 60)

        guard
            var cursor = calendar.date(byAdding: .minute, value: workingHours.startMinute, to: day),
            let dayEnd = calendar.date(byAdding: .minute, value: workingHours.endMinute, to: day)
        else {
            return nil
        }

        // Сьогодні минулий час не пропонуємо (округлення вгору до 5 хвилин)
        if calendar.isDate(wanted, inSameDayAs: now) {
            let step: TimeInterval = 5 * 60
            let nextStep = Date(timeIntervalSinceReferenceDate: (now.timeIntervalSinceReferenceDate / step).rounded(.up) * step)
            cursor = max(cursor, nextStep)
        }

        var best: Date?

        func consider(gapEnd: Date) {
            guard gapEnd.timeIntervalSince(cursor) >= needed else {
                return
            }
            // Найближчий до бажаного початок, за якого запис влазить у вікно
            let latest = gapEnd.addingTimeInterval(-needed)
            let candidate = min(max(wanted, cursor), latest)

            guard let current = best else {
                best = candidate
                return
            }
            // Однакова відстань — кращий пізніший час: він не зсуває клієнта наперед
            if abs(candidate.timeIntervalSince(wanted)) <= abs(current.timeIntervalSince(wanted)) {
                best = candidate
            }
        }

        for appointment in active where appointment.endDate > cursor && appointment.startDate < dayEnd {
            consider(gapEnd: appointment.startDate)
            cursor = max(cursor, appointment.endDate)
        }

        consider(gapEnd: dayEnd)

        return best
    }

    // MARK: - DAY OFF

    // Запис на вихідний не заборонений: форма лише попереджає майстра
    static func isDayOff(
        _ date: Date,
        dayOffs: [DayOff]
    ) -> Bool {
        let key = DayOff.key(for: date)
        return dayOffs.contains { $0.dayKey == key }
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

        if hasMissingPrice(services: services, selectedServiceIDs: selectedServiceIDs, customPrices: customPrices) {
            return .failure(.missingPrice)
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

        // Змінювати можна лише запланований запис:
        // завершений уже в доході, скасований треба спершу відновити
        guard appointment.status == .active else {
            return .failure(.invalidStatus)
        }

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

        if hasMissingPrice(services: services, selectedServiceIDs: selectedServiceIDs, customPrices: customPrices) {
            return .failure(.missingPrice)
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

    @discardableResult
    // addedServices — послуги, які клієнт замовив уже на місці.
    // Тривалість запису не змінюється: він уже завершується.
    static func complete(
        appointment: Appointment,
        finalServicePrices: [UUID: Decimal],
        addedServices: [AppointmentServiceItem] = []
    ) -> Result<Void, AppointmentError> {

        guard appointment.status.canChange(to: .completed) else {
            return .failure(.invalidStatus)
        }

        let existingIDs = Set(appointment.services.map(\.serviceID))

        appointment.services.append(
            contentsOf: addedServices.filter { !existingIDs.contains($0.serviceID) }
        )

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

        return .success(())
    }

    // MARK: - RESCHEDULE

    // Перенесення зі шкали: змінюється лише час початку
    static func reschedule(
        appointment: Appointment,
        to newStart: Date,
        existingAppointments: [Appointment],
        now: Date = Date()
    ) -> Result<Void, AppointmentError> {

        guard appointment.status == .active else {
            return .failure(.invalidStatus)
        }

        guard newStart >= now else {
            return .failure(.pastTime)
        }

        let newEnd = Calendar.current.date(
            byAdding: .minute,
            value: appointment.duration,
            to: newStart
        ) ?? newStart

        if hasConflict(
            newStart: newStart,
            newEnd: newEnd,
            existing: existingAppointments,
            ignoring: appointment.id
        ) {
            return .failure(.timeConflict)
        }

        appointment.startDate = newStart

        return .success(())
    }

    // Можна обміняти, якщо запис кинули рівно на один інший активний запис.
    // Перший за часом слот стає початком для другого запису, а перший запис
    // стає на місце другого, або одразу після нього, якщо другий довший.
    static func swapPlan(
        appointment: Appointment,
        droppedAt newStart: Date,
        existingAppointments: [Appointment],
        now: Date = Date()
    ) -> AppointmentSwapPlan? {

        guard appointment.status == .active else {
            return nil
        }

        let calendar = Calendar.current

        func end(_ start: Date, _ duration: Int) -> Date {
            calendar.date(byAdding: .minute, value: duration, to: start) ?? start
        }

        let newEnd = end(newStart, appointment.duration)

        let overlapping = existingAppointments.filter {
            $0.status == .active && $0.id != appointment.id
                && newStart < $0.endDate && newEnd > $0.startDate
        }

        guard overlapping.count == 1, let other = overlapping.first else {
            return nil
        }

        let (first, second) = appointment.startDate <= other.startDate
            ? (appointment, other)
            : (other, appointment)

        let secondNewStart = first.startDate
        let firstNewStart = max(second.startDate, end(secondNewStart, second.duration))

        let starts = [
            (first, firstNewStart),
            (second, secondNewStart)
        ]

        guard starts.allSatisfy({ $0.1 >= now }) else {
            return nil
        }

        let rest = existingAppointments.filter {
            $0.id != appointment.id && $0.id != other.id
        }

        for (item, start) in starts where hasConflict(
            newStart: start,
            newEnd: end(start, item.duration),
            existing: rest
        ) {
            return nil
        }

        return AppointmentSwapPlan(
            moved: appointment,
            movedStart: first.id == appointment.id ? firstNewStart : secondNewStart,
            other: other,
            otherStart: first.id == other.id ? firstNewStart : secondNewStart
        )
    }

    // Повернення часу кількох записів разом (кнопка «Скасувати», обмін).
    // Минулий час тут дозволений: запис міг там і стояти.
    @discardableResult
    static func setStarts(
        _ starts: [(appointment: Appointment, start: Date)],
        existingAppointments: [Appointment]
    ) -> Bool {

        let ids = Set(starts.map(\.appointment.id))
        let rest = existingAppointments.filter { !ids.contains($0.id) }

        for item in starts {

            let end = Calendar.current.date(
                byAdding: .minute,
                value: item.appointment.duration,
                to: item.start
            ) ?? item.start

            guard item.appointment.status == .active,
                  !hasConflict(newStart: item.start, newEnd: end, existing: rest)
            else {
                return false
            }
        }

        for item in starts {
            item.appointment.startDate = item.start
        }

        return true
    }

    // MARK: - CANCEL

    @discardableResult
    static func cancel(appointment: Appointment) -> Result<Void, AppointmentError> {

        guard appointment.status.canChange(to: .cancelled) else {
            return .failure(.invalidStatus)
        }

        appointment.status = .cancelled
        return .success(())
    }

    // MARK: - RESTORE

    // Повертає скасований запис у заплановані, якщо його час досі вільний
    @discardableResult
    static func restore(
        appointment: Appointment,
        existingAppointments: [Appointment]
    ) -> Result<Void, AppointmentError> {

        guard appointment.status.canChange(to: .active) else {
            return .failure(.invalidStatus)
        }

        if hasConflict(
            newStart: appointment.startDate,
            newEnd: appointment.endDate,
            existing: existingAppointments,
            ignoring: appointment.id
        ) {
            return .failure(.timeConflict)
        }

        appointment.status = .active
        return .success(())
    }

    // MARK: - ARCHIVE

    // Ховає скасований запис з календаря
    @discardableResult
    static func archive(appointment: Appointment) -> Result<Void, AppointmentError> {

        guard appointment.status.canChange(to: .archived) else {
            return .failure(.invalidStatus)
        }

        appointment.status = .archived
        return .success(())
    }
}
