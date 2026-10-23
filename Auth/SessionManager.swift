//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 30.04.26.
//
import Foundation
import Combine

final class SessionManager: ObservableObject {

    @Published var isLoggedIn = false
    @Published var userID: String?


    
    private let key = "session_user"
    
    init() {
        loadSession()
    }
    
    func login(userID: String) {
        self.userID = userID
        self.isLoggedIn = true
        
        UserDefaults.standard.set(userID, forKey: key)
    }
    
    func logout() {
        self.userID = nil
        self.isLoggedIn = false
        SyncTracking.currentWorkspaceID = nil
        
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    private func loadSession() {
        if let savedID = UserDefaults.standard.string(forKey: key) {
            self.userID = savedID
            self.isLoggedIn = true
        }
    }
}
