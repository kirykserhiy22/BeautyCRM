//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 16.07.26.
//

import SwiftUI


struct SignUpBusinessStep: View {


    @ObservedObject var state: SignUpState



    var body: some View {


        VStack(
            spacing: 20
        ) {


            Text("signup.business.title")
                .font(.title2.bold())

            TextField(
                "signup.business.name",
                text: $state.businessName
            )
            .textFieldStyle(.roundedBorder)
        }
    }
}
