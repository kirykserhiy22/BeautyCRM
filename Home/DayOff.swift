//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 17.05.26.
//
import Foundation
import SwiftData

@Model
final class DayOff: SyncTrackable {

    var id: UUID

    var userID: String

    var date: Date

    // Календарний день рядком «2026-11-07»: не залежить від часового поясу (#52)
    var dayKey: String = ""

    var createdAt: Date

    // MARK: - SYNC

    var workspaceID: UUID? = nil
    var updatedAt: Date? = nil
    var deletedAt: Date? = nil

    init(
        userID: String,
        date: Date,
        calendar: Calendar = .current
    ) {

        self.id = UUID()
        self.userID = userID
        self.date = calendar.startOfDay(for: date)
        self.dayKey = DayOff.key(for: date, calendar: calendar)
        self.createdAt = Date()
    }

    // MARK: - DAY KEY

    static func key(for date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    // Початок цього дня в часовому поясі телефона
    static func date(fromKey key: String, calendar: Calendar = .current) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }
}
