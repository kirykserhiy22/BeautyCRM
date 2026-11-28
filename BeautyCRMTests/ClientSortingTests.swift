import XCTest
@testable import BeautyCRM

@MainActor
final class ClientSortingTests: XCTestCase {

    private typealias F = AuditFixtures

    private func client(_ name: String, added: Date) -> Client {
        let c = Client(userID: F.userID, name: name)
        c.createdAt = added
        return c
    }

    private func visit(_ client: Client, _ date: Date, status: AppointmentStatus = .completed) -> Appointment {
        let a = Appointment(userID: F.userID, clientID: client.id, clientName: client.name, startDate: date, duration: 60)
        a.status = status
        return a
    }

    func testSorts() {
        let anna = client("Анна", added: F.date(2026, 1, 1, 10))
        let olena = client("олена", added: F.date(2026, 3, 1, 10))
        let iryna = client("Ірина", added: F.date(2026, 5, 1, 10))
        let nova = client("Яна", added: F.date(2026, 11, 1, 10))   // без візитів
        let all = [olena, nova, anna, iryna]

        let visits = ClientSorting.lastVisits([
            visit(anna, F.date(2026, 10, 1, 10)),
            visit(olena, F.date(2026, 11, 20, 10)),
            visit(iryna, F.date(2026, 6, 1, 10)),
            visit(iryna, F.date(2026, 11, 25, 10), status: .cancelled)   // не рахується
        ])
        let uk = Locale(identifier: "uk")

        func names(_ sort: ClientSort) -> [String] {
            ClientSorting.sorted(all, by: sort, lastVisits: visits, locale: uk).map(\.name)
        }

        XCTAssertEqual(names(.nameAscending), ["Анна", "Ірина", "олена", "Яна"])
        XCTAssertEqual(names(.nameDescending), ["Яна", "олена", "Ірина", "Анна"])
        XCTAssertEqual(names(.recentVisit), ["олена", "Анна", "Ірина", "Яна"])
        XCTAssertEqual(names(.oldestVisit), ["Ірина", "Анна", "олена", "Яна"], "Без візитів — у кінці")
        XCTAssertEqual(names(.noVisits).first, "Яна")
        XCTAssertEqual(names(.recentlyAdded), ["Яна", "Ірина", "олена", "Анна"])
    }

    func testUpcomingWithinWeekNearestFirst() {
        let now = F.date(2026, 11, 28, 12)
        let a = client("A", added: now), b = client("B", added: now), c = client("C", added: now), d = client("D", added: now)
        let list = ClientSorting.upcoming([a, b, c, d], appointments: [
            visit(a, F.date(2026, 12, 2, 10), status: .active),
            visit(b, F.date(2026, 11, 29, 10), status: .active),
            visit(b, F.date(2026, 12, 1, 10), status: .active),
            visit(c, F.date(2026, 12, 20, 10), status: .active),      // далі тижня
            visit(d, F.date(2026, 11, 29, 9), status: .cancelled)     // скасований
        ], now: now)
        XCTAssertEqual(list.map(\.client.name), ["B", "A"])
        XCTAssertEqual(list.first?.start, F.date(2026, 11, 29, 10))
    }
}
