//
//  ClientMessageTests.swift
//  BeautyCRMTests
//
//  Нагадування клієнту: текст за шаблоном і посилання на месенджери.
//

import XCTest
@testable import BeautyCRM

final class ClientMessageTests: XCTestCase {

    private let template = "Доброго дня, {name}! Ваш запис {date} о {time}: {services}.\nАдреса: {address}\nДо зустрічі!"

    private let values: ClientMessageTemplate.Values = [
        .name: "Олена", .date: "14 листопада", .time: "14:00",
        .services: "Манікюр, покриття", .price: "45 €", .address: "вул. Шевченка 12"
    ]

    func testRenderFillsValuesAndSignature() {
        let text = ClientMessageTemplate.render(template: template, values: values, signature: "Марія")

        XCTAssertEqual(text, "Доброго дня, Олена! Ваш запис 14 листопада о 14:00: Манікюр, покриття.\nАдреса: вул. Шевченка 12\nДо зустрічі!\n— Марія")
    }

    func testLineWithEmptyValueIsSkipped() {
        var noAddress = values
        noAddress[.address] = "  "

        let text = ClientMessageTemplate.render(template: template, values: noAddress, signature: nil)

        XCTAssertFalse(text.contains("Адреса"), "Без адреси рядок «Адреса:» не лишається")
        XCTAssertTrue(text.hasSuffix("До зустрічі!"), "Порожній підпис не додається")
    }

    func testTokensLocalizeForEditorAndBack() {
        let titles: [ClientMessageToken: String] = [.name: "ім'я", .date: "дата", .time: "час", .services: "послуги", .price: "ціна", .address: "адреса"]
        let title: (ClientMessageToken) -> String = { titles[$0]! }

        let shown = ClientMessageTemplate.localized(template, title: title)
        XCTAssertTrue(shown.contains("{ім'я}"))
        XCTAssertFalse(shown.contains("{name}"))

        XCTAssertEqual(ClientMessageTemplate.neutral(shown, title: title), template)
    }

    func testWhatsAppAndSMSCarryTextToThePhone() {
        let contact = ClientMessageChannel.Contact(phone: "+49 151 234-56-78")

        let whatsapp = ClientMessageChannel.whatsapp.link(text: "Привіт & до зустрічі", contact: contact)
        XCTAssertEqual(whatsapp?.url.absoluteString.hasPrefix("https://wa.me/491512345678?text="), true)
        XCTAssertFalse(whatsapp!.url.absoluteString.contains("&"), "«&» у тексті закодовано")
        XCTAssertEqual(whatsapp?.needsPaste, false)

        let sms = ClientMessageChannel.sms.link(text: "Hi", contact: contact)
        XCTAssertEqual(sms?.url.absoluteString, "sms:+491512345678&body=Hi")
    }

    func testTelegramAndViberOpenChatAndAskToPaste() {
        let contact = ClientMessageChannel.Contact(phone: "+380 67 123 45 67", telegram: "@olena_k")

        let telegram = ClientMessageChannel.telegram.link(text: "Hi", contact: contact)
        XCTAssertEqual(telegram?.url.absoluteString, "https://t.me/olena_k")
        XCTAssertEqual(telegram?.needsPaste, true)

        let viber = ClientMessageChannel.viber.link(text: "Hi", contact: contact)
        XCTAssertEqual(viber?.url.absoluteString, "viber://chat?number=%2B380671234567")
        XCTAssertEqual(viber?.needsPaste, true)
    }

    func testWithoutContactMessengerOffersToPickChat() {
        let none = ClientMessageChannel.Contact()

        XCTAssertEqual(ClientMessageChannel.telegram.link(text: "Hi", contact: none)?.url.absoluteString, "tg://msg?text=Hi")
        XCTAssertEqual(ClientMessageChannel.viber.link(text: "Hi", contact: none)?.url.absoluteString, "viber://forward?text=Hi")
        XCTAssertEqual(ClientMessageChannel.whatsapp.link(text: "Hi", contact: none)?.url.absoluteString, "https://wa.me/?text=Hi")
    }

    func testEncodingKeepsOnlySafeCharacters() {
        XCTAssertEqual(ClientMessageChannel.encode("a b\n+"), "a%20b%0A%2B")
        XCTAssertEqual(ClientMessageChannel.encode("Олена").removingPercentEncoding, "Олена")
    }
}
