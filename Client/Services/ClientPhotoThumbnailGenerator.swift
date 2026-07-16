//
//  Untitled.swift
//  BeautyCRM
//
//  Created by Serhii Kiryk on 30.05.26.
//

import UIKit

enum ClientPhotoThumbnailGenerator {

    static func generate(
        from image: UIImage,
        maxSize: CGFloat = 300
    ) -> UIImage? {

        let size = image.size

        let scale = min(
            maxSize / size.width,
            maxSize / size.height
        )

        let newSize = CGSize(
            width: size.width * scale,
            height: size.height * scale
        )

        let renderer = UIGraphicsImageRenderer(size: newSize)

        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
