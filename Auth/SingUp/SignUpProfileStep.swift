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


            Text(
                "About you"
            )
            .font(.title2.bold())



            TextField(
                "First name",
                text: $state.firstName
            )
            .textFieldStyle(.roundedBorder)



            TextField(
                "Last name",
                text: $state.lastName
            )
            .textFieldStyle(.roundedBorder)
        }
    }
}
