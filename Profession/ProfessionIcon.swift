//
//  ProfessionIcon.swift
//  BeautyCRM
//

import SwiftUI


// Іконка професії. Зараз — SF Symbols (.system).
// Пізніше їх замінять власні іконки в стилі логотипа (.asset з Assets.xcassets),
// і View, які показують `icon.image`, при цьому не зміняться.
enum ProfessionIcon: nonisolated Equatable {

    case system(String)
    case asset(String)


    var image: Image {

        switch self {

        case .system(let name):
            return Image(systemName: name)

        case .asset(let name):
            return Image(name)
        }
    }
}
