// Малює іконку Beauty Base (ескіз B «квадрат»: b a / s e, нахилена ніжка-пензлик).
// Запуск з кореня проєкту:  swift docs/brand/generate_app_icon.swift
// Кути не заокруглюємо: iOS робить це сама. Альфа-каналу немає (вимога App Store).

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let output = "BeautyCRM/Assets.xcassets/AppIcon.appiconset"
let size = 1024
let unit = CGFloat(size) / 200  // малюємо в сітці 200×200

func rgb(_ hex: UInt32) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: 1
    )
}

struct Style {
    let name: String
    let backgroundTop: UInt32
    let backgroundBottom: UInt32
    let letters: UInt32
    let brush: UInt32
}

func draw(_ style: Style) {
    let context = CGContext(
        data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    )!

    let gradient = CGGradient(
        colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
        colors: [rgb(style.backgroundTop), rgb(style.backgroundBottom)] as CFArray,
        locations: [0, 1]
    )!
    context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size), end: CGPoint(x: size, y: 0), options: [])

    // Сітка 200×200 з початком угорі, зсув центрує знак в іконці
    context.scaleBy(x: unit, y: -unit)
    context.translateBy(x: 4, y: -200 + 6)

    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.setLineWidth(10)
    context.setStrokeColor(rgb(style.letters))

    let r: CGFloat = 26
    let letters = CGMutablePath()
    // b: кругла частина (ніжка — окремо, це пензлик)
    letters.addEllipse(in: CGRect(x: 66 - r, y: 74 - r, width: r * 2, height: r * 2))
    // a
    letters.addEllipse(in: CGRect(x: 134 - r, y: 74 - r, width: r * 2, height: r * 2))
    letters.move(to: CGPoint(x: 160, y: 48))
    letters.addLine(to: CGPoint(x: 160, y: 100))
    // s
    letters.move(to: CGPoint(x: 87, y: 123))
    letters.addCurve(to: CGPoint(x: 46, y: 128), control1: CGPoint(x: 76, y: 110), control2: CGPoint(x: 46, y: 111))
    letters.addCurve(to: CGPoint(x: 86, y: 152), control1: CGPoint(x: 46, y: 146), control2: CGPoint(x: 86, y: 134))
    letters.addCurve(to: CGPoint(x: 45, y: 157), control1: CGPoint(x: 86, y: 169), control2: CGPoint(x: 56, y: 170))
    // e
    letters.move(to: CGPoint(x: 108, y: 140))
    letters.addLine(to: CGPoint(x: 160, y: 140))
    letters.addArc(
        center: CGPoint(x: 134, y: 140), radius: r,
        startAngle: 0, endAngle: .pi * 0.28, clockwise: true
    )
    context.addPath(letters)
    context.strokePath()

    // Пензлик: нижче товщає, як мазок, і сходиться з круглою частиною b
    let top = CGPoint(x: 30, y: 16), bottom = CGPoint(x: 40, y: 78)
    let topRadius: CGFloat = 3.5, bottomRadius: CGFloat = 7
    let dx = bottom.x - top.x, dy = bottom.y - top.y
    let length = (dx * dx + dy * dy).squareRoot()
    let nx = -dy / length, ny = dx / length
    context.setFillColor(rgb(style.brush))
    context.addLines(between: [
        CGPoint(x: top.x + nx * topRadius, y: top.y + ny * topRadius),
        CGPoint(x: bottom.x + nx * bottomRadius, y: bottom.y + ny * bottomRadius),
        CGPoint(x: bottom.x - nx * bottomRadius, y: bottom.y - ny * bottomRadius),
        CGPoint(x: top.x - nx * topRadius, y: top.y - ny * topRadius)
    ])
    context.closePath()
    context.fillPath()
    context.fillEllipse(in: CGRect(x: top.x - topRadius, y: top.y - topRadius, width: topRadius * 2, height: topRadius * 2))
    context.fillEllipse(in: CGRect(x: bottom.x - bottomRadius, y: bottom.y - bottomRadius, width: bottomRadius * 2, height: bottomRadius * 2))

    let url = URL(fileURLWithPath: "\(output)/\(style.name).png")
    let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, context.makeImage()!, nil)
    CGImageDestinationFinalize(destination)
}

// Звичайна, для темного режиму iOS і монохромна (iOS сама її розфарбовує)
draw(Style(name: "AppIcon", backgroundTop: 0x5E1430, backgroundBottom: 0x3A0A1C, letters: 0xFFFFFF, brush: 0xFF1450))
draw(Style(name: "AppIcon-Dark", backgroundTop: 0x2A0814, backgroundBottom: 0x140409, letters: 0xFFFFFF, brush: 0xFF1450))
draw(Style(name: "AppIcon-Tinted", backgroundTop: 0x000000, backgroundBottom: 0x000000, letters: 0xFFFFFF, brush: 0xB0B0B0))
