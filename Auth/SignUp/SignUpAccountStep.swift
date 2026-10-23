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


            Text("signup.account.title")
                .font(.title2.bold())



            TextField("signup.email", text: $state.email)
                .textFieldStyle(.roundedBorder)



            SecureField("signup.password", text: $state.password)
                .textFieldStyle(.roundedBorder)



            Text("signup.password.hint")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}
