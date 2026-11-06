// Draws the Quick Styles icon at every size the app and extension need.
// Run: swift scripts/make-icons.swift
import AppKit

func render(_ px: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let s = CGFloat(px)
    // macOS icon grid: 824pt body inside a 1024 canvas.
    let inset = s * 100 / 1024
    let body = NSRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let shape = NSBezierPath(roundedRect: body, xRadius: body.width * 0.225, yRadius: body.width * 0.225)
    NSGradient(colors: [NSColor(red: 1.0, green: 0.62, blue: 0.20, alpha: 1),
                        NSColor(red: 0.96, green: 0.32, blue: 0.16, alpha: 1)])!.draw(in: shape, angle: -90)

    let config = NSImage.SymbolConfiguration(pointSize: s * 0.42, weight: .semibold)
        .applying(.init(paletteColors: [.white]))
    if let symbol = NSImage(systemSymbolName: "paintbrush.pointed.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) {
        let size = symbol.size
        symbol.draw(in: NSRect(x: (s - size.width) / 2, y: (s - size.height) / 2, width: size.width, height: size.height))
    }
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let fm = FileManager.default
let iconset = "App/Assets.xcassets/AppIcon.appiconset"
try fm.createDirectory(atPath: iconset, withIntermediateDirectories: true)
var images: [[String: String]] = []
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = "icon_\(points)x\(points)@\(scale)x.png"
        try render(points * scale).write(to: URL(fileURLWithPath: "\(iconset)/\(name)"))
        images.append(["idiom": "mac", "size": "\(points)x\(points)", "scale": "\(scale)x", "filename": name])
    }
}
let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    .write(to: URL(fileURLWithPath: "\(iconset)/Contents.json"))

for px in [48, 96, 128, 256, 512] {
    try render(px).write(to: URL(fileURLWithPath: "Extension/Resources/icon-\(px).png"))
}

// Safari toolbar icon: the same paintbrush, black on transparent. Safari
// only uses the alpha channel and tints it to match the toolbar. The outline
// variant matches the other outlined icons in Safari's toolbar.
func renderToolbar(_ px: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let s = CGFloat(px)
    let config = NSImage.SymbolConfiguration(pointSize: s, weight: .regular)
        .applying(.init(paletteColors: [.black]))
    if let symbol = NSImage(systemSymbolName: "paintbrush.pointed", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) {
        // Scale the symbol to fit the canvas, keeping its proportions.
        let fit = min(s / symbol.size.width, s / symbol.size.height)
        let w = symbol.size.width * fit, h = symbol.size.height * fit
        symbol.draw(in: NSRect(x: (s - w) / 2, y: (s - h) / 2, width: w, height: h))
    }
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

for px in [16, 19, 32, 38] {
    try renderToolbar(px).write(to: URL(fileURLWithPath: "Extension/Resources/toolbar-\(px).png"))
}
print("Icons written")
