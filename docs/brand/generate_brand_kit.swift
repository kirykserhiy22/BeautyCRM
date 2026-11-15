// Малює бренд-кит Beauty Base для соцмереж (аватар Instagram, логотипи, заставка,
// обкладинки «Актуального», палітра) з тих самих фігур, що й іконка додатку.
//
// Запуск з кореня проєкту:
//   swift docs/brand/generate_brand_kit.swift "<папка, куди класти файли>"

import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

let outRoot = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : FileManager.default.currentDirectoryPath + "/brand-kit"

// MARK: - Кольори бренду

func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

let cherryTop: UInt32 = 0x5E1430      // градієнт іконки, верх
let cherryBottom: UInt32 = 0x3A0A1C   // градієнт іконки, низ
let night: UInt32 = 0x2A0814          // фон заставки
let crimson: UInt32 = 0xFF1450        // пензлик
let raspberry: UInt32 = 0xE20942      // головні кнопки
let blush: UInt32 = 0xF7EFF2          // світлий фон
let white: UInt32 = 0xFFFFFF

// MARK: - Шрифт назви

let fontURL = URL(fileURLWithPath: "BeautyCRM/Fonts/Jost.ttf")
CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)

// MARK: - Полотно

func canvas(_ w: Int, _ h: Int, transparent: Bool = false) -> CGContext {
    CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
              space: CGColorSpace(name: CGColorSpace.sRGB)!,
              bitmapInfo: (transparent ? CGImageAlphaInfo.premultipliedLast : CGImageAlphaInfo.noneSkipLast).rawValue)!
}

func save(_ ctx: CGContext, _ path: String) {
    let url = URL(fileURLWithPath: outRoot + "/" + path)
    try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
    CGImageDestinationFinalize(dest)
    print("✓ \(path)")
}

func fill(_ ctx: CGContext, _ hex: UInt32, _ w: Int, _ h: Int) {
    ctx.setFillColor(rgb(hex)); ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
}

func gradient(_ ctx: CGContext, _ w: Int, _ h: Int, _ top: UInt32 = cherryTop, _ bottom: UInt32 = cherryBottom) {
    let g = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                       colors: [rgb(top), rgb(bottom)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: h), end: CGPoint(x: w, y: 0), options: [])
}

// MARK: - Знак (сітка 200×200, як в іконці й у BrandMark.swift)

