//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 16.07.26.
//

import SwiftUI


struct SignUpCurrencyStep: View {


    @ObservedObject var state: SignUpState


    var body: some View {


        VStack(
            spacing: 28
        ) {


            Text("Choose currency")
                .font(.title2.bold())



            VStack(
                alignment: .leading,
                spacing: 12
            ) {


                Text("Currency")
                    .font(.headline)



                Picker(
                    "Currency",
                    selection: $state.currencyCode
                ) {


                    ForEach(
                        SupportedCurrency.all
                    ) { currency in


                        Text(
                            "\(currency.symbol) \(currency.title)"
                        )
                        .tag(
                            currency.code
                        )
                    }
                }
                .pickerStyle(.menu)

            }

        }
    }
}
