// Draws the Quick Styles icon at every size the app and extension need.
// Run: swift scripts/make-icons.swift
import AppKit
import CoreText

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

for px in [16, 32, 48, 64, 96, 128, 256, 512] {
    try render(px).write(to: URL(fileURLWithPath: "Extension/Resources/icon-\(px).png"))
}

// Safari toolbar icon: the same paintbrush as an SVG so it stays sharp at any
// size. Safari only uses the alpha channel and tints it to match the toolbar.
// The outline variant matches the other outlined icons in Safari's toolbar.
//
// SF Symbols can't be exported as vectors through AppKit, so the outline comes
// from the paintbrush.pointed glyph (U+1008F6) in the SF Pro font, which is
// installed with the SF Symbols app or Apple's SF Pro download.
func toolbarSVG() -> String? {
    let font = CTFontCreateWithName("SF Pro" as CFString, 100, nil)
    var units = Array(String(Character(Unicode.Scalar(0x1008F6)!)).utf16)
    var glyphs = [CGGlyph](repeating: 0, count: units.count)
    guard CTFontGetGlyphsForCharacters(font, &units, &glyphs, units.count), glyphs[0] != 0,
          let path = CTFontCreatePathForGlyph(font, glyphs[0], nil) else { return nil }

    // Square canvas around the glyph with a little breathing room. Font
    // coordinates point up, SVG coordinates point down, so flip y.
    let box = path.boundingBoxOfPath
    let side = max(box.width, box.height) * 1.08
    let ox = box.midX - side / 2, oy = box.midY + side / 2
    func pt(_ p: CGPoint) -> String {
        String(format: "%.2f %.2f", p.x - ox, oy - p.y)
    }
    var d = ""
    path.applyWithBlock { element in
        let e = element.pointee
        switch e.type {
        case .moveToPoint: d += "M\(pt(e.points[0]))"
        case .addLineToPoint: d += "L\(pt(e.points[0]))"
        case .addQuadCurveToPoint: d += "Q\(pt(e.points[0])) \(pt(e.points[1]))"
        case .addCurveToPoint: d += "C\(pt(e.points[0])) \(pt(e.points[1])) \(pt(e.points[2]))"
        case .closeSubpath: d += "Z"
        @unknown default: break
        }
    }
    let size = String(format: "%.2f", side)
    return """
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 \(size) \(size)">
      <path fill="#000" d="\(d)"/>
    </svg>

    """
}

if let svg = toolbarSVG() {
    try svg.write(toFile: "Extension/Resources/toolbar-icon.svg", atomically: true, encoding: .utf8)
} else {
    print("SF Pro isn't installed, so the toolbar icon wasn't updated")
}
print("Icons written")
