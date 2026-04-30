//
//  Item.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 30.04.26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
