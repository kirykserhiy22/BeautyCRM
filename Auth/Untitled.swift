//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 16.07.26.
//

import SwiftUI

struct WelcomeView: View {

    @EnvironmentObject var router: AppRouter

    var body: some View {

        VStack(spacing: 30) {

            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 70))

            VStack(spacing: 12) {

                Text("Beauty CRM")
                    .font(.largeTitle.bold())

                Text("Manage your clients, appointments and income in one place.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }

            Spacer()

            Button {

                router.currentScreen = .signUp

            } label: {

                Text("Create Account")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)

            Button {

                router.currentScreen = .login

            } label: {

                Text("I already have an account")
                    .font(.headline)
            }

        }
        .padding()
    }
}
