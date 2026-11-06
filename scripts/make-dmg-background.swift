// Draws the background for the Quick Styles disk image: a tangerine arrow
// from the app to the Applications folder, and a one-line instruction.
// The layout matches scripts/dmg-settings.py (540 x 340 window, icons
// centered at x 140 and 400, y 160).
// Run: swift scripts/make-dmg-background.swift
import AppKit

let width: CGFloat = 540, height: CGFloat = 340

func render(scale: CGFloat) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(width * scale), pixelsHigh: Int(height * scale),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: width, height: height)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    // Warm off-white, a touch lighter at the top.
    NSGradient(colors: [NSColor(red: 1.0, green: 0.985, blue: 0.97, alpha: 1),
                        NSColor(red: 0.985, green: 0.955, blue: 0.93, alpha: 1)])!
        .draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: -90)

    // Finder's y runs down from the top; AppKit's runs up from the bottom.
    let iconY = height - 160
    let start = NSPoint(x: 218, y: iconY + 4), end = NSPoint(x: 318, y: iconY + 4)
    let arrow = NSBezierPath()
    arrow.move(to: start)
    arrow.curve(to: end, controlPoint1: NSPoint(x: 248, y: iconY + 30), controlPoint2: NSPoint(x: 288, y: iconY + 30))
    arrow.lineWidth = 7
    arrow.lineCapStyle = .round

    // Arrowhead, pointing along the curve's final direction.
    let head = NSBezierPath()
    let angle = atan2(end.y - (iconY + 30), end.x - 288)
    let len: CGFloat = 20, spread: CGFloat = .pi / 5
    head.move(to: NSPoint(x: end.x - len * cos(angle - spread), y: end.y - len * sin(angle - spread)))
    head.line(to: end)
    head.line(to: NSPoint(x: end.x - len * cos(angle + spread), y: end.y - len * sin(angle + spread)))
    head.lineWidth = 7
    head.lineCapStyle = .round
    head.lineJoinStyle = .round

    // Fill the stroked outlines with the app icon's tangerine gradient.
    let stroke = NSBezierPath()
    for path in [arrow, head] {
        let outline = path.cgPath.copy(strokingWithWidth: 7, lineCap: .round, lineJoin: .round, miterLimit: 10)
        stroke.append(NSBezierPath(cgPath: outline))
    }
    NSGraphicsContext.current?.saveGraphicsState()
    stroke.addClip()
    NSGradient(colors: [NSColor(red: 1.0, green: 0.62, blue: 0.20, alpha: 1),
                        NSColor(red: 0.96, green: 0.32, blue: 0.16, alpha: 1)])!
        .draw(in: stroke.bounds.insetBy(dx: -2, dy: -2), angle: 0)
    NSGraphicsContext.current?.restoreGraphicsState()

    let style = NSMutableParagraphStyle()
    style.alignment = .center
    let text = NSAttributedString(string: "Drag Quick Styles into Applications to install", attributes: [
        .font: NSFont.systemFont(ofSize: 13, weight: .medium),
        .foregroundColor: NSColor(red: 0.42, green: 0.36, blue: 0.32, alpha: 1),
        .paragraphStyle: style,
    ])
    text.draw(in: NSRect(x: 0, y: 42, width: width, height: 20))

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

// Write 1x and 2x PNGs; scripts/dmg.sh combines them into a two-resolution
// TIFF so the background stays sharp on Retina screens.
let dir = "scripts/dmg"
try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
try render(scale: 1).representation(using: .png, properties: [:])!
    .write(to: URL(fileURLWithPath: "\(dir)/background.png"))
try render(scale: 2).representation(using: .png, properties: [:])!
    .write(to: URL(fileURLWithPath: "\(dir)/background@2x.png"))
print("Wrote \(dir)/background.png and background@2x.png")
