//
//  Untitled 2.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 20.05.26.
//
import Foundation

enum AnalyticsPeriod: String, CaseIterable, Identifiable {

    case week
    case month
    case year

    var id: String {
        rawValue
    }

    var title: String {

        switch self {

        case .week:
            return "Week"

        case .month:
            return "Month"

        case .year:
            return "Year"
        }
    }

    var subtitle: String {

        switch self {

        case .week:
            return "Current week overview"

        case .month:
            return "Selected month overview"

        case .year:
            return "Selected year overview"
        }
    }
}
