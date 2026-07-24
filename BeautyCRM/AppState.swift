//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 30.04.26.
//

import Foundation
import Combine

final class AppState: ObservableObject {

    let session: SessionManager

    init() {
        session = SessionManager()
    }
}
