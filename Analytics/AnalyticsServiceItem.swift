//
//  Untitled 3.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 20.05.26.
//

import Foundation

struct AnalyticsServiceItem: Identifiable {

    let id = UUID()

    let name: String
    let revenue: Decimal
    let count: Int
}


struct AnalyticsClientItem: Identifiable {

    let id = UUID()

    let name: String
    let spent: Decimal
    let visits: Int
}


// Один стовпчик графіка доходу: день (тиждень, місяць) або місяць (рік)
struct AnalyticsChartItem: Identifiable {

    var id: Date { date }

    let date: Date
    let revenue: Decimal
    let count: Int

    // Тільки для малювання графіка
    var value: Double { revenue.doubleValue }
}
