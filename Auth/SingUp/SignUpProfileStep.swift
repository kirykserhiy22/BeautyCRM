//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 16.07.26.
//

import SwiftUI


struct SignUpProfileStep: View {


    @ObservedObject var state: SignUpState



    var body: some View {


        VStack(
            spacing: 20
        ) {


            Text("signup.profile.title")
                .font(.title2.bold())

            TextField("signup.firstName", text: $state.firstName)
                .textFieldStyle(.roundedBorder)

            TextField("signup.lastName", text: $state.lastName)
                .textFieldStyle(.roundedBorder)
        }
    }
}
