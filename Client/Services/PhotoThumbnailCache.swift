//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 30.05.26.
//

import UIKit

enum PhotoThumbnailCache {

    private static let cache = NSCache<NSString, UIImage>()

    static func image(
        for key: String
    ) -> UIImage? {

        cache.object(
            forKey: key as NSString
        )
    }

    static func save(
        image: UIImage,
        for key: String
    ) {

        cache.setObject(
            image,
            forKey: key as NSString
        )
    }

    static func remove(
        for key: String
    ) {

        cache.removeObject(
            forKey: key as NSString
        )
    }

    static func clear() {

        cache.removeAllObjects()
    }
}
