//
//  BrandThemeTests.swift
//  BeautyCRMTests
//
//  Фірмова тема Dark Cherry: тема за замовчуванням, світлий і темний варіанти.
//

import XCTest
import SwiftUI
@testable import BeautyCRM

final class BrandThemeTests: XCTestCase {

    private func hex(_ color: Color, _ style: UIUserInterfaceStyle) -> UInt32 {
        let resolved = UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
        var (r, g, b, a): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
        return UInt32((r * 255).rounded()) << 16 | UInt32((g * 255).rounded()) << 8 | UInt32((b * 255).rounded())
    }

    func testBrandThemeIsDefaultAndFollowsSystem() {
        let manager = ThemeManager()
        XCTAssertEqual(manager.currentTheme, .darkCherry)
        XCTAssertEqual(manager.appearance, .system)
        XCTAssertNil(AppearanceMode.system.colorScheme, "Як в iPhone — iOS вирішує сам")
        XCTAssertEqual(AppearanceMode.light.colorScheme, .light)
        XCTAssertEqual(AppearanceMode.dark.colorScheme, .dark)
    }

    func testRemovedOldThemeFallsBackToBrandTheme() {
        let key = "app_theme"
        let saved = UserDefaults.standard.string(forKey: key)
        defer { UserDefaults.standard.set(saved, forKey: key) }

        UserDefaults.standard.set("graphite", forKey: key)

        XCTAssertEqual(ThemeStorage().load(), .darkCherry)
    }

    func testBrandColorsChangeWithAppearance() {
        let colors = ThemeManager().colors(for: .darkCherry)

        XCTAssertEqual(hex(colors.background, .dark), 0x2A0814)
        XCTAssertEqual(hex(colors.background, .light), 0xF7EFF2)
        XCTAssertEqual(hex(colors.card, .dark), 0x4A0E24)
        XCTAssertEqual(hex(colors.card, .light), 0xFFFFFF)

        // Кнопка однакова в обох варіантах
        XCTAssertEqual(hex(colors.buttonPrimary, .dark), 0xE20942)
        XCTAssertEqual(hex(colors.buttonPrimary, .light), 0xE20942)
    }


    // MARK: - Splash

    func testNeonSplashUnlessReduceMotion() {
        XCTAssertEqual(SplashPlan.choose(reduceMotion: false), .neon)
        XCTAssertEqual(SplashPlan.choose(reduceMotion: true), .still)
    }
}
