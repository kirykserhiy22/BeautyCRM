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

}
