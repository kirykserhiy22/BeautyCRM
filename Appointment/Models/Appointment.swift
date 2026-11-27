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
    //   completed → active (випадково завершили — «Повернути в заплановані»)
    //   cancelled → active (відновити), archived (приховати)
    // Прихований запис — кінцевий.
    func canChange(to newStatus: AppointmentStatus) -> Bool {
        switch (self, newStatus) {
        case (.active, .completed),
             (.active, .cancelled),
             (.completed, .active),
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

    // Коли майстер востаннє надіслав клієнту нагадування про цей запис
    var clientReminderSentAt: Date? = nil

    // «Перенести пізніше»: майстер скасував запис, але клієнта треба записати знову —
    // такий запис стоїть у списку «Чекають перенесення», доки його не перенесуть або не приберуть
    var rescheduleRequestedAt: Date? = nil

    // Коли майстер повідомив клієнта про перенесення (позначка в списку «Чекають перенесення»)
    var rescheduleNotifiedAt: Date? = nil

    // Повернення коштів після завершення (скарга тощо): частина або вся оплата
    var refundAmount: Decimal? = nil
    var refundReason: String? = nil
    var refundedAt: Date? = nil

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
    }

    // Скільки майстер отримав насправді: оплата мінус повернення (не менше 0)
    var netPrice: Decimal? {
        finalPrice.map { max($0 - (refundAmount ?? 0), 0) }
    }

    // Яка частка оплати лишилась після повернення (1 — повернень не було).
    // Нею зменшуємо суми окремих послуг в аналітиці
    var keptShare: Decimal {
        guard let finalPrice, finalPrice > 0, let refundAmount, refundAmount > 0 else {
            return 1
        }
        return max(finalPrice - refundAmount, 0) / finalPrice
    }
}
