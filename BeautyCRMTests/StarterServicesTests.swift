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

@MainActor
final class ContactImportTests: XCTestCase {

    func testCreatesClientsAndSkipsDuplicates() throws {
        let container = try ModelContainer(for: Client.self, ClientPhoto.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        context.insert(Client(userID: "u", name: "Олена Коваль", phone: "+380671234501"))
        try context.save()

        let created = ContactImport.create([
            ImportedContact(name: "Олена Коваль", phone: "+380 67 123 45 01"),
            ImportedContact(name: "Марина Шевчук", phone: "+380 50 123 45 02"),
            ImportedContact(name: "Ірина", phone: nil)
        ], userID: "u", context: context)

        XCTAssertEqual(created, 2, "Олена вже є")
        XCTAssertEqual(try context.fetch(FetchDescriptor<Client>()).count, 3)
    }
}
