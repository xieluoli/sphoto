// 生成 App 图标：纯白底 + 黑色 SPhoto 字标。
// 用法：swiftc -O Tools/make-appicon.swift -o /tmp/makeicon && /tmp/makeicon <输出路径>
//
// App Store 不接受带 alpha 通道的图标，所以位图用 noneSkipLast，产出的 PNG 只有 RGB 三通道。
import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

let side: CGFloat = 1024
let sideMargin: CGFloat = 96          // 两侧留白，字标不顶到圆角
let text = "SPhoto"
let outputPath = CommandLine.arguments[1]

let rgb = CGColorSpaceCreateDeviceRGB()
let ctx = CGContext(
    data: nil, width: Int(side), height: Int(side), bitsPerComponent: 8, bytesPerRow: 0,
    space: rgb, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
)!

// 白底
ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
ctx.fill(CGRect(x: 0, y: 0, width: side, height: side))

/// 系统 UI 字体（SF Pro）的加粗版，跟 iOS 界面同源。
func boldSystemFont(size: CGFloat) -> CTFont {
    let base = CTFontCreateUIFontForLanguage(.system, size, nil)!
    return CTFontCreateCopyWithSymbolicTraits(base, size, nil, .traitBold, .traitBold) ?? base
}

func makeLine(fontSize: CGFloat) -> CTLine {
    let attrs: [CFString: Any] = [
        kCTFontAttributeName: boldSystemFont(size: fontSize),
        kCTForegroundColorAttributeName: CGColor(red: 0, green: 0, blue: 0, alpha: 1),
        kCTKernAttributeName: -fontSize * 0.015,   // 字标收紧一点更整体
    ]
    let attributed = CFAttributedStringCreate(nil, text as CFString, attrs as CFDictionary)!
    return CTLineCreateWithAttributedString(attributed)
}

// 先按参考字号量一次，再按目标宽度反推真实字号
let probeSize: CGFloat = 200
let probeWidth = CTLineGetBoundsWithOptions(makeLine(fontSize: probeSize), .useOpticalBounds).width
let fontSize = probeSize * (side - sideMargin * 2) / probeWidth

let line = makeLine(fontSize: fontSize)
let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)

// 按字形的光学边界居中，而不是按基线，避免视觉偏上
ctx.textPosition = CGPoint(
    x: (side - bounds.width) / 2 - bounds.minX,
    y: (side - bounds.height) / 2 - bounds.minY
)
CTLineDraw(line, ctx)

let url = URL(fileURLWithPath: outputPath) as CFURL
let dest = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("PNG 写入失败") }
print("已生成 \(outputPath)")
