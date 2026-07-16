//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 30.05.26.
//

import UIKit

final class PhotoMemoryCache {

    static let shared = PhotoMemoryCache()

    private let cache = NSCache<NSString, UIImage>()

    private init() {

        cache.countLimit = 300        // max images in RAM
        cache.totalCostLimit = 50 * 1024 * 1024 // ~50MB
    }

    func image(for key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func set(_ image: UIImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
    }

    func remove(for key: String) {
        cache.removeObject(forKey: key as NSString)
    }

    func clear() {
        cache.removeAllObjects()
    }
}
