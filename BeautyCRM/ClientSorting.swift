//
//  ClientSorting.swift
//  BeautyCRM
//
//  Сортування списку клієнтів і «Найближчі» — ті, в кого запис найближчим часом.
//  Без SwiftUI — перевіряється тестами.
//

import Foundation


enum ClientSort: String, CaseIterable, Identifiable {

    case nameAscending, nameDescending
    case recentVisit, oldestVisit, noVisits
    case recentlyAdded

    var id: String { rawValue }
    var titleKey: String { "clients.sort.\(rawValue)" }

    var icon: String {
        switch self {
        case .nameAscending: return "textformat.abc"
        case .nameDescending: return "textformat.abc.dottedunderline"
        case .recentVisit: return "clock.arrow.circlepath"
        case .oldestVisit: return "hourglass"
        case .noVisits: return "person.crop.circle.badge.questionmark"
        case .recentlyAdded: return "sparkles"
        }
    }

    // Групи в екрані вибору
    enum Group: String, CaseIterable {
        case name, visit, added
        var titleKey: String { "clients.sort.group.\(rawValue)" }
    }

    var group: Group {
        switch self {
        case .nameAscending, .nameDescending: return .name
        case .recentVisit, .oldestVisit, .noVisits: return .visit
        case .recentlyAdded: return .added
        }
    }
}


enum ClientSorting {

    // Останній завершений візит кожного клієнта
    static func lastVisits(_ appointments: [Appointment]) -> [UUID: Date] {
        appointments
            .filter { $0.status == .completed }
            .reduce(into: [UUID: Date]()) { result, appointment in
                result[appointment.clientID] = max(result[appointment.clientID] ?? .distantPast, appointment.startDate)
            }
    }

    // «Без візитів» — спершу ті, хто ще не приходив; «давні» — ті, хто давно не був
    static func sorted(
        _ clients: [Client],
        by sort: ClientSort,
        lastVisits: [UUID: Date],
        locale: Locale = .current
    ) -> [Client] {

        func byName(_ a: Client, _ b: Client) -> Bool {
            a.name.compare(b.name, options: [.caseInsensitive, .diacriticInsensitive], locale: locale) == .orderedAscending
        }

        switch sort {

        case .nameAscending:
            return clients.sorted(by: byName)

        case .nameDescending:
            return clients.sorted { byName($1, $0) }

        case .recentVisit:
            return clients.sorted {
                let a = lastVisits[$0.id], b = lastVisits[$1.id]
                if a != b { return (a ?? .distantPast) > (b ?? .distantPast) }
                return byName($0, $1)
            }

        case .oldestVisit:
            // Хто ще не приходив — у кінці: «давно не була» стосується тих, хто приходив
            return clients.sorted {
                let a = lastVisits[$0.id] ?? .distantFuture, b = lastVisits[$1.id] ?? .distantFuture
                if a != b { return a < b }
                return byName($0, $1)
            }

        case .noVisits:
            return clients.sorted {
                let a = lastVisits[$0.id] == nil, b = lastVisits[$1.id] == nil
                if a != b { return a }
                return $0.createdAt > $1.createdAt
            }

        case .recentlyAdded:
            return clients.sorted { $0.createdAt > $1.createdAt }
        }
    }

    // «Найближчі»: в кого запланований запис протягом `days` днів, від найближчого
    static func upcoming(
        _ clients: [Client],
        appointments: [Appointment],
        now: Date = Date(),
        days: Int = 7,
        calendar: Calendar = .current
    ) -> [(client: Client, start: Date)] {

        let limit = calendar.date(byAdding: .day, value: days, to: now) ?? now
        var next: [UUID: Date] = [:]
        for appointment in appointments where appointment.status == .active
            && appointment.startDate >= now && appointment.startDate < limit {
            next[appointment.clientID] = min(next[appointment.clientID] ?? .distantFuture, appointment.startDate)
        }

        return clients
            .compactMap { client in next[client.id].map { (client, $0) } }
            .sorted { $0.start < $1.start }
    }
}
