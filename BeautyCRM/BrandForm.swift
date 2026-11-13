//
//  BrandForm.swift
//  BeautyCRM
//
//  Фірмове оформлення форм (новий клієнт, послуга, запис, профіль, робочі години)
//  і поле пароля з кнопкою «показати / сховати».
//

import SwiftUI


// MARK: - PASSWORD FIELD

// Пароль крапками, а кнопка з оком справа дає перевірити, що введено.
// Обидва поля весь час на екрані (видно одне): якщо прибирати поле пароля,
// iPhone вважає форму відправленою і пропонує «Зберегти пароль?».
// Ідентифікатор лишається на полі з крапками — автотести шукають його як і раніше.
struct PasswordField: View {

    let titleKey: LocalizedStringKey
    @Binding var text: String
    let colors: ThemeColors
    let identifier: String

    private enum Mode { case hidden, visible }

    @State private var isVisible = false
    @FocusState private var focus: Mode?

    var body: some View {

        HStack(spacing: 8) {

            ZStack {

                SecureField(titleKey, text: $text, prompt: prompt)
                    .focused($focus, equals: .hidden)
                    .opacity(isVisible ? 0 : 1)
                    .allowsHitTesting(!isVisible)
                    .accessibilityHidden(isVisible)
                    .accessibilityIdentifier(identifier)

                TextField(titleKey, text: $text, prompt: prompt)
                    .focused($focus, equals: .visible)
                    .opacity(isVisible ? 1 : 0)
                    .allowsHitTesting(isVisible)
                    .accessibilityHidden(!isVisible)
                    .accessibilityIdentifier("\(identifier).visible")
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            Button {
                // Курсор переходить у поле, яке стало видно
                let wasFocused = focus != nil
                isVisible.toggle()
                if wasFocused {
                    focus = isVisible ? .visible : .hidden
                }
            } label: {
                Image(systemName: isVisible ? "eye" : "eye.slash")
                    .font(.body)
                    .foregroundColor(colors.textSecondary)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(LocalizedStringKey(isVisible ? "password.hide" : "password.show")))
            .accessibilityIdentifier("\(identifier).toggle")
        }
        .authField(colors)
    }

    private var prompt: Text {
        Text(titleKey).foregroundColor(colors.textSecondary)
    }
}


// MARK: - FORM STYLE

extension View {

    // Системна форма (Form / List) на фірмовому тлі з акцентним кольором
    func brandForm(_ colors: ThemeColors) -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(colors.background)
            .tint(colors.accent)
    }

    // Рядки секції — фірмові картки замість системного сірого
    func brandRows(_ colors: ThemeColors) -> some View {
        listRowBackground(colors.card)
    }

    // Блок форми, зібраної вручну (форма запису)
    func formCard(_ colors: ThemeColors) -> some View {
        self
            .padding()
            .background(colors.card)
            .cornerRadius(14)
    }
}


// Заголовок блоку у формі запису (вона зібрана вручну, без Form)
struct FormSectionTitle: View {

    let text: String
    let colors: ThemeColors

    var body: some View {
        // Як заголовки секцій у формах клієнта й послуги
        Text(text)
            .font(.headline)
            .foregroundColor(colors.textSecondary)
            .padding(.leading, 16)
    }
}


// Головна кнопка в кінці системної форми: велика, у фірмовому кольорі
struct FormPrimaryButton: View {

    let title: String
    let isEnabled: Bool
    let colors: ThemeColors
    let action: () -> Void

    var body: some View {

        Section {
            Button(action: action) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(isEnabled ? .white : colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isEnabled ? colors.buttonPrimary : colors.buttonSecondary)
                    .cornerRadius(16)
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }
}
