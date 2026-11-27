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

    // Запис, який треба відкрити (тап по сповіщенню). Головна відкриває його й скидає
    @Published var openAppointmentID: UUID?

    // День, який треба відкрити в Календарі («Переглянути» в «Ритмі місяця»). Календар відкриває його й скидає
    @Published var openCalendarDay: Date?

    init() {
        session = SessionManager()
    }
}
