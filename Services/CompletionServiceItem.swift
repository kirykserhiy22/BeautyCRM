//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 22.05.26.
//

import Foundation

struct CompletionServiceItem: Identifiable {

    let id = UUID()

    let serviceID: UUID
    let serviceName: String
    let plannedPrice: Decimal
}
