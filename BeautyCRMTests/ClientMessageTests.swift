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

    func testTelegramOpensClientChatWithText() {
        let contact = ClientMessageChannel.Contact(telegram: "https://t.me/olena_k")

        let telegram = ClientMessageChannel.telegram.link(text: "Hi there", contact: contact)
        XCTAssertEqual(telegram?.url.absoluteString, "tg://resolve?domain=olena_k&text=Hi%20there")
        XCTAssertEqual(telegram?.fallback?.absoluteString, "https://t.me/olena_k?text=Hi%20there")
        XCTAssertEqual(telegram?.needsPaste, true, "Текст ще й копіюється — на випадок старого Telegram")
    }

    func testViberAndTelegramWithoutNickPickChatWithTextInside() {
        let none = ClientMessageChannel.Contact()

        XCTAssertEqual(ClientMessageChannel.viber.link(text: "Hi", contact: none)?.url.absoluteString, "viber://forward?text=Hi")
        XCTAssertEqual(ClientMessageChannel.telegram.link(text: "Hi", contact: none)?.url.absoluteString, "tg://msg?text=Hi")
        XCTAssertEqual(ClientMessageChannel.whatsapp.link(text: "Hi", contact: none)?.url.absoluteString, "https://wa.me/?text=Hi")
    }

    func testInstagramAndMessengerOpenDirectMessages() {
        let contact = ClientMessageChannel.Contact(instagram: "@olena.nails", messenger: "olena.k")

        XCTAssertEqual(ClientMessageChannel.instagram.link(text: "Hi", contact: contact)?.url.absoluteString, "https://ig.me/m/olena.nails?text=Hi")
        XCTAssertEqual(ClientMessageChannel.messenger.link(text: "Hi", contact: contact)?.url.absoluteString, "https://m.me/olena.k")
        XCTAssertNil(ClientMessageChannel.instagram.link(text: "Hi", contact: .init()), "Без ніка Instagram нікуди не відкрити")
    }

    func testClientChannelsComeFirst() {
        let contact = ClientMessageChannel.Contact(telegram: "@olena_k", instagram: "olena.nails")

        let split = ClientMessageChannel.split(for: contact)

        XCTAssertEqual(split.primary, [.telegram, .instagram])
        XCTAssertEqual(split.other, [.whatsapp, .viber, .sms], "Messenger без ніка не пропонуємо")
    }

    func testLocalNumbersGetCountryCode() {
        XCTAssertEqual(ClientMessageChannel.international("067 123 45 67", countryCode: "380"), "380671234567")
        XCTAssertEqual(ClientMessageChannel.international("0151 2345678", countryCode: "49"), "491512345678")
        XCTAssertEqual(ClientMessageChannel.international("601 234 567", countryCode: "48"), "48601234567")
        XCTAssertEqual(ClientMessageChannel.international("+380 67 123 45 67", countryCode: "49"), "380671234567", "Номер з «+» не чіпаємо")
        XCTAssertEqual(ClientMessageChannel.international("0049 151 2345678", countryCode: "380"), "491512345678")
        XCTAssertNil(ClientMessageChannel.international("12 34", countryCode: "380"))
    }

    func testEncodingKeepsOnlySafeCharacters() {
        XCTAssertEqual(ClientMessageChannel.encode("a b\n+"), "a%20b%0A%2B")
        XCTAssertEqual(ClientMessageChannel.encode("Олена").removingPercentEncoding, "Олена")
    }
}
