//
//  SupabaseConfig.swift
//  BeautyCRM
//
//  Адреса проєкту Supabase і публічний ключ.
//  Беруться з Info.plist, куди їх підставляє Xcode з Config/Secrets.xcconfig (поза git).
//  Якщо файлу секретів немає або там шаблон — сервер просто вимкнений, додаток працює як раніше.
//

import Foundation

nonisolated struct SupabaseConfig: Equatable {

    let url: URL
    let publishableKey: String

    static let urlInfoKey = "SupabaseURL"
    static let keyInfoKey = "SupabasePublishableKey"

    // Налаштування цього додатка (nil — сервер не підключено)
    static let current: SupabaseConfig? = load(from: Bundle.main.infoDictionary)

    // Чистий розбір — перевіряють тести
    static func load(from info: [String: Any]?) -> SupabaseConfig? {

        guard
            let rawURL = (info?[urlInfoKey] as? String)?.trimmingCharacters(in: .whitespaces),
            let rawKey = (info?[keyInfoKey] as? String)?.trimmingCharacters(in: .whitespaces),
            let url = URL(string: rawURL),
            url.scheme == "https",
            let host = url.host,
            host.hasSuffix(".supabase.co"),
            !host.hasPrefix("your-project"),
            isPublicKey(rawKey)
        else {
            return nil
        }

        return SupabaseConfig(url: url, publishableKey: rawKey)
    }

    // Лише публічний ключ. Секретний (sb_secret_ / service_role) у додатку бути не може —
    // з ним не працюють правила доступу, тому відмовляємось його використовувати.
    static func isPublicKey(_ key: String) -> Bool {
        if key.isEmpty || key.hasPrefix("$(") || key == "your-anon-key" || key.hasPrefix("sb_secret_") {
            return false
        }
        if key.hasPrefix("sb_publishable_") {
            return true
        }
        // Старий формат: JWT із роллю anon
        if key.hasPrefix("eyJ") {
            return jwtRole(key) == "anon"
        }
        return false
    }

    private static func jwtRole(_ token: String) -> String? {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { return nil }
        var payload = String(parts[1]).replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        while payload.count % 4 != 0 { payload += "=" }
        guard
            let data = Data(base64Encoded: payload),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }
        return json["role"] as? String
    }
}
