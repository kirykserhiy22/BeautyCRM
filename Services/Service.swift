//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 03.05.26.
//
import Foundation
import SwiftData

enum ServicePricingType: String, Codable {
    case fixed
    case variable
}

@Model
final class Service {
    
    var id: UUID
    var userID: String
    
    var name: String
    
    // 💰 pricing
    var pricingType: ServicePricingType
    var price: Decimal? // fixed price
    
    var createdAt: Date
    
    init(
        userID: String,
        name: String,
        pricingType: ServicePricingType,
        price: Decimal? = nil
    ) {
        self.id = UUID()
        self.userID = userID
        self.name = name
        self.pricingType = pricingType
        self.price = price
        self.createdAt = Date()
    }
}
