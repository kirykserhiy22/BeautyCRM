//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 30.04.26.
//
import SwiftUI
import SwiftData

struct SplashView: View {
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var currency: CurrencyManager
    @EnvironmentObject var profession: ProfessionManager

    @Environment(\.modelContext)
    private var context
    @EnvironmentObject var theme: ThemeManager
    private var colors: ThemeColors {
        theme.colors(for: theme.currentTheme)
    }
    var body: some View {
        
        VStack {
            Text("Beauty CRM")
                .font(.largeTitle)
        }
        .onAppear {
            route()
        }
    }
    
    private func route() {

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 1
        ) {


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
}
