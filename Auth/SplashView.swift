//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 30.04.26.
//
import SwiftUI

struct SplashView: View {
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var router: AppRouter
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


            if appState.session.isLoggedIn {

                router.currentScreen = .main

            } else {

                router.currentScreen = .welcome
            }
        }
    }
}
