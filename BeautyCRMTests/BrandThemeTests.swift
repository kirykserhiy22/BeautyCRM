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
        XCTAssertEqual(ThemeManager().currentTheme, .darkCherry)
        XCTAssertTrue(AppTheme.darkCherry.followsSystemAppearance)
        XCTAssertFalse(AppTheme.classic.followsSystemAppearance)
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
}
