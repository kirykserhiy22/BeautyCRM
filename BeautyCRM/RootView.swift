//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 30.04.26.
//

import SwiftUI


struct RootView: View {


    @EnvironmentObject var router: AppRouter


    var body: some View {


        switch router.currentScreen {


        case .splash:

            SplashView()



        case .welcome:

            WelcomeView()



        case .login:

            LoginView()



        case .signUp:

            SignUpFlowView()



        case .main:

            MainTabView()
        }
    }
}
