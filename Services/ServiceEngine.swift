//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 03.05.26.
//

import Foundation

final class ServiceEngine {
    
    static func validate(name: String) -> Bool {
        return !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    static func calculatePrice(
        services: [Service],
        variablePrices: [UUID: Decimal]
    ) -> Decimal {
        
        var total: Decimal = 0
        
        for service in services {
            
            switch service.pricingType {
                
            case .fixed:
                total += service.price ?? 0
                
            case .variable:
                total += variablePrices[service.id] ?? 0
            }
        }
        
        return total
    }
}
