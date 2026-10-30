//
//  SaveErrorReporter.swift
//  BeautyCRM
//

import UIKit
import SwiftData


extension ModelContext {

    // Зберігає зміни. Якщо не вдалося — майстер бачить повідомлення,
    // а не думає, що все збережено. Повертає true, коли збережено.
    @discardableResult
    func saveReportingErrors() -> Bool {

        guard hasChanges else {
            return true
        }

        do {
            try save()
            return true
        } catch {
            SaveErrorReporter.report(error)
            return false
        }
    }
}


enum SaveErrorReporter {

    // Що робити з помилкою. За замовчуванням — показати вікно;
    // у тестах можна підмінити.
    static var handler: (Error) -> Void = { _ in
        presentAlert()
    }

    static func report(_ error: Error) {
        handler(error)
    }


    // MARK: - ALERT

    // Вікно показується поверх усього, що зараз відкрито (і поверх аркушів-sheet),
    // тому його не треба додавати в кожен екран окремо
    private static func presentAlert() {

        let localization = LocalizationManager()

        let alert = UIAlertController(
            title: localization.localizedString(for: "error.save.title"),
            message: localization.localizedString(for: "error.save.message"),
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(
                title: localization.localizedString(for: "common.ok"),
                style: .default
            )
        )

        topViewController()?.present(alert, animated: true)
    }

    private static func topViewController() -> UIViewController? {

        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }

        var top = window?.rootViewController

        while let presented = top?.presentedViewController {
            top = presented
        }

        return top
    }
}
