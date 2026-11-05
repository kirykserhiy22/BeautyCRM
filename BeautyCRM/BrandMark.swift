//
//  BrandMark.swift
//  BeautyCRM
//
//  Знак Beauty Base: b a / s e у два ряди, ніжка b — нахилений пензлик.
//  Ті самі координати (сітка 200×200), що й в іконці: docs/brand/generate_app_icon.swift.
//

import SwiftUI


// Літери без пензлика. Малювати лінією, щоб можна було анімувати через trim
struct BrandMarkLetters: Shape {

    func path(in rect: CGRect) -> Path {

        let radius: CGFloat = 26
        var path = Path()

        // b (кругла частина) і a
        path.addEllipse(in: CGRect(x: 66 - radius, y: 74 - radius, width: radius * 2, height: radius * 2))
        path.addEllipse(in: CGRect(x: 134 - radius, y: 74 - radius, width: radius * 2, height: radius * 2))
        path.move(to: CGPoint(x: 160, y: 48))
        path.addLine(to: CGPoint(x: 160, y: 100))

        // s
        path.move(to: CGPoint(x: 87, y: 123))
        path.addCurve(to: CGPoint(x: 46, y: 128), control1: CGPoint(x: 76, y: 110), control2: CGPoint(x: 46, y: 111))
        path.addCurve(to: CGPoint(x: 86, y: 152), control1: CGPoint(x: 46, y: 146), control2: CGPoint(x: 86, y: 134))
        path.addCurve(to: CGPoint(x: 45, y: 157), control1: CGPoint(x: 86, y: 169), control2: CGPoint(x: 56, y: 170))

        // e
        path.move(to: CGPoint(x: 108, y: 140))
        path.addLine(to: CGPoint(x: 160, y: 140))
        path.addArc(
            center: CGPoint(x: 134, y: 140),
            radius: radius,
            startAngle: .zero,
            endAngle: .radians(.pi * 0.28),
            clockwise: true
        )

        return path.applying(BrandMark.transform(in: rect))
    }
}


// Пензлик: тонкий угорі, товщає донизу, як мазок
struct BrandMarkBrush: Shape {

    func path(in rect: CGRect) -> Path {

        let top = CGPoint(x: 30, y: 16)
        let bottom = CGPoint(x: 40, y: 78)
        let topRadius: CGFloat = 3.5
        let bottomRadius: CGFloat = 7

        let dx = bottom.x - top.x
        let dy = bottom.y - top.y
        let length = (dx * dx + dy * dy).squareRoot()
        let nx = -dy / length
        let ny = dx / length

        var body = Path()
        body.addLines([
            CGPoint(x: top.x + nx * topRadius, y: top.y + ny * topRadius),
            CGPoint(x: bottom.x + nx * bottomRadius, y: bottom.y + ny * bottomRadius),
            CGPoint(x: bottom.x - nx * bottomRadius, y: bottom.y - ny * bottomRadius),
            CGPoint(x: top.x - nx * topRadius, y: top.y - ny * topRadius)
        ])
        body.closeSubpath()

        let topCap = Path(ellipseIn: CGRect(x: top.x - topRadius, y: top.y - topRadius, width: topRadius * 2, height: topRadius * 2))
        let bottomCap = Path(ellipseIn: CGRect(x: bottom.x - bottomRadius, y: bottom.y - bottomRadius, width: bottomRadius * 2, height: bottomRadius * 2))

        return body
            .union(topCap)
            .union(bottomCap)
            .applying(BrandMark.transform(in: rect))
    }
}


enum BrandMark {

    // Товщина лінії літер у сітці 200×200
    static let strokeWidth: CGFloat = 10

    // Сітка 200×200 → розмір екрана; зсув центрує знак
    static func transform(in rect: CGRect) -> CGAffineTransform {
        let scale = min(rect.width, rect.height) / 200
        return CGAffineTransform(translationX: rect.minX, y: rect.minY)
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: 4, y: 6)
    }
}


// Шрифт бренду: назва, великі заголовки й суми. Решта текстів — системний.
enum BrandFont {

    static func register() {
        guard let url = Bundle.main.url(forResource: "Jost", withExtension: "ttf") else {
            return
        }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }

    static func font(size: CGFloat) -> Font {
        .custom("Jost", size: size)
    }
}