// Знак у квадраті зі стороною `side`, лівий-верхній кут у (x, y) — координати зверху вниз
func drawMark(_ ctx: CGContext, canvasHeight: Int, x: CGFloat, y: CGFloat, side: CGFloat,
              letters: UInt32, brush: UInt32, glow: Bool = false) {
    let unit = side / 200
    ctx.saveGState()
    ctx.translateBy(x: x, y: CGFloat(canvasHeight) - y)
    ctx.scaleBy(x: unit, y: -unit)
    // центруємо знак у його квадраті (як в іконці)
    ctx.translateBy(x: 4, y: 6)

    ctx.setLineCap(.round); ctx.setLineJoin(.round); ctx.setLineWidth(10)
    ctx.setStrokeColor(rgb(letters))
    let r: CGFloat = 26
    let p = CGMutablePath()
    p.addEllipse(in: CGRect(x: 66 - r, y: 74 - r, width: r * 2, height: r * 2))
    p.addEllipse(in: CGRect(x: 134 - r, y: 74 - r, width: r * 2, height: r * 2))
    p.move(to: CGPoint(x: 160, y: 48)); p.addLine(to: CGPoint(x: 160, y: 100))
    p.move(to: CGPoint(x: 87, y: 123))
    p.addCurve(to: CGPoint(x: 46, y: 128), control1: CGPoint(x: 76, y: 110), control2: CGPoint(x: 46, y: 111))
    p.addCurve(to: CGPoint(x: 86, y: 152), control1: CGPoint(x: 46, y: 146), control2: CGPoint(x: 86, y: 134))
    p.addCurve(to: CGPoint(x: 45, y: 157), control1: CGPoint(x: 86, y: 169), control2: CGPoint(x: 56, y: 170))
    p.move(to: CGPoint(x: 108, y: 140)); p.addLine(to: CGPoint(x: 160, y: 140))
    p.addArc(center: CGPoint(x: 134, y: 140), radius: r, startAngle: 0, endAngle: .pi * 0.28, clockwise: true)
    ctx.addPath(p); ctx.strokePath()

    // пензлик
    let top = CGPoint(x: 30, y: 16), bottom = CGPoint(x: 40, y: 78)
    let tr: CGFloat = 3.5, br: CGFloat = 7
    let dx = bottom.x - top.x, dy = bottom.y - top.y, len = (dx * dx + dy * dy).squareRoot()
    let nx = -dy / len, ny = dx / len
    if glow { ctx.setShadow(offset: .zero, blur: 14, color: rgb(brush, 0.9)) }
    ctx.setFillColor(rgb(brush))
    ctx.addLines(between: [
        CGPoint(x: top.x + nx * tr, y: top.y + ny * tr), CGPoint(x: bottom.x + nx * br, y: bottom.y + ny * br),
        CGPoint(x: bottom.x - nx * br, y: bottom.y - ny * br), CGPoint(x: top.x - nx * tr, y: top.y - ny * tr)
    ])
    ctx.closePath(); ctx.fillPath()
    ctx.fillEllipse(in: CGRect(x: top.x - tr, y: top.y - tr, width: tr * 2, height: tr * 2))
    ctx.fillEllipse(in: CGRect(x: bottom.x - br, y: bottom.y - br, width: br * 2, height: br * 2))
    ctx.restoreGState()
}

// MARK: - Текст

// Рядок тексту по центру; y — базова лінія від верху полотна
func drawText(_ ctx: CGContext, canvasWidth: Int, canvasHeight: Int, text: String, font: String,
              size: CGFloat, tracking: CGFloat, color: UInt32, centerY: CGFloat, alpha: CGFloat = 1) {
    let ctFont = CTFontCreateWithName(font as CFString, size, nil)
    let attrs: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key(kCTFontAttributeName as String): ctFont,
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): rgb(color, alpha),
        NSAttributedString.Key(kCTKernAttributeName as String): tracking
    ]
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attrs))
    let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
    let width = bounds.width - tracking   // останній символ без відступу
    ctx.saveGState()
    ctx.textPosition = CGPoint(x: (CGFloat(canvasWidth) - width) / 2 - bounds.minX,
                               y: CGFloat(canvasHeight) - centerY - bounds.midY)
    CTLineDraw(line, ctx)
    ctx.restoreGState()
}

let wordmark = "BEAUTY BASE"

// MARK: - 1. Аватар Instagram

// Instagram обрізає аватар у коло — знак менший, щоб пензлик не зрізався
for (name, top, bottom) in [("avatar-cherry", cherryTop, cherryBottom), ("avatar-night", night, 0x140409 as UInt32)] {
    let s = 1080
    let ctx = canvas(s, s)
    gradient(ctx, s, s, top, bottom)
    let side = CGFloat(s) * 0.74
    drawMark(ctx, canvasHeight: s, x: (CGFloat(s) - side) / 2, y: (CGFloat(s) - side) / 2,
             side: side, letters: white, brush: crimson)
    save(ctx, "1 Профіль Instagram/\(name)-1080.png")
}

// MARK: - 2. Іконка додатку (як в App Store)

do {
    let s = 1024
    let ctx = canvas(s, s)
    gradient(ctx, s, s)
    drawMark(ctx, canvasHeight: s, x: 0, y: 0, side: CGFloat(s), letters: white, brush: crimson)
    save(ctx, "2 Іконка додатку/app-icon-1024.png")
}

// MARK: - 3. Логотип

