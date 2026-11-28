//
//  ContactImport.swift
//  BeautyCRM
//
//  Клієнтки з контактів телефону: системний вибір контактів (без доступу до всієї телефонної
//  книги — додаток бачить лише тих, кого вибрали) і створення клієнток. Дублікати пропускаються.
//

import SwiftUI
import SwiftData
import ContactsUI


// Ім'я й телефон з контакту
struct ImportedContact: Equatable {
    let name: String
    let phone: String?
}


nonisolated enum ContactImport {

    static func imported(from contact: CNContact) -> ImportedContact? {
        let name = [contact.givenName, contact.familyName]
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        let fallback = contact.organizationName.trimmingCharacters(in: .whitespaces)
        let finalName = name.isEmpty ? fallback : name
        guard !finalName.isEmpty else { return nil }
        let phone = contact.phoneNumbers.first?.value.stringValue
        return ImportedContact(name: finalName, phone: phone)
    }

    // Створює клієнток; повертає, скільки нових (дублікати за ім'ям і телефоном пропущено)
    @MainActor @discardableResult
    static func create(_ contacts: [ImportedContact], userID: String, context: ModelContext) -> Int {
        var created = 0
        for contact in contacts {
            let duplicate = try? ClientManager.possibleDuplicate(
                name: contact.name, phone: contact.phone, instagram: nil, telegram: nil,
                userID: userID, context: context
            )
            guard duplicate == nil else { continue }
            context.insert(Client(userID: userID, name: contact.name, phone: contact.phone))
            created += 1
        }
        if created > 0 {
            context.saveReportingErrors()
        }
        return created
    }
}


// Системний екран вибору кількох контактів. Показується поверх поточного екрана напряму:
// вкладений у sheet SwiftUI він буває порожнім
@MainActor
final class ContactPickerPresenter: NSObject, CNContactPickerDelegate {

    static let shared = ContactPickerPresenter()

    private var onPick: (([ImportedContact]) -> Void)?

    func present(onPick: @escaping ([ImportedContact]) -> Void) {
        self.onPick = onPick
        // Меню, з якого натиснули, ще закривається — показуємо, коли воно зникне
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            guard let top = Self.topViewController() else { return }
            let picker = CNContactPickerViewController()
            picker.delegate = self
            picker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
            top.present(picker, animated: true)
        }
    }

    // Реалізація цього методу вмикає вибір кількох контактів
    nonisolated func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
        let picked = contacts.compactMap(ContactImport.imported(from:))
        Task { @MainActor in
            self.onPick?(picked)
            self.onPick = nil
        }
    }

    nonisolated func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        Task { @MainActor in self.onPick = nil }
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        var top = scene?.windows.first { $0.isKeyWindow }?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}
