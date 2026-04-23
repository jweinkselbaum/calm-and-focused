#!/usr/bin/swift
import AppKit
import CoreGraphics

func drawIcon(size: Int) -> Data? {
    let s = CGFloat(size)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(
        data: nil, width: size, height: size,
        bitsPerComponent: 8, bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }

    // Dark walnut background with rounded corners
    let corner = s * 0.22
    let bgPath = CGMutablePath()
    bgPath.addRoundedRect(in: CGRect(x: 0, y: 0, width: s, height: s),
                          cornerWidth: corner, cornerHeight: corner)
    ctx.addPath(bgPath)
    ctx.setFillColor(CGColor(red: 0.14, green: 0.08, blue: 0.03, alpha: 1))
    ctx.fillPath()

    // Subtle wood grain lines
    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()
    for i in 0..<12 {
        let y = s * (CGFloat(i) / 12.0) + s * 0.04
        let opacity = CGFloat.random(in: 0.04...0.09)
        ctx.setStrokeColor(CGColor(red: 0.55, green: 0.35, blue: 0.12, alpha: opacity))
        ctx.setLineWidth(s * 0.012)
        ctx.move(to: CGPoint(x: 0, y: y))
        ctx.addLine(to: CGPoint(x: s, y: y + CGFloat.random(in: -s*0.02...s*0.02)))
        ctx.strokePath()
    }
    ctx.restoreGState()

    // Waveform bars (7 bars, asymmetric heights)
    let heights: [CGFloat] = [0.32, 0.58, 0.82, 1.0, 0.74, 0.50, 0.28]
    let barCount = CGFloat(heights.count)
    let padX = s * 0.155
    let totalW = s - padX * 2
    let barW = totalW / barCount * 0.50
    let spacing = totalW / barCount
    let maxH = s * 0.56

    let top = CGColor(red: 0.98, green: 0.80, blue: 0.35, alpha: 1)
    let bottom = CGColor(red: 0.70, green: 0.44, blue: 0.10, alpha: 1)

    for (i, ratio) in heights.enumerated() {
        let barH = maxH * ratio
        let x = padX + CGFloat(i) * spacing + (spacing - barW) / 2
        let y = (s - barH) / 2
        let r = min(barW / 2, s * 0.04)

        let barPath = CGMutablePath()
        barPath.addRoundedRect(in: CGRect(x: x, y: y, width: barW, height: barH),
                               cornerWidth: r, cornerHeight: r)

        ctx.saveGState()
        ctx.addPath(barPath)
        ctx.clip()

        guard let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: [top, bottom] as CFArray,
            locations: [0, 1]
        ) else { ctx.restoreGState(); continue }

        ctx.drawLinearGradient(gradient,
            start: CGPoint(x: x + barW / 2, y: y + barH),
            end: CGPoint(x: x + barW / 2, y: y),
            options: [])
        ctx.restoreGState()
    }

    guard let cgImage = ctx.makeImage() else { return nil }
    let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: size, height: size))
    guard let tiff = nsImage.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
    return bitmap.representation(using: .png, properties: [:])
}

let outputDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."

let icons: [(Int, String)] = [
    (16,   "icon_16.png"),
    (32,   "icon_16@2x.png"),
    (32,   "icon_32.png"),
    (64,   "icon_32@2x.png"),
    (128,  "icon_128.png"),
    (256,  "icon_128@2x.png"),
    (256,  "icon_256.png"),
    (512,  "icon_256@2x.png"),
    (512,  "icon_512.png"),
    (1024, "icon_512@2x.png"),
    (1024, "icon_1024.png"),
]

for (size, name) in icons {
    if let data = drawIcon(size: size) {
        let path = "\(outputDir)/\(name)"
        try! data.write(to: URL(fileURLWithPath: path))
        print("✓ \(name)")
    } else {
        print("✗ Failed: \(name)")
    }
}
