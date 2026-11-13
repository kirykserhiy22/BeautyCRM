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
    case instagram
    case whatsapp
    case viber
    case messenger
    case sms

    var id: String { rawValue }

    var title: String {
        switch self {
        case .telegram: return "Telegram"
        case .instagram: return "Instagram"
        case .whatsapp: return "WhatsApp"
        case .viber: return "Viber"
        case .messenger: return "Messenger"
        case .sms: return "SMS"
        }
    }

    // Контакти клієнта з картки
    struct Contact: Equatable {
        var phone: String?
        var telegram: String?
        var instagram: String?
        var whatsapp: String?
        var viber: String?
        var messenger: String?
        // Код країни майстра — для номерів, записаних без «+» («067…»)
        var countryCode: String?
    }

    struct Link: Equatable {
        let url: URL
        // Застосунок не вміє вставити текст сам — текст копіюється, майстер вставляє
        let needsPaste: Bool
        // Якщо застосунку немає на телефоні — відкрити через сайт
        var fallback: URL? = nil
    }

    // Чи заповнений у клієнта саме цей контакт: такі месенджери показуємо першими
    func isFilled(in contact: Contact) -> Bool {
        switch self {
        case .telegram: return Self.filled(contact.telegram)
        case .instagram: return Self.filled(contact.instagram)
        case .whatsapp: return Self.filled(contact.whatsapp)
        case .viber: return Self.filled(contact.viber)
        case .messenger: return Self.filled(contact.messenger)
        case .sms: return Self.filled(contact.phone)
        }
    }

    // Instagram і Messenger без ніка відкрити нікуди — їх не пропонуємо
    func isOffered(for contact: Contact) -> Bool {
        switch self {
        case .instagram, .messenger: return isFilled(in: contact)
        default: return true
        }
    }

    // Спершу контакти з картки клієнта, потім решта
    static func split(for contact: Contact) -> (primary: [ClientMessageChannel], other: [ClientMessageChannel]) {
        let offered = allCases.filter { $0.isOffered(for: contact) }
        return (offered.filter { $0.isFilled(in: contact) }, offered.filter { !$0.isFilled(in: contact) })
    }

    func link(text: String, contact: Contact) -> Link? {

        let body = Self.encode(text)
        let code = contact.countryCode

        switch self {

        case .telegram:
            // Чат клієнта з уже набраним текстом (якщо Telegram старий — текст є в буфері)
            if let nick = Self.nick(contact.telegram, sites: ["t.me/", "telegram.me/"]) {
                var link = Self.make("tg://resolve?domain=\(nick)&text=\(body)", paste: true)
                link?.fallback = URL(string: "https://t.me/\(nick)?text=\(body)")
                return link
            }
            // Без ніка Telegram сам запропонує вибрати чат, текст уже вставлений
            return Self.make("tg://msg?text=\(body)", paste: false)

        case .instagram:
            guard let nick = Self.nick(contact.instagram, sites: ["instagram.com/"]) else { return nil }
            return Self.make("https://ig.me/m/\(nick)", paste: true)

        case .messenger:
            guard let nick = Self.nick(contact.messenger, sites: ["m.me/", "messenger.com/t/", "facebook.com/"]) else { return nil }
            return Self.make("https://m.me/\(nick)", paste: true)

        case .whatsapp:
            if let digits = Self.international(contact.whatsapp ?? contact.phone, countryCode: code) {
                return Self.make("https://wa.me/\(digits)?text=\(body)", paste: false)
            }
            return Self.make("https://wa.me/?text=\(body)", paste: false)

        case .viber:
            // Відкрити чат за номером Viber на iPhone дозволяє ненадійно;
            // надійно — вибір контакту з уже вставленим текстом
            return Self.make("viber://forward?text=\(body)", paste: false)

        case .sms:
            let to = Self.international(contact.phone, countryCode: code).map { "+\($0)" } ?? ""
            return Self.make("sms:\(to)&body=\(body)", paste: false)
        }
    }

    // MARK: helpers

    private static func make(_ string: String, paste: Bool) -> Link? {
        URL(string: string).map { Link(url: $0, needsPaste: paste) }
    }

    private static func filled(_ value: String?) -> Bool {
        !(value ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // Чистий нік: «@olena_k», «t.me/olena_k» → «olena_k»
    static func nick(_ text: String?, sites: [String]) -> String? {
        var value = (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        for site in sites {
            if let range = value.range(of: site, options: .caseInsensitive) {
                value = String(value[range.upperBound...])
            }
        }
        value = value.components(separatedBy: CharacterSet(charactersIn: "?#")).first ?? ""
        value = value.trimmingCharacters(in: CharacterSet(charactersIn: "@/"))
        let isValid = !value.isEmpty && value.allSatisfy {
            $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "." || $0 == "_")
        }
        return isValid ? value : nil
    }

    // Номер у міжнародному вигляді без «+»: «+49 151…» → «49151…»,
    // «067 123…» з кодом країни 380 → «38067123…»
    static func international(_ text: String?, countryCode: String?) -> String? {
        let raw = (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        var digits = raw.filter { $0.isASCII && $0.isNumber }
        guard digits.count >= 7 else {
            return nil
        }
        if raw.hasPrefix("+") {
            return digits
        }
        if digits.hasPrefix("00") {
            return String(digits.dropFirst(2))
        }
        if let code = countryCode, digits.hasPrefix("0") {
            digits.removeFirst()
            // «380» + «67…»; для країн, де код уже містить «0» на початку номера — без змін
            return code + digits
        }
        // Польща й Чехія: номер з 9 цифр без «0» на початку
        if let code = countryCode, ["48", "420"].contains(code), digits.count == 9 {
            return code + digits
        }
        return digits
    }

    // Код країни за регіоном телефону майстра
    static func countryCode(region: String?) -> String? {
        switch region {
        case "UA": return "380"
        case "DE": return "49"
        case "AT": return "43"
        case "PL": return "48"
        case "CZ": return "420"
        case "GB": return "44"
        default: return nil
        }
    }

    // Текст у посиланні: кодується все, крім латинських літер, цифр і «-._~»
    static func encode(_ text: String) -> String {
        var allowed = CharacterSet.alphanumerics.intersection(CharacterSet(charactersIn: Unicode.Scalar(0)..<Unicode.Scalar(128)))
        allowed.insert(charactersIn: "-._~")
        return text.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
    }
}
