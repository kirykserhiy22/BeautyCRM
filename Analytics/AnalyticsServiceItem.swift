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
    let revenue: Double
    let count: Int
}

struct AnalyticsClientItem: Identifiable {

    let id = UUID()

    let name: String
    let spent: Double
    let visits: Int
}

struct AnalyticsChartItem: Identifiable {

    let id = UUID()

    let label: String
    let value: Double
}
