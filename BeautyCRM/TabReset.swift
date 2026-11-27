//
//  TabReset.swift
//  BeautyCRM
//
//  Повернення на вкладку відкриває її з головного екрана, а не з форми, яку покинули.
//  Виняток — форма, у якій уже щось введено: її не скидаємо, щоб не втратити введене.
//

import SwiftUI


// Які вкладки мають відкриту форму з незбереженим
@MainActor
final class UnsavedForms {

    static let shared = UnsavedForms()

    private var forms: [UUID: String] = [:]

    func set(_ form: UUID, tab: String?, hasChanges: Bool) {
        if hasChanges, let tab {
            forms[form] = tab
        } else {
            forms[form] = nil
        }
    }

    func hasUnsaved(in tab: String) -> Bool {
        forms.values.contains(tab)
    }
}


private struct FormTabKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

extension EnvironmentValues {
    // У якій вкладці відкрито екран (ставить MainTabView)
    var formTab: String? {
        get { self[FormTabKey.self] }
        set { self[FormTabKey.self] = newValue }
    }
}


// Форма повідомляє вкладці, чи є в ній незбережене
struct ReportsUnsavedChanges: ViewModifier {

    let hasChanges: Bool

    @Environment(\.formTab) private var tab
    @State private var id = UUID()

    func body(content: Content) -> some View {
        content
            .onChange(of: hasChanges, initial: true) { _, value in
                UnsavedForms.shared.set(id, tab: tab, hasChanges: value)
            }
            .onDisappear {
                UnsavedForms.shared.set(id, tab: tab, hasChanges: false)
            }
    }
}
