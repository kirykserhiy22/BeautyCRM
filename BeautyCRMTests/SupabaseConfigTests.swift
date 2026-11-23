//
//  SupabaseConfigTests.swift
//  BeautyCRMTests
//
//  Ключі сервера: беремо лише справжню адресу Supabase і лише публічний ключ.
//

import XCTest
@testable import BeautyCRM

final class SupabaseConfigTests: XCTestCase {

    private func info(_ url: String, _ key: String) -> [String: Any] {
        [SupabaseConfig.urlInfoKey: url, SupabaseConfig.keyInfoKey: key]
    }

    private func jwt(role: String) -> String {
        let payload = try! JSONSerialization.data(withJSONObject: ["role": role])
            .base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
        return "eyJhbGciOiJIUzI1NiJ9.\(payload).signature"
    }

    func testValidPublishableKey() {
        let config = SupabaseConfig.load(from: info("https://abcdefghijklmnopqrst.supabase.co", "sb_publishable_abc123"))
        XCTAssertEqual(config?.url.host, "abcdefghijklmnopqrst.supabase.co")
        XCTAssertEqual(config?.publishableKey, "sb_publishable_abc123")
    }

    // Немає файлу секретів: Xcode лишає $(…) або порожньо — сервер вимкнений
    func testMissingOrTemplateValuesDisableServer() {
        XCTAssertNil(SupabaseConfig.load(from: nil))
        XCTAssertNil(SupabaseConfig.load(from: info("$(SUPABASE_URL)", "$(SUPABASE_ANON_KEY)")))
        XCTAssertNil(SupabaseConfig.load(from: info("", "")))
        XCTAssertNil(SupabaseConfig.load(from: info("https://your-project.supabase.co", "your-anon-key")))
    }

    func testRejectsWrongHostAndHttp() {
        XCTAssertNil(SupabaseConfig.load(from: info("http://abcdefghijklmnopqrst.supabase.co", "sb_publishable_x")))
        XCTAssertNil(SupabaseConfig.load(from: info("https://example.com", "sb_publishable_x")))
    }

    // Секретний ключ у додатку — небезпечно, відмовляємось
    func testRejectsSecretKeys() {
        XCTAssertFalse(SupabaseConfig.isPublicKey("sb_secret_abc"))
        XCTAssertFalse(SupabaseConfig.isPublicKey(jwt(role: "service_role")))
        XCTAssertTrue(SupabaseConfig.isPublicKey(jwt(role: "anon")))
    }
}
