//
//  OnboardingView.swift
//  BeautyCRM
//
//  Короткий гід по додатку у форматі сторіс: один раз після реєстрації
//  і будь-коли з Налаштувань («Як користуватися»).
//  Картинки намальовані кодом: самі підлаштовуються під мову й світлий/темний вигляд.
//

import SwiftUI


// MARK: - STORE

// Гід чекає лише на щойно зареєстрованого майстра на цьому телефоні
enum OnboardingStore {

    private static func key(_ userID: String) -> String {
        "onboarding.pending.\(userID)"
    }

    static func markPending(userID: String, defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: key(userID))
    }

    static func isPending(userID: String, defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: key(userID))
    }

    static func markSeen(userID: String, defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key(userID))
    }
}


// MARK: - SLIDES

enum OnboardingSlide: Int, CaseIterable, Identifiable {

    case home
    case newAppointment
    case reschedule
    case complete
    case client
    case settings

    var id: Int { rawValue }

    var titleKey: String { "onboarding.\(rawValue + 1).title" }
    var textKey: String { "onboarding.\(rawValue + 1).text" }
}


// MARK: - SCREEN

struct OnboardingView: View {

    let onFinish: () -> Void

    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager

    @State private var page = 0

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    private var slides: [OnboardingSlide] { OnboardingSlide.allCases }

    private var isLast: Bool { page == slides.count - 1 }