// Знак на прозорому фоні — для накладання на фото й відео
for (name, letters) in [("mark-white", white), ("mark-cherry", 0x4A0E24 as UInt32)] {
    let s = 2048
    let ctx = canvas(s, s, transparent: true)
    drawMark(ctx, canvasHeight: s, x: 0, y: 0, side: CGFloat(s), letters: letters, brush: crimson)
    save(ctx, "3 Логотип/\(name)-transparent.png")
}

// Знак + назва, як на заставці додатку
for (name, bg, text, light) in [("logo-night", night, white, false), ("logo-light", blush, 0x2A0814 as UInt32, true)] {
    let w = 1600, h = 1200
    let ctx = canvas(w, h)
    fill(ctx, bg, w, h)
    let side: CGFloat = 520
    drawMark(ctx, canvasHeight: h, x: (CGFloat(w) - side) / 2, y: 190, side: side,
             letters: light ? 0x4A0E24 : white, brush: crimson, glow: !light)
    drawText(ctx, canvasWidth: w, canvasHeight: h, text: wordmark, font: "Jost", size: 84,
             tracking: 18.5, color: text, centerY: 840)
    save(ctx, "3 Логотип/\(name).png")
}

// MARK: - 4. Заставка (сторіс / вертикальне відео 9:16)

do {
    let w = 1080, h = 1920
    let ctx = canvas(w, h)
    fill(ctx, night, w, h)
    let side: CGFloat = 420
    drawMark(ctx, canvasHeight: h, x: (CGFloat(w) - side) / 2, y: 640, side: side,
             letters: white, brush: crimson, glow: true)
    drawText(ctx, canvasWidth: w, canvasHeight: h, text: wordmark, font: "Jost", size: 60,
             tracking: 13.2, color: white, centerY: 1170)
    save(ctx, "4 Заставка/splash-story-1080x1920.png")
}

// MARK: - 5. Обкладинки «Актуального» (Highlights)

// Instagram показує їх у колі — знак або короткий символ по центру
do {
    let s = 1080
    let ctx = canvas(s, s)
    fill(ctx, night, s, s)
    let side = CGFloat(s) * 0.6
    drawMark(ctx, canvasHeight: s, x: (CGFloat(s) - side) / 2, y: (CGFloat(s) - side) / 2,
             side: side, letters: white, brush: crimson)
    save(ctx, "5 Обкладинки Актуального/highlight-mark.png")
}

// MARK: - 6. Палітра

do {
    let swatches: [(UInt32, String, String)] = [
        (night, "#2A0814", "Ніч — фон"),
        (0x4A0E24, "#4A0E24", "Вишня — картки"),
        (cherryTop, "#5E1430", "Вишня світла"),
        (raspberry, "#E20942", "Малина — кнопки"),
        (crimson, "#FF1450", "Пензлик — акцент"),
        (blush, "#F7EFF2", "Пудра — світлий фон")
    ]
    let w = 1800, rowH = 200, h = rowH * swatches.count
    let ctx = canvas(w, h)
    for (i, s) in swatches.enumerated() {
        let y = CGFloat(h - (i + 1) * rowH)
        ctx.setFillColor(rgb(s.0)); ctx.fill(CGRect(x: 0, y: y, width: CGFloat(w), height: CGFloat(rowH)))
        let textColor: UInt32 = (s.0 == blush) ? 0x2A0814 : white
        let font = CTFontCreateWithName("Helvetica Neue" as CFString, 56, nil)
        for (text, x) in [(s.1, 80.0), (s.2, 640.0)] {
            let attrs: [NSAttributedString.Key: Any] = [
                NSAttributedString.Key(kCTFontAttributeName as String): font,
                NSAttributedString.Key(kCTForegroundColorAttributeName as String): rgb(textColor)
            ]
            let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attrs))
            ctx.textPosition = CGPoint(x: x, y: y + 80)
            CTLineDraw(line, ctx)
        }
    }
    save(ctx, "6 Кольори і шрифт/palette.png")
}
