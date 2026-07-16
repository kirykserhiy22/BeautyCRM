//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 03.05.26.
//

import Foundation
import SwiftData

final class ClientManager {
    
    static func createClient(
        name: String,
        phone: String?,
        instagram: String?,
        userID: String,
        context: ModelContext
    ) {
        let client = Client(
            userID: userID,
            name: name,
            phone: phone,
            instagram: instagram
        )
        
        context.insert(client)
    }
    
    static func delete(client: Client, context: ModelContext) {
        context.delete(client)
    }
}
