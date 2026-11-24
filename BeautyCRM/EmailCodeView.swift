//
//  EmailCodeView.swift
//  BeautyCRM
//
//  «Введіть код з листа»: 6 цифр після реєстрації (або при вході з непідтвердженою поштою).
//  Код можна вставити з пошти — iPhone ще й сам підказує його над клавіатурою.
//  «Надіслати ще раз» — не частіше ніж раз на хвилину.
//

import SwiftUI
import Combine

struct EmailCodeView: View {

    let email: String
    // nil — код прийнято; інакше помилка для показу
    let verify: (String) async -> AuthError?
    let resend: () async -> AuthError?
    let onChangeEmail: () -> Void

    static let codeLength = 6
    static let resendDelay = 60

    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager

    @State private var code = ""
    @State private var errorKey: String?
    @State private var noticeKey: String?
    @State private var isWorking = false
    @State private var secondsLeft = EmailCodeView.resendDelay
    @FocusState private var isFocused: Bool

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 18) {

            Button(action: onChangeEmail) {
                Label(localization.localizedString(for: "signup.back"), systemImage: "chevron.left")
                    .font(.subheadline)
                    .foregroundColor(colors.textSecondary)
            }
            .buttonStyle(.plain)

            Image(systemName: "envelope")
                .font(.title2)
                .foregroundColor(colors.accent)
                .frame(width: 56, height: 56)
                .background(RoundedRectangle(cornerRadius: 16).fill(colors.card))
                .padding(.top, 4)

            Text(localization.localizedString(for: "auth.code.title"))
                .font(.title.bold())
                .foregroundColor(colors.textPrimary)

            VStack(alignment: .leading, spacing: 2) {
                Text(localization.localizedString(for: "auth.code.sentTo"))
                    .foregroundColor(colors.textSecondary)
                Text(email)
                    .foregroundColor(colors.textPrimary)
            }
            .font(.subheadline)

            codeBoxes

            Text(localization.localizedString(for: "auth.code.hint"))
                .font(.caption)
                .foregroundColor(colors.textSecondary)

            if let errorKey {
                Text(localization.localizedString(for: errorKey))
                    .font(.footnote)
                    .foregroundColor(colors.danger)
                    .accessibilityIdentifier("code.error")
            } else if let noticeKey {
                Text(localization.localizedString(for: noticeKey))
                    .font(.footnote)
                    .foregroundColor(colors.success)
            }

            Spacer(minLength: 0)

            Button {
                submit()
            } label: {
                ZStack {
                    AuthButtonLabel(
                        title: LocalizedStringKey(isWorking ? "" : "auth.code.confirm"),
                        background: code.count == Self.codeLength ? colors.buttonPrimary : colors.buttonSecondary,
                        foreground: .white
                    )
                    if isWorking {
                        ProgressView().tint(.white)
                    }
                }
            }
            .disabled(code.count != Self.codeLength || isWorking)
            .accessibilityIdentifier("code.confirm")

            Button {
                resendCode()
            } label: {
                Text(resendTitle)
                    .font(.subheadline)
                    .foregroundColor(secondsLeft > 0 ? colors.textSecondary : colors.accent)
                    .frame(maxWidth: .infinity)
            }
            .disabled(secondsLeft > 0 || isWorking)
            .accessibilityIdentifier("code.resend")

            Button(action: onChangeEmail) {
                Text(localization.localizedString(for: "auth.code.changeEmail"))
                    .font(.subheadline)
                    .foregroundColor(colors.accent)
                    .frame(maxWidth: .infinity)
            }
            .disabled(isWorking)
        }
        .padding()
        .background(colors.background.ignoresSafeArea())
        .onAppear { isFocused = true }
        .onReceive(ticker) { _ in
            if secondsLeft > 0 { secondsLeft -= 1 }
        }
    }

    // Шість клітинок поверх невидимого поля: друк, вставка й підказка iPhone працюють як звичайно
    private var codeBoxes: some View {

        ZStack {

            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFocused)
                .foregroundColor(.clear)
                .tint(.clear)
                .accessibilityIdentifier("code.field")
                .onChange(of: code) { _, newValue in
                    let digits = String(newValue.filter(\.isNumber).prefix(Self.codeLength))
                    if digits != newValue { code = digits }
                    errorKey = nil
                    if digits.count == Self.codeLength { submit() }
                }

            HStack(spacing: 8) {
                ForEach(0..<Self.codeLength, id: \.self) { index in
                    let digits = Array(code)
                    let isCurrent = index == digits.count && isFocused
                    Text(index < digits.count ? String(digits[index]) : "")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(colors.textPrimary)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(RoundedRectangle(cornerRadius: 12).fill(colors.card))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(errorKey != nil ? colors.danger : (isCurrent ? colors.accent : .clear), lineWidth: 1.5)
                        )
                }
            }
            .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .onTapGesture { isFocused = true }
    }

    private var resendTitle: String {
        guard secondsLeft > 0 else {
            return localization.localizedString(for: "auth.code.resend")
        }
        return String(
            format: localization.localizedString(for: "auth.code.resendIn"),
            String(format: "%d:%02d", secondsLeft / 60, secondsLeft % 60)
        )
    }

    private func submit() {
        guard code.count == Self.codeLength, !isWorking else { return }
        isWorking = true
        noticeKey = nil
        Task {
            let error = await verify(code)
            isWorking = false
            if let error {
                errorKey = error.localizationKey
                code = ""
            }
        }
    }

    private func resendCode() {
        isWorking = true
        errorKey = nil
        Task {
            let error = await resend()
            isWorking = false
            if let error {
                errorKey = error.localizationKey
            } else {
                noticeKey = "auth.code.resent"
                secondsLeft = Self.resendDelay
            }
        }
    }
}
