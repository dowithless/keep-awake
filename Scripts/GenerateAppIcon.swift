import AppKit

// Use the same filled coffee cup symbol as the enabled menu bar state.
// Run: xcrun swift Scripts/GenerateAppIcon.swift KeepAwake/Assets.xcassets/AppIcon.appiconset
let output = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "KeepAwake/Assets.xcassets/AppIcon.appiconset", isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

func drawIcon(in context: CGContext) {
    NSColor(calibratedRed: 0.965, green: 0.950, blue: 0.918, alpha: 1).setFill()
    let tile = NSBezierPath(roundedRect: NSRect(x: 86, y: 86, width: 852, height: 852), xRadius: 190, yRadius: 190)
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.13)
    shadow.shadowBlurRadius = 20
    shadow.shadowOffset = NSSize(width: 0, height: -9)
    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    tile.fill()
    NSGraphicsContext.restoreGraphicsState()

    let ink = NSColor(calibratedRed: 0.18, green: 0.21, blue: 0.24, alpha: 1)
    let configuration = NSImage.SymbolConfiguration(pointSize: 512, weight: .regular)
        .applying(NSImage.SymbolConfiguration(paletteColors: [ink]))
    guard let symbol = NSImage(systemSymbolName: "cup.and.saucer.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(configuration) else {
        fatalError("Cannot load the menu bar coffee cup symbol")
    }
    let scale = min(600 / symbol.size.width, 520 / symbol.size.height)
    let size = NSSize(width: symbol.size.width * scale, height: symbol.size.height * scale)
    symbol.draw(in: NSRect(x: (1024 - size.width) / 2, y: (1024 - size.height) / 2,
                          width: size.width, height: size.height))
}

var images: [[String: String]] = []
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = points * scale
        let filename = "AppIcon-\(points)x\(points)@\(scale)x.png"
        guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
              let graphics = NSGraphicsContext(bitmapImageRep: bitmap) else { fatalError("Cannot create icon bitmap") }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = graphics
        let context = graphics.cgContext
        context.clear(CGRect(x: 0, y: 0, width: pixels, height: pixels))
        context.scaleBy(x: CGFloat(pixels) / 1024, y: CGFloat(pixels) / 1024)
        drawIcon(in: context)
        NSGraphicsContext.restoreGraphicsState()
        guard let data = bitmap.representation(using: .png, properties: [:]) else { fatalError("Cannot encode icon") }
        try data.write(to: output.appendingPathComponent(filename))
        images.append(["idiom": "mac", "size": "\(points)x\(points)", "scale": "\(scale)x", "filename": filename])
    }
}
let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
let json = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
try (json + Data([10])).write(to: output.appendingPathComponent("Contents.json"))
print("Generated \(images.count) app icon assets")
