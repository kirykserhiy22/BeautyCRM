//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 30.04.26.
//

import SwiftUI

struct RootView: View {
    
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        
        ZStack {
            
            appState.theme.colors().background
                .ignoresSafeArea()
            
            if appState.session.isLoggedIn {
                Text("MAIN APP")
            } else {
                Text("AUTH SCREEN")
            }
        }
    }
}
