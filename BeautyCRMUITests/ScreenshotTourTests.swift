//
//  ScreenshotTourTests.swift
//  BeautyCRMUITests
//
//  Обхід усіх екранів для аудиту (docs/audit/screenshots/<тема>/<NN-екран>.png).
//  Запуск — лише через скрипт аудиту на чистому симуляторі:
//    1) test01_RegisterMaster — реєструє вигаданого майстра через UI;
//    2) AuditDemoDataSeeder (unit) — дописує демо-дані;
//    3) test02…test04 — по одній темі на тест.
//  Без змінної AUDIT_SHOTS тести пропускаються й нічого не роблять.
//
//  Елементи шукаються за англійськими текстами (мова додатку за замовчуванням),
//  бо accessibilityIdentifier у коді додатку немає.
//

import XCTest

final class ScreenshotTourTests: XCTestCase {

    private let email = "demo.master@example.com"
    private let password = "demo-pass-2026"

    private var app: XCUIApplication!
    private var outputDir: URL!
    private var themeFolder = "classic"


    override func setUpWithError() throws {
        let path = ProcessInfo.processInfo.environment["AUDIT_SHOTS"]
        try XCTSkipIf(path == nil, "Скріншоти аудиту знімаються лише скриптом аудиту")

        outputDir = URL(fileURLWithPath: path!)
        continueAfterFailure = true

        app = XCUIApplication()
        app.launch()
    }


    // MARK: - TESTS

