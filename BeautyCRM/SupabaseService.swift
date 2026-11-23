//
//  SupabaseService.swift
//  BeautyCRM
//
//  Єдиний клієнт Supabase для всього додатка (бібліотека supabase-swift).
//  Поки що (крок S2) лише створюється і перевіряє зв'язок; вхід і синхронізація — у наступних кроках.
//  Сесію входу бібліотека сама зберігає в Keychain.
//
//  Якщо ключів немає (Config/Secrets.xcconfig не заповнено) — client == nil,
//  додаток працює як раніше, лише на телефоні.
//

import Foundation
import Supabase

enum SupabaseService {

    static let client: SupabaseClient? = SupabaseConfig.current.map {
        SupabaseClient(supabaseURL: $0.url, supabaseKey: $0.publishableKey)
    }

    static var isConfigured: Bool {
        client != nil
    }

    // Чи відповідає сервер: службова адреса Supabase Auth, без даних користувачів
    nonisolated static func isReachable(_ config: SupabaseConfig, session: URLSession = .shared) async -> Bool {
        var request = URLRequest(url: config.url.appending(path: "auth/v1/health"))
        request.setValue(config.publishableKey, forHTTPHeaderField: "apikey")
        request.timeoutInterval = 10
        guard let (_, response) = try? await session.data(for: request) else {
            return false
        }
        return (response as? HTTPURLResponse)?.statusCode == 200
    }

    #if DEBUG
    // Під час розробки: один рядок у консолі Xcode, чи є зв'язок із сервером (без особистих даних)
    static func logConnection() {
        guard let config = SupabaseConfig.current else {
            print("Supabase: ключів немає — працюємо лише на телефоні")
            return
        }
        Task.detached {
            let ok = await isReachable(config)
            print(ok ? "Supabase: зв'язок є" : "Supabase: сервер не відповідає")
        }
    }
    #endif
}
