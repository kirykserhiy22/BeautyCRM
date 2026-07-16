
import SwiftUI

enum AppScreen {
    case auth
    case onboarding
    case main
}

final class AppRouter: ObservableObject {
    
    @Published var currentScreen: AppScreen = .auth
}
