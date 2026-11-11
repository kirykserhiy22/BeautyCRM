//
//  AppFlowUITests.swift
//  BeautyCRMUITests
//
//  Головний шлях користувача: реєстрація → вихід → вхід → порожній список клієнтів.
//  Елементи шукаються за accessibilityIdentifier (#63), тому тест запускається
//  українською і не ламається, коли змінюються тексти чи дизайн екранів.
//

import XCTest

final class AppFlowUITests: XCTestCase {

    private let password = "demo-pass-2026"

    private enum Tab: Int {
        case home, clients, calendar, analytics, settings
    }

    private var app: XCUIApplication!


    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        // Мова додатку на час тесту (той самий ключ, що в LocalizationManager)
        app.launchArguments += ["-app_language", "uk"]
        app.launch()
    }


    func testSignUpLogOutAndLogIn() {
        logOutIfNeeded()

        // Кожен запуск — новий акаунт: попередні лишаються в симуляторі
        let email = "flow.\(UUID().uuidString.prefix(8))@example.com"

        tap("welcome.createAccount")

        enter(email, into: app.textFields["signup.email"])
        enter(password, into: app.secureTextFields["signup.password"])
        goNext()

        enter("Demo", into: app.textFields["signup.firstName"])
        enter("Master", into: app.textFields["signup.lastName"])
        goNext()

        tap("profession.hair_stylist")
        goNext()

        goNext() // назва салону необов'язкова
        goNext() // валюта вже вибрана: кнопка створює акаунт

        dismissSystemPrompts()

        // Новий майстер один раз бачить гід по додатку
        XCTAssertTrue(app.buttons["onboarding.skip"].waitForExistence(timeout: 8), "Після реєстрації показується гід")
        app.buttons["onboarding.skip"].tap()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 8), "Після реєстрації відкрився додаток")

        // Новий майстер бачить порожній список і кнопку додавання
        open(.clients)
        XCTAssertTrue(app.buttons["floating.add"].waitForExistence(timeout: 4))

        logOut()

        tap("welcome.login")
        enter(email, into: app.textFields["login.email"])
        enter(password, into: app.secureTextFields["login.password"])
        tap("login.submit")

        dismissSystemPrompts()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 8), "Вхід із новим акаунтом працює")
        XCTAssertFalse(app.buttons["onboarding.skip"].exists, "Гід не показується вдруге")

        logOut()
    }


    // MARK: - HELPERS

    private func tap(_ identifier: String) {
        let button = app.buttons[identifier]
        XCTAssertTrue(button.waitForExistence(timeout: 5), identifier)
        button.tap()
    }

    private func goNext() {
        tap("signup.next")
        dismissSystemPrompts()
    }

    private func open(_ tab: Tab) {
        app.tabBars.buttons.element(boundBy: tab.rawValue).tap()
    }

    private func logOutIfNeeded() {
        if app.tabBars.firstMatch.waitForExistence(timeout: 5) {
            logOut()
        }
    }

    private func logOut() {
        open(.settings)

        let logOut = app.buttons["settings.logout"]
        for _ in 0..<4 where !logOut.isHittable {
            app.swipeUp()
        }
        logOut.tap()

        XCTAssertTrue(app.buttons["welcome.createAccount"].waitForExistence(timeout: 5))
    }

    // Панель «Обрати надійний пароль» стає замість клавіатури прямо під час введення
    // і забирає символи. Тому після введення звіряємо довжину і за потреби вводимо знову.
    private func enter(_ text: String, into field: XCUIElement) {
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        dismissSystemPrompts()

        for _ in 0..<4 {
            focus(field)
            closeStrongPasswordPanel()

            let typed = (field.value as? String) ?? ""
            if !typed.isEmpty, typed != field.placeholderValue {
                field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: typed.count))
            }

            for character in text {
                closeStrongPasswordPanel()
                field.typeText(String(character))
            }

            if (field.value as? String)?.count == text.count {
                return
            }
        }

        XCTFail("Текст не вдалося ввести повністю")
    }

    // Дотик + очікування фокуса: одразу після переходу екрана поле ще «не готове»
    private func focus(_ field: XCUIElement) {
        for _ in 0..<5 {
            field.tap()
            if (field.value(forKey: "hasKeyboardFocus") as? Bool) == true {
                return
            }
            usleep(400_000)
        }
    }

    private func closeStrongPasswordPanel() {
        let close = app.buttons["xmark"]
        if close.exists {
            close.tap()
            usleep(500_000)
        }
    }

    // Системні пропозиції iOS (зберегти пароль, надійний пароль) перекривають поля.
    // Їхні кнопки — мовою системи симулятора.
    private func dismissSystemPrompts() {
        for title in ["Не зараз", "Not Now", "Not now"] {
            let button = app.buttons[title]
            if button.waitForExistence(timeout: 1) {
                button.tap()
                return
            }
        }
    }
}
