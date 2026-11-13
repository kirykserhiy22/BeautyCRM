//
//  ClientMessage.swift
//  BeautyCRM
//
//  Нагадування клієнту одним тапом: текст за шаблоном майстра
//  і посилання, що відкриває Telegram, Viber, WhatsApp чи SMS з готовим текстом.
//
//  У шаблоні вставки зберігаються незалежно від мови: {name}, {date}… —
//  а майстер у редакторі бачить їх своєю мовою: {ім'я}, {дата}…
//

import Foundation


// MARK: - TEMPLATE

nonisolated enum ClientMessageToken: String, CaseIterable, Identifiable {

    case name
    case date
    case time
    case services
    case price
    case address

    var id: String { rawValue }

    // Як вставка зберігається в шаблоні
    var placeholder: String { "{\(rawValue)}" }

    // Назва вставки мовою майстра: «ім'я»
    var titleKey: String { "clientMessage.token.\(rawValue)" }
}

nonisolated enum ClientMessageTemplate {

    // Значення вставок для конкретного запису
    typealias Values = [ClientMessageToken: String]

    // Готовий текст. Рядок, у якому вставка вийшла порожньою (немає адреси),
    // пропускається — щоб не лишалось «Адреса: ».
    static func render(template: String, values: Values, signature: String?) -> String {

        var lines: [String] = []

        for line in template.components(separatedBy: "\n") {

            let used = ClientMessageToken.allCases.filter { line.contains($0.placeholder) }

            if used.contains(where: { (values[$0] ?? "").trimmingCharacters(in: .whitespaces).isEmpty }) {
                continue
            }

            var result = line
            for token in used {
                result = result.replacingOccurrences(of: token.placeholder, with: values[token] ?? "")
            }
            lines.append(result)
        }

        if let signature = signature?.trimmingCharacters(in: .whitespacesAndNewlines), !signature.isEmpty {
            lines.append("— \(signature)")
        }

        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // {name} → {ім'я}: так шаблон показується в редакторі
    static func localized(_ template: String, title: (ClientMessageToken) -> String) -> String {
        ClientMessageToken.allCases.reduce(template) {
            $0.replacingOccurrences(of: $1.placeholder, with: "{\(title($1))}")
        }
    }

    // {ім'я} → {name}: так шаблон зберігається
    static func neutral(_ template: String, title: (ClientMessageToken) -> String) -> String {
        ClientMessageToken.allCases.reduce(template) {
            $0.replacingOccurrences(of: "{\(title($1))}", with: $1.placeholder)
        }
    }
}


// MARK: - CHANNELS

nonisolated enum ClientMessageChannel: String, CaseIterable, Identifiable {

    case telegram
    case viber
    case whatsapp
    case sms

    var id: String { rawValue }

    var title: String {
        switch self {
        case .telegram: return "Telegram"
        case .viber: return "Viber"
        case .whatsapp: return "WhatsApp"
        case .sms: return "SMS"
        }
    }

    // Контакти клієнта, потрібні для каналу
    struct Contact: Equatable {
        var phone: String?
        var telegram: String?
        var viber: String?
        var whatsapp: String?
    }

    struct Link: Equatable {
        let url: URL
        // Telegram і Viber не вміють відкрити чат конкретної людини з готовим текстом:
        // текст копіюється, і майстер вставляє його в чаті
        let needsPaste: Bool
    }

    func link(text: String, contact: Contact) -> Link? {

        let body = Self.encode(text)

        switch self {

        case .whatsapp:
            if let digits = Self.digits(contact.whatsapp ?? contact.phone) {
                return Link(url: URL(string: "https://wa.me/\(digits)?text=\(body)")!, needsPaste: false)
            }
            return URL(string: "https://wa.me/?text=\(body)").map { Link(url: $0, needsPaste: false) }

        case .telegram:
            if let nick = contact.telegram, let chat = ContactLinks.telegram(nick) {
                return Link(url: chat, needsPaste: true)
            }
            if let digits = Self.digits(contact.phone) {
                return URL(string: "https://t.me/+\(digits)").map { Link(url: $0, needsPaste: true) }
            }
            // Без контакту — Telegram сам запропонує вибрати чат
            return URL(string: "tg://msg?text=\(body)").map { Link(url: $0, needsPaste: false) }

        case .viber:
            if let digits = Self.digits(contact.viber ?? contact.phone) {
                return URL(string: "viber://chat?number=%2B\(digits)").map { Link(url: $0, needsPaste: true) }
            }
            return URL(string: "viber://forward?text=\(body)").map { Link(url: $0, needsPaste: false) }

        case .sms:
            let to = Self.digits(contact.phone).map { "+\($0)" } ?? ""
            return URL(string: "sms:\(to)&body=\(body)").map { Link(url: $0, needsPaste: false) }
        }
    }

    // Цифри номера; nil, якщо номер закороткий
    private static func digits(_ text: String?) -> String? {
        let digits = (text ?? "").filter { $0.isASCII && $0.isNumber }
        return digits.count >= 7 ? digits : nil
    }

    // Текст у посиланні: кодується все, крім літер, цифр і «-._~»
    static func encode(_ text: String) -> String {
        var allowed = CharacterSet.alphanumerics.intersection(CharacterSet(charactersIn: Unicode.Scalar(0)..<Unicode.Scalar(128)))
        allowed.insert(charactersIn: "-._~")
        return text.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
    }
}
