//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 30.04.26.
//
import SwiftUI
import SwiftData

// Як показувати заставку. Неон — при кожному запуску додатку
enum SplashPlan: Equatable {
    case neon
    // «Зменшити рух» на iPhone: без мерехтіння й малювання
    case still

    static func choose(reduceMotion: Bool) -> SplashPlan {
        reduceMotion ? .still : .neon
    }

    var duration: TimeInterval {
        switch self {
        case .neon: return 1.7
        case .still: return 0.4
        }
    }
}


struct SplashView: View {

    // Фірмовий момент: фон завжди темний, незалежно від режиму iPhone
    private static let background = Color("SplashBackground")
    private static let crimson = Color(red: 1, green: 0x14 / 255, blue: 0x50 / 255)

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var currency: CurrencyManager
    @EnvironmentObject var profession: ProfessionManager

    @Environment(\.modelContext)
    private var context
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @State private var plan: SplashPlan?
    @State private var drawn: CGFloat = 0
    @State private var brushOn = false
    @State private var nameVisible = false

    var body: some View {

        ZStack {

            Self.background
                .ignoresSafeArea()

            VStack(spacing: 28) {

                mark
                    .frame(width: 150, height: 150)

                Text(Constants.appName.uppercased())
                    .font(BrandFont.font(size: 20))
                    .tracking(4.4)
                    .foregroundColor(.white)
                    .opacity(nameVisible ? 1 : 0)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            start()
        }
    }

    private var mark: some View {

        GeometryReader { proxy in

            let scale = proxy.size.width / 200

            ZStack {

                BrandMarkLetters()
                    .trim(from: 0, to: drawn)
                    .stroke(
                        .white,
                        style: StrokeStyle(
                            lineWidth: BrandMark.strokeWidth * scale,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )

                BrandMarkBrush()
                    .fill(Self.crimson)
                    .shadow(color: Self.crimson, radius: 10)
                    .keyframeAnimator(initialValue: 0.0, trigger: brushOn) { view, value in
                        view.opacity(value)
                    } keyframes: { _ in
                        KeyframeTrack {
                            if plan == .neon {
                                // Спалах неонової вивіски: два короткі провали й рівне світло
                                LinearKeyframe(1, duration: 0.1)
                                LinearKeyframe(0.25, duration: 0.08)
                                LinearKeyframe(1, duration: 0.1)
                                LinearKeyframe(0.45, duration: 0.08)
                                LinearKeyframe(1, duration: 0.14)
                            } else {
                                LinearKeyframe(1, duration: 0.25)
                            }
                        }
                    }
            }
        }
    }

    private func start() {

        let chosen = SplashPlan.choose(reduceMotion: reduceMotion)

        plan = chosen

        switch chosen {

        case .neon:
            withAnimation(.easeOut(duration: 0.8).delay(0.15)) {
                drawn = 1
            }
            withAnimation(.easeOut(duration: 0.3).delay(1.25)) {
                nameVisible = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                brushOn = true
            }

        case .still:
            drawn = 1
            nameVisible = true
            brushOn = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + chosen.duration) {
            route()
        }
    }

    private func route() {

        if appState.session.isLoggedIn,
           let userID = appState.session.userID {

            // Холодний старт зі збереженою сесією:
            // відновити мову, валюту і професію з профілю
            UserProfileLoader.load(
                context: context,
                userID: userID,
                localization: localization,
                currency: currency,
                profession: profession
            )

            router.currentScreen = .main

        } else {

            router.currentScreen = .welcome
        }
    }
}
