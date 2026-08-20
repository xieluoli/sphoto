// 生成 App 图标：白色照片卡 + 镂空上滑箭头，对应「上滑把照片移走」这一个动作。
// 用法：swift Tools/make-appicon.swift SPhoto/Assets.xcassets/AppIcon.appiconset/AppIcon.png
//
// App Store 不接受带 alpha 通道的图标，所以位图用 noneSkipLast，产出的 PNG 只有 RGB 三个通道。
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let side = 1024
let outputPath = CommandLine.arguments[1]

let rgb = CGColorSpaceCreateDeviceRGB()
let ctx = CGContext(
    data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: 0,
    space: rgb, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
)!

let gradient = CGGradient(
    colorsSpace: rgb,
    colors: [
        CGColor(red: 0.51, green: 0.36, blue: 0.98, alpha: 1),
        CGColor(red: 0.20, green: 0.10, blue: 0.51, alpha: 1),
    ] as CFArray,
    locations: [0, 1]
)!

func paintBackground() {
    ctx.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: side), end: CGPoint(x: side, y: 0),
        options: []
    )
}

/// 照片卡里镂空的「日照 + 山峦」剪影，让白卡片一眼是照片而不是文档。
func punchPhotoGlyph() {
    ctx.addEllipse(in: CGRect(x: 376, y: 512, width: 82, height: 82))   // 太阳
    let ridge = CGMutablePath()                                          // 山峦
    ridge.move(to: CGPoint(x: 354, y: 268))
    ridge.addLine(to: CGPoint(x: 468, y: 412))
    ridge.addLine(to: CGPoint(x: 548, y: 330))
    ridge.addLine(to: CGPoint(x: 670, y: 452))
    ridge.addLine(to: CGPoint(x: 670, y: 268))
    ridge.closeSubpath()
    ctx.addPath(ridge)
}

/// 卡片上方的上滑箭头，点明「往上划就移走」。
func strokeChevron() {
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    ctx.setLineWidth(66)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.move(to: CGPoint(x: 388, y: 742))
    ctx.addLine(to: CGPoint(x: 512, y: 858))
    ctx.addLine(to: CGPoint(x: 636, y: 742))
    ctx.strokePath()
}

paintBackground()

// 竖版照片卡，轻微倾斜暗示正在被划走。
let card = CGRect(x: -206, y: -247, width: 412, height: 494)
ctx.saveGState()
ctx.translateBy(x: 512, y: 430)
ctx.rotate(by: -6 * .pi / 180)
ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
ctx.addPath(CGPath(roundedRect: card, cornerWidth: 54, cornerHeight: 54, transform: nil))
ctx.fillPath()
ctx.restoreGState()

// 剪影镂空：裁剪到卡片内，再把背景渐变画回去。
ctx.saveGState()
ctx.translateBy(x: 512, y: 430)
ctx.rotate(by: -6 * .pi / 180)
ctx.translateBy(x: -512, y: -430)
ctx.addPath(CGPath(
    roundedRect: CGRect(x: 306, y: 183, width: 412, height: 494),
    cornerWidth: 54, cornerHeight: 54, transform: nil
))
ctx.clip()
punchPhotoGlyph()
ctx.clip()
ctx.translateBy(x: 512, y: 430)
ctx.rotate(by: 6 * .pi / 180)
ctx.translateBy(x: -512, y: -430)
paintBackground()
ctx.restoreGState()

strokeChevron()

let url = URL(fileURLWithPath: outputPath) as CFURL
let dest = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("PNG 写入失败") }
print("已生成 \(outputPath)")
