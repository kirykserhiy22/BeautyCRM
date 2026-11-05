//
//  AuthStyle.swift
//  BeautyCRM
//
//  Спільне оформлення екранів вітання, входу й реєстрації.
//

import SwiftUI


// Знак бренду без анімації
struct BrandMarkView: View {

    let letters: Color
    let brush: Color
    let size: CGFloat

    var body: some View {

        ZStack {

            BrandMarkLetters()
                .stroke(
                    letters,
                    style: StrokeStyle(
                        lineWidth: BrandMark.strokeWidth * size / 200,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )

            BrandMarkBrush()
                .fill(brush)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}


// Поле вводу
struct AuthFieldModifier: ViewModifier {

    let colors: ThemeColors

    func body(content: Content) -> some View {
        content
            .foregroundColor(colors.textPrimary)
            .padding()
            .background(colors.inputBackground)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(colors.border, lineWidth: 1)
            )
    }
}

extension View {
    func authField(_ colors: ThemeColors) -> some View {
        modifier(AuthFieldModifier(colors: colors))
    }
}


// Велика кнопка на всю ширину
struct AuthButtonLabel: View {

    let title: LocalizedStringKey
    let background: Color
    let foreground: Color

    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(foreground)
            .frame(maxWidth: .infinity)
            .padding()
            .background(background)
            .cornerRadius(16)
    }
}


// Смужка кроків реєстрації
struct SignUpProgressBar: View {

    let step: Int
    let total: Int
    let colors: ThemeColors

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...total, id: \.self) { index in
                Capsule()
                    .fill(index <= step ? colors.buttonPrimary : colors.buttonSecondary)
                    .frame(height: 5)
            }
        }
        .accessibilityHidden(true)
    }
}
