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

}