    func test01_RegisterMaster() {
        let createAccount = app.buttons["Create Account"]
        guard createAccount.waitForExistence(timeout: 6) else {
            return // уже зареєстровано і ввійшли
        }

        createAccount.tap()
        fillSignUpSteps(email: email, shoot: false)

        app.buttons["Create account"].tap()
        sleep(1)
        dismissSystemPrompts()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 6))
    }

    func test02_TourClassic() {
        tour(theme: "Classic", folder: "classic")
    }

    func test03_TourGraphite() {
        tour(theme: "Graphite", folder: "graphite")
    }

    func test04_TourPearlIvory() {
        tour(theme: "Pearl Ivory", folder: "pearl-ivory")
    }


    // MARK: - TOUR

    private func tour(theme: String, folder: String) {
        // Додатковий прогін у темному режимі iPhone пише в «<тема>-dark»
        themeFolder = folder + (ProcessInfo.processInfo.environment["AUDIT_SUFFIX"] ?? "")
        ensureLoggedIn()

        // Тема
        tab("Settings")
        button(containing: "Appearance").tap()
        button(containing: theme).tap()
        shot("24-settings-theme")
        back()

        // Головна
        tab("Home")
        shot("08-home")

        // Клієнти
        tab("Clients")
        shot("09-clients")

        app.staticTexts["Olivia Hart"].firstMatch.tap()
        shot("10-client-profile")
        app.swipeUp()
        shot("10b-client-profile-photos")
        app.navigationBars.buttons.element(boundBy: app.navigationBars.buttons.count - 1).tap()
        shot("12-client-edit")
        dismissSheet()
        back()

        floatingPlus().tap()
        shot("11-client-new")
        dismissSheet()

        // Календар
        tab("Calendar")
        shot("13-calendar")

        if let row = firstAppointmentRow() {
            row.tap()
            shot("14-calendar-appointment-expanded")

            if app.buttons["Complete"].waitForExistence(timeout: 2) {
                app.buttons["Complete"].tap()
                shot("16-appointment-complete")
                dismissSheet()
            }
            if app.buttons["Edit"].waitForExistence(timeout: 2) {
                app.buttons["Edit"].tap()
                shot("15b-appointment-edit")
                dismissSheet()
            }
        }

        app.swipeUp()
        shot("13b-calendar-week-collapsed")

        floatingPlus().tap()
        shot("15-appointment-new")
        button(containing: "Add services").tap()
        shot("15c-service-picker")
        dismissSheet()
        dismissSheet()

        // Головна → швидкі дії
        tab("Home")
        button(containing: "Services").tap()
        shot("17-services")
        floatingPlus().tap()
        shot("18-service-new")
        dismissSheet()
        back()

        button(containing: "Day Off").tap()
        shot("23-day-off")
        back()

        // Аналітика
        tab("Analytics")
        app.buttons["Week"].tap()
        shot("19-analytics-week")
        app.buttons["Month"].tap()
        shot("20-analytics-month")
        app.buttons["Year"].tap()
        shot("21-analytics-year")

        // Налаштування
        tab("Settings")
        shot("22-settings")

        button(containing: "Language").tap()
        shot("25-settings-language")
        back()

        button(containing: "Specialization").tap()
        shot("26-settings-profession")
        back()

        button(containing: "Working hours").tap()
        shot("27-settings-working-hours")
        back()

        // Вихід → екрани без входу
        button(containing: "Log Out").tap()
        XCTAssertTrue(app.buttons["Create Account"].waitForExistence(timeout: 5))
        shot("01-welcome")

        app.buttons["Create Account"].tap()
        fillSignUpSteps(email: "preview.\(folder)@example.com", shoot: true)
        for _ in 0..<SignUpStepCount.value {
            app.buttons["Back"].tap()
        }

        app.buttons["I already have an account"].tap()
        shot("02-login")
        login()
    }


    // MARK: - SIGN UP

    private enum SignUpStepCount {
        static let value = 5
    }

    // Проходить кроки реєстрації до останнього (валюта), не створюючи акаунт
    private func fillSignUpSteps(email: String, shoot: Bool) {
        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        enter(email, into: emailField)
        let passwordField = app.secureTextFields["Password"]
        enter(password, into: passwordField)
        hideKeyboard()
        if shoot { shot("03-signup-1-account") }
        app.buttons["Next"].tap()
        sleep(1)
        dismissSystemPrompts()

        let first = app.textFields["First name"]
        XCTAssertTrue(first.waitForExistence(timeout: 3))
        enter("Demo", into: first)
        let last = app.textFields["Last name"]
        enter("Master", into: last)
        hideKeyboard()
        if shoot { shot("04-signup-2-profile") }
        app.buttons["Next"].tap()

        button(containing: "Hair stylist").tap()
        if shoot { shot("05-signup-3-profession") }
        app.buttons["Next"].tap()

        let business = app.textFields.firstMatch
        XCTAssertTrue(business.waitForExistence(timeout: 3))
        enter("Demo Studio", into: business)
        hideKeyboard()
        if shoot { shot("06-signup-4-business") }
        app.buttons["Next"].tap()

        XCTAssertTrue(app.staticTexts["Choose currency"].waitForExistence(timeout: 3))
        if shoot { shot("07-signup-5-currency") }
    }

    private func ensureLoggedIn() {
        if app.tabBars.firstMatch.waitForExistence(timeout: 6) {
            return
        }
        if app.buttons["I already have an account"].exists {
            app.buttons["I already have an account"].tap()
        }
        login()
    }

    private func login() {
        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        enter(email, into: emailField)
        let passwordField = app.secureTextFields["Password"]
        enter(password, into: passwordField)
        hideKeyboard()
        app.buttons["Log In"].tap()
        sleep(1)
        dismissSystemPrompts()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 6))
    }


    // MARK: - HELPERS

    private func tab(_ title: String) {
        app.tabBars.buttons[title].tap()
    }

    private func button(containing text: String) -> XCUIElement {
        let element = app.buttons
            .matching(NSPredicate(format: "label CONTAINS[c] %@", text))
            .firstMatch
        XCTAssertTrue(element.waitForExistence(timeout: 4), "Немає кнопки «\(text)»")
        return element
    }

    // Круглі кнопки «+» внизу праворуч (SF Symbol plus → label «Add»)
    private func floatingPlus() -> XCUIElement {
        let element = app.buttons.matching(identifier: "Add").allElementsBoundByIndex.last
            ?? app.buttons["Add"]
        XCTAssertTrue(element.waitForExistence(timeout: 4), "Немає кнопки «+»")
        return element
    }

    private func firstAppointmentRow() -> XCUIElement? {
        for name in ["Nora Petrenko", "Ivy Lindholm", "Olivia Hart"] {
            let text = app.staticTexts[name].firstMatch
            if text.waitForExistence(timeout: 1) {
                return text
            }
        }
        return nil
    }

    private func back() {
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        if backButton.waitForExistence(timeout: 2) {
            backButton.tap()
        }
    }

    // Потягнути аркуш (sheet) донизу
    private func dismissSheet() {
        hideKeyboard()
        let window = app.windows.firstMatch
        let top = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.12))
        let bottom = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.98))
        top.press(forDuration: 0.1, thenDragTo: bottom)
        sleep(1)
    }

    private func hideKeyboard() {
        guard app.keyboards.firstMatch.exists else {
            return
        }
        app.windows.firstMatch
            .coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08))
            .tap()
    }

    private func shot(_ name: String) {
        sleep(1) // дочекатися анімацій
        let folder = outputDir.appendingPathComponent(themeFolder)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let png = XCUIScreen.main.screenshot().pngRepresentation
        do {
            try png.write(to: folder.appendingPathComponent("\(name).png"))
        } catch {
            // Якщо раннер не може писати на диск Mac — лишаємо вкладенням у .xcresult
            let attachment = XCTAttachment(data: png, uniformTypeIdentifier: "public.png")
            attachment.name = "\(themeFolder)/\(name)"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
}


// MARK: - TEXT INPUT

private extension ScreenshotTourTests {

    // Дотик + очікування фокуса: одразу після переходу екрана поле ще «не готове»
    func enter(_ text: String, into field: XCUIElement) {
        XCTAssertTrue(field.waitForExistence(timeout: 4))
        dismissSystemPrompts()
        if !field.isHittable {
            shot("debug-not-hittable")
        }
        for _ in 0..<5 {
            field.tap()
            if (field.value(forKey: "hasKeyboardFocus") as? Bool) == true {
                break
            }
            usleep(400_000)
        }
        field.typeText(text)
    }
}


// MARK: - SYSTEM PROMPTS

private extension ScreenshotTourTests {

    // Системні пропозиції iOS (зберегти пароль, надійний пароль) перекривають поля
    func dismissSystemPrompts() {
        // Назви кнопок мовою системи симулятора (тут українська) і англійською
        for title in ["Не зараз", "Not Now", "Not now"] {
            let button = app.buttons[title]
            if button.waitForExistence(timeout: 1) {
                button.tap()
                return
            }
        }
    }
}
