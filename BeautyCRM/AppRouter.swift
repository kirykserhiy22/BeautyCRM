
import SwiftUI
import Combine

enum AppScreen {
    case splash
    case welcome
    case login
    case signUp
    case main
}

final class AppRouter: ObservableObject {
    
    @Published var currentScreen: AppScreen = .splash
}
