import XCTest
import SwiftData
@testable import BeautyCRM

@MainActor
final class StarterServicesTests: XCTestCase {

    func testCreatesProfessionServicesOnceWithoutPrice() throws {
        let container = try ModelContainer(for: Service.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)

        let created = StarterServices.createIfNeeded(userID: "u", profession: .nailArtist, context: context, localized: { $0 })
        XCTAssertEqual(created, Profession.nailArtist.config.suggestedServiceKeys.count)

        let services = try context.fetch(FetchDescriptor<Service>())
        XCTAssertTrue(services.allSatisfy { $0.pricingType == .variable && $0.price == nil && $0.userID == "u" })

        XCTAssertEqual(StarterServices.createIfNeeded(userID: "u", profession: .nailArtist, context: context, localized: { $0 }), 0, "Вдруге не дублює")
        XCTAssertEqual(StarterServices.createIfNeeded(userID: "u2", profession: nil, context: context, localized: { $0 }), 0)
    }
}
