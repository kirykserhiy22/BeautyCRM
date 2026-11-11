//
//  ClientNetworkTests.swift
//  BeautyCRMTests
//
//  Соцмережі клієнта: посилання на WhatsApp, Viber, Messenger і поля моделі.
//

import XCTest
@testable import BeautyCRM

@MainActor
final class ClientNetworkTests: XCTestCase {

    func testWhatsAppAndViberUsePhoneDigits() {
        XCTAssertEqual(ContactLinks.whatsapp("+49 (151) 000-0101")?.absoluteString, "https://wa.me/491510000101")
        XCTAssertEqual(ContactLinks.viber("+380 67 000 01 06")?.absoluteString, "viber://chat?number=%2B380670000106")
        XCTAssertNil(ContactLinks.whatsapp("12 34"), "Закороткий номер — не посилання")
        XCTAssertNil(ContactLinks.viber("нема"))
    }

    func testMessengerAcceptsNickOrLink() {
        XCTAssertEqual(ContactLinks.messenger("@anna.demo")?.absoluteString, "https://m.me/anna.demo")
        XCTAssertEqual(ContactLinks.messenger("https://m.me/anna.demo")?.absoluteString, "https://m.me/anna.demo")
        XCTAssertEqual(ContactLinks.messenger("facebook.com/anna.demo?ref=x")?.absoluteString, "https://m.me/anna.demo")
        XCTAssertNil(ContactLinks.messenger("Анна Демо"))
    }

    func testEveryNetworkHasItsOwnField() {
        let client = Client(userID: AuditFixtures.userID, name: "Demo Client")

        for network in ContactNetwork.allCases {
            network.set("value-\(network.rawValue)", on: client)
        }

        for network in ContactNetwork.allCases {
            XCTAssertEqual(network.value(of: client), "value-\(network.rawValue)")
        }

        ContactNetwork.viber.set(nil, on: client)
        XCTAssertNil(client.viber)
        XCTAssertEqual(client.whatsapp, "value-whatsapp", "Очищення одного поля не чіпає інші")
    }
}
