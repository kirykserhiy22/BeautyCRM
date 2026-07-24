//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 16.07.26.
//

import SwiftUI


struct SignUpAccountStep: View {


    @ObservedObject var state: SignUpState



    var body: some View {


        VStack(
            spacing: 20
        ) {


            Text(
                "Create your account"
            )
            .font(.title2.bold())



            TextField(
                "Email",
                text: $state.email
            )
            .textFieldStyle(.roundedBorder)



            SecureField(
                "Password",
                text: $state.password
            )
            .textFieldStyle(.roundedBorder)



            Text(
                "Use at least 8 characters"
            )
            .font(.caption)
            .foregroundColor(.gray)
        }
    }
}