    var body: some View {

        ZStack {

            colors.background
                .ignoresSafeArea()

            VStack(spacing: 14) {

                progressBars

                HStack {
                    Spacer()
                    Button(localization.localizedString(for: "onboarding.skip")) {
                        onFinish()
                    }
                    .font(.subheadline)
                    .foregroundColor(colors.textSecondary)
                    .opacity(isLast ? 0 : 1)
                    .disabled(isLast)
                    .accessibilityIdentifier("onboarding.skip")
                }

                TabView(selection: $page) {
                    ForEach(slides) { slide in
                        slideView(slide)
                            .tag(slide.rawValue)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                Button {
                    if isLast {
                        onFinish()
                    } else {
                        withAnimation { page += 1 }
                    }
                } label: {
                    AuthButtonLabel(
                        title: LocalizedStringKey(isLast ? "onboarding.start" : "onboarding.next"),
                        background: colors.buttonPrimary,
                        foreground: .white
                    )
                }
                .accessibilityIdentifier(isLast ? "onboarding.start" : "onboarding.next")
            }
            .padding()
        }
    }

    // Смужки зверху, як у сторіс: пройдені й поточна — яскраві
    private var progressBars: some View {

        HStack(spacing: 4) {
            ForEach(slides) { slide in
                Capsule()
                    .fill(slide.rawValue <= page ? colors.textPrimary : colors.textMuted.opacity(0.5))
                    .frame(height: 3)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: page)
        .accessibilityHidden(true)
    }

    private func slideView(_ slide: OnboardingSlide) -> some View {

        VStack(alignment: .leading, spacing: 14) {

            OnboardingIllustration(slide: slide, isActive: page == slide.rawValue)
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .background(colors.card.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .accessibilityHidden(true)

            Text(localization.localizedString(for: slide.titleKey))
                .font(.title2.bold())
                .foregroundColor(colors.textPrimary)

            Text(localization.localizedString(for: slide.textKey))
                .font(.body)
                .foregroundColor(colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}


// MARK: - ILLUSTRATIONS

// Мініекрани з фірмовими кольорами і пальцем, що показує дотик чи перетягування
struct OnboardingIllustration: View {

    let slide: OnboardingSlide
    let isActive: Bool

    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var currency: CurrencyManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var animate = false

    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }

    var body: some View {

        Group {
            switch slide {
            case .home: home
            case .newAppointment: newAppointment
            case .reschedule: reschedule
            case .complete: complete
            case .client: client
            case .settings: settings
            }
        }
        .padding(18)
        .onAppear { restart() }
        .onChange(of: isActive) { restart() }
    }

    // Анімація пальця — лише на видимому слайді і не при «Зменшенні руху»
    private func restart() {
        animate = false
        guard isActive, !reduceMotion else {
            return
        }
        withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true).delay(0.3)) {
            animate = true
        }
    }

    private func t(_ key: String) -> String {
        localization.localizedString(for: key)
    }

    // MARK: Pieces

    private var finger: some View {
        Image(systemName: "hand.point.up.left.fill")
            .font(.system(size: 34))
            .foregroundColor(colors.textPrimary)
            .shadow(color: colors.shadow, radius: 4, y: 2)
    }

    private var tapFinger: some View {
        finger
            .scaleEffect(animate ? 0.85 : 1)
            .opacity(animate ? 1 : 0.85)
    }

    private func pill(_ icon: String, _ text: String, highlighted: Bool = false) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(highlighted ? colors.warning : colors.accent)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundColor(highlighted ? colors.warning : colors.textPrimary)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func primaryButton(_ key: String) -> some View {
        Text(t(key))
            .font(.subheadline.bold())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(colors.buttonPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // dashed — «тінь» на місці, звідки запис забрали
    private func block(_ name: String, time: String?, filled: Bool, dashed: Bool = false, height: CGFloat? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name).font(.caption.bold())
            if let time {
                Text(time).font(.caption2)
            }
        }
        .foregroundColor(filled ? .white : colors.textSecondary)
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: height, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(filled ? colors.buttonPrimary : colors.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(dashed ? colors.accent : Color.clear, style: StrokeStyle(lineWidth: 1, dash: [4]))
        )
    }

    private func hourLine(_ text: String) -> some View {
        HStack(spacing: 8) {
            Text(text)
                .font(.caption2)
                .foregroundColor(colors.textMuted)
                .frame(width: 38, alignment: .leading)
            Rectangle()
                .fill(colors.divider)
                .frame(height: 1)
        }
    }

    // MARK: Slides

    private var home: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(t("home.nextAppointment"))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                Text("Anna K.")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                Text("14:00 – 15:30")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(colors.buttonPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(alignment: .bottomTrailing) {
                tapFinger.offset(x: -16, y: 22)
            }

            hourLine("16:00")
            block("Mia N.", time: "16:00 – 17:00", filled: false)
            hourLine("17:00")
            block("Olivia H.", time: "17:00 – 18:00", filled: false)
        }
    }

    private var newAppointment: some View {
        VStack(spacing: 8) {
            pill("person.fill", "Anna K.")
            pill("scissors", currency.format(85))
            pill("clock", "14:00 · 90 min")
            pill("exclamationmark.triangle.fill", t("onboarding.busy"), highlighted: true)
            primaryButton("appointment.createButton")
                .overlay(alignment: .trailing) {
                    tapFinger.offset(x: -24, y: 24)
                }
        }
    }

    private var reschedule: some View {
        GeometryReader { geo in
            let rowHeight = (geo.size.height - 10) / 4
            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    ForEach(["10:00", "11:00", "12:00", "13:00"], id: \.self) { hour in
                        hourLine(hour)
                            .frame(height: rowHeight, alignment: .top)
                    }
                }

                // Тінь там, звідки запис забрали
                block("Anna K.", time: "10:00", filled: false, dashed: true, height: rowHeight - 10)
                    .padding(.leading, 46)
                    .offset(y: 8)

                // Запис «їде» вниз за пальцем
                block("Anna K.", time: nil, filled: true, height: rowHeight - 10)
                    .padding(.leading, 46)
                    .offset(y: 8 + (animate ? rowHeight * 2 : 0))
                    .overlay(alignment: .trailing) {
                        finger
                            .offset(x: -30, y: 8 + (animate ? rowHeight * 2 : 0) + 6)
                    }
            }
        }
    }

    private var complete: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Anna K.").font(.headline).foregroundColor(colors.textPrimary)
                    Text("14:00 – 15:30").font(.caption).foregroundColor(colors.textSecondary)
                }
                Spacer()
                Text(currency.format(85))
                    .font(.title3.bold())
                    .foregroundColor(colors.textPrimary)
            }
            .padding(12)
            .background(colors.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            primaryButton("appointment.complete")
                .overlay(alignment: .trailing) {
                    tapFinger.offset(x: -24, y: 24)
                }

            // Стовпчики Аналітики ростуть, коли візит завершено
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array([0.35, 0.6, 0.45, 0.8, 0.55].enumerated()), id: \.offset) { index, height in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(index == 4 ? colors.buttonPrimary : colors.accent.opacity(0.45))
                        .frame(height: 80 * (index == 4 && animate ? 1 : height))
                }
            }
            .frame(height: 84, alignment: .bottom)
            .padding(.top, 8)
        }
    }

    private var client: some View {
        VStack(spacing: 10) {
            Circle()
                .fill(colors.cardSecondary)
                .frame(width: 54, height: 54)
                .overlay(Text("A").font(.title2.bold()).foregroundColor(colors.accent))
            Text("Anna K.")
                .font(.headline)
                .foregroundColor(colors.textPrimary)

            HStack(spacing: 10) {
                contactCircle { Image(systemName: "phone.fill") }
                contactCircle { ContactNetworkIcon(network: .instagram, size: 18) }
                contactCircle { ContactNetworkIcon(network: .telegram, size: 18) }
            }

            primaryButton("clients.book")
                .overlay(alignment: .trailing) {
                    tapFinger.offset(x: -24, y: 24)
                }

            HStack(spacing: 8) {
                photo("clients.photo.before", color: colors.cardSecondary)
                photo("clients.photo.after", color: colors.buttonPrimary.opacity(0.6))
            }
        }
    }

    private func contactCircle<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .foregroundColor(colors.accent)
            .frame(width: 36, height: 36)
            .background(Circle().fill(colors.card))
    }

    private func photo(_ key: String, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(color)
            .frame(height: 44)
            .overlay(alignment: .topLeading) {
                Text(t(key))
                    .font(.caption2.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.black.opacity(0.45)))
                    .padding(5)
            }
    }

    private var settings: some View {
        VStack(spacing: 0) {
            settingsRow("scissors", t("settings.services"), value: "4")
            Divider().overlay(colors.divider)
            settingsRow("clock", t("settings.workingHours"), value: "9:00–19:00")
            Divider().overlay(colors.divider)
            settingsRow("questionmark.circle", t("settings.guide"), value: nil)
                .background(colors.accent.opacity(animate ? 0.18 : 0.06))
        }
        .background(colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(alignment: .bottomTrailing) {
            tapFinger.offset(x: -30, y: 20)
        }
        .frame(maxHeight: .infinity)
    }

    private func settingsRow(_ icon: String, _ title: String, value: String?) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(colors.accent)
                .frame(width: 20)
            Text(title)
                .font(.subheadline)
                .foregroundColor(colors.textPrimary)
            Spacer()
            if let value {
                Text(value)
                    .font(.caption)
                    .foregroundColor(colors.textSecondary)
            }
            Image(systemName: "chevron.right")
                .font(.caption2.bold())
                .foregroundColor(colors.textMuted)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }
}
