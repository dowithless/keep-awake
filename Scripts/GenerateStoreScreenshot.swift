import AppKit

// Editable product-page images. Use current catalog text and the app's
// SF Symbol; the desktop/menu are illustrated, rather than desktop captures.
// Run from the repository root:
// bash Scripts/generate-store-screenshots.sh zh-Hans en-US
struct StatusCard: Decodable {
    let symbol: String
    let label: String
    let value: String
    let active: Bool
}

struct FlowStep: Decodable {
    let symbol: String
    let label: String
}

struct Copy: Decodable {
    let eyebrow: String
    let headline: [String]
    let description: [String]
    let interaction: String
    let benefits: [String]
    let benefitSymbols: [String]?
    let footnote: String
    let menuLocale: String
    let preventDisplaySleep: Bool
    let statusCards: [StatusCard]?
    let isEnabled: Bool?
    let sceneCaption: String?
    let steps: [FlowStep]?
    let repositoryURL: String?
}

func requireFit(_ condition: Bool, _ message: @autoclosure () -> String) {
    guard condition else {
        fputs("Render failed [\(language)/\(screen)]: \(message())\n", stderr)
        exit(1)
    }
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let language = CommandLine.arguments.dropFirst().first ?? "zh-Hans"
let screen = CommandLine.arguments.dropFirst(2).first ?? "01-keep-awake"
requireFit(["01-keep-awake", "02-display-sleep", "03-manual-sleep", "04-simple", "05-open-source"].contains(screen),
             "Unknown screenshot: \(screen)")
let isMinimal = screen == "04-simple"
let isOpenSource = screen == "05-open-source"
let copies = try JSONDecoder().decode([String: [String: Copy]].self, from: Data(contentsOf:
    root.appendingPathComponent("docs/app-store/screenshot-copy.json")))
guard let copy = copies[language]?[screen] else { fatalError("Missing screenshot copy: \(language)/\(screen)") }
let isEnabled = copy.isEnabled ?? true
let catalog = try JSONSerialization.jsonObject(with: Data(contentsOf:
    root.appendingPathComponent("KeepAwake/Localizable.xcstrings"))) as! [String: Any]
let strings = catalog["strings"] as! [String: [String: Any]]
func localized(_ key: String) -> String {
    guard let locales = strings[key]?["localizations"] as? [String: Any],
          let entry = locales[copy.menuLocale] as? [String: Any],
          let unit = entry["stringUnit"] as? [String: Any],
          let value = unit["value"] as? String else { fatalError("Missing menu translation: \(key)") }
    return value
}
func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255,
            green: CGFloat((hex >> 8) & 255) / 255,
            blue: CGFloat(hex & 255) / 255, alpha: alpha)
}
let ink = color(0x1D1D1F)
let muted = color(0x6E6E73)
let accent = color(0x007AFF)
func rounded(_ rect: NSRect, _ radius: CGFloat, _ fill: NSColor,
             stroke: NSColor? = nil, lineWidth: CGFloat = 1) {
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    fill.setFill(); path.fill()
    if let stroke { stroke.setStroke(); path.lineWidth = lineWidth; path.stroke() }
}
func text(_ value: String, x: CGFloat, y: CGFloat, width: CGFloat,
          size: CGFloat, weight: NSFont.Weight = .regular,
          fill: NSColor = ink, height: CGFloat = 110) {
    var fittedSize = size
    var font = NSFont.systemFont(ofSize: fittedSize, weight: weight)
    // Preserve approved Chinese geometry; longer translations may fit down to 84%.
    let minimumSize = language == "zh-Hans" ? size : size * 0.84
    while (value as NSString).size(withAttributes: [.font: font]).width > width,
          fittedSize - 0.5 >= minimumSize {
        fittedSize -= 0.5
        font = NSFont.systemFont(ofSize: fittedSize, weight: weight)
    }
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineBreakMode = .byClipping
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font, .foregroundColor: fill, .paragraphStyle: paragraph
    ]
    let measured = (value as NSString).size(withAttributes: attributes)
    requireFit(measured.width <= width + 1, "Text overflows: \(value) (\(measured.width) > \(width))")
    requireFit(measured.height <= height, "Text exceeds line height: \(value)")
    (value as NSString).draw(in: NSRect(x: x, y: y, width: width, height: height),
                            withAttributes: attributes)
}
func symbol(_ name: String, _ rect: NSRect, fill: NSColor = ink, weight: NSFont.Weight = .regular) {
    let config = NSImage.SymbolConfiguration(pointSize: rect.height, weight: weight)
        .applying(NSImage.SymbolConfiguration(paletteColors: [fill]))
    guard let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
        .withSymbolConfiguration(config) else { fatalError("Missing symbol: \(name)") }
    let scale = min(rect.width / image.size.width, rect.height / image.size.height)
    let size = NSSize(width: image.size.width * scale, height: image.size.height * scale)
    image.draw(in: NSRect(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2,
                         width: size.width, height: size.height),
               from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
}
func withShadow(blur: CGFloat, opacity: CGFloat, offset: CGFloat, _ draw: () -> Void) {
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = color(0x202838, opacity)
    shadow.shadowBlurRadius = blur
    shadow.shadowOffset = NSSize(width: 0, height: -offset)
    shadow.set(); draw()
    NSGraphicsContext.restoreGraphicsState()
}

let output = root.appendingPathComponent("docs/app-store/screenshots/\(language)")
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
guard let cg = CGContext(data: nil, width: 2560, height: 1600,
    bitsPerComponent: 8, bytesPerRow: 2560 * 4,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { fatalError("Cannot create canvas") }
NSGraphicsContext.saveGraphicsState()
cg.scaleBy(x: 2, y: 2)
cg.translateBy(x: 0, y: 800)
cg.scaleBy(x: 1, y: -1)
let flipped = NSGraphicsContext(cgContext: cg, flipped: true)
NSGraphicsContext.current = flipped

color(0xF8F9FB).setFill()
NSRect(x: 0, y: 0, width: 1280, height: 800).fill()

// Left: benefit-led typography, deliberately readable at storefront thumbnail size.
rounded(NSRect(x: 70, y: 74, width: 44, height: 44), 13, color(0xFFFFFF),
        stroke: color(0xE6E8ED), lineWidth: 0.7)
symbol("cup.and.saucer.fill", NSRect(x: 78, y: 84, width: 28, height: 23))
text(copy.eyebrow, x: 128, y: 83, width: 510, size: 18, weight: .medium, fill: muted)
text(copy.headline[0], x: 68, y: 207, width: 600, size: 68, weight: .semibold)
text(copy.headline[1], x: 68, y: 303, width: 600, size: 68, weight: .semibold)
rounded(NSRect(x: 72, y: 413, width: 40, height: 3), 1.5, accent)
for (index, line) in copy.description.enumerated() {
    text(line, x: 71, y: 451 + CGFloat(index) * 36, width: 560,
         size: 24, fill: muted, height: 40)
}
if let cards = copy.statusCards {
    // Explanatory cards sit outside the desktop, rather than representing app controls.
    requireFit(cards.count == 2, "Expected two status explanations")
    for (index, card) in cards.enumerated() {
        let x = 72 + CGFloat(index) * 268
        rounded(NSRect(x: x, y: 572, width: 246, height: 84), 13, color(0xFFFFFF),
                stroke: color(0xE2E5EB), lineWidth: 0.7)
        symbol(card.symbol, NSRect(x: x + 18, y: 598, width: 30, height: 28),
               fill: card.active ? accent : muted)
        text(card.label, x: x + 64, y: 584, width: 165, size: 15, fill: muted, height: 25)
        text(card.value, x: x + 64, y: 610, width: 165, size: 20,
             weight: .medium, height: 30)
    }
} else {
    let benefits = Array(zip(copy.benefitSymbols ?? ["arrow.down", "cube", "terminal"], copy.benefits))
    var benefitX: CGFloat = 72
    for (icon, label) in benefits {
        symbol(icon, NSRect(x: benefitX, y: 588, width: 22, height: 22), fill: accent)
        text(label, x: benefitX + 33, y: 585, width: 155, size: 18, weight: .medium)
        if language != "zh-Hans" && language != "en-US" && !isMinimal && !isOpenSource {
            let labelWidth = (label as NSString).size(withAttributes: [
                .font: NSFont.systemFont(ofSize: 18, weight: .medium)
            ]).width
            requireFit(benefitX + 33 + min(labelWidth, 155) <= 680, "Scenario labels extend beyond the text column")
            benefitX += max(137, 33 + min(labelWidth, 155) + 24)
        } else {
            benefitX += isMinimal || isOpenSource ? 225 : (label.count > 3 ? 175 : 137)
        }
    }
}
text(copy.footnote, x: 72, y: 717, width: 480, size: 17, fill: muted)

// Right: original desktop illustration. All visible menu actions match the app;
// there are no timer, automation or other invented product controls.
NSGraphicsContext.saveGraphicsState()
if isMinimal { cg.translateBy(x: 0, y: 107) }
let panel = isMinimal
    ? NSRect(x: 770, y: 81, width: 578, height: 360)
    : NSRect(x: 716, y: 81, width: 632, height: 622)
withShadow(blur: 25, opacity: 0.07, offset: 10) {
    rounded(panel, 24, isMinimal ? color(0xFFFFFF) : color(0xEEF2F8))
}
NSGraphicsContext.saveGraphicsState()
NSBezierPath(roundedRect: panel, xRadius: 24, yRadius: 24).addClip()
if !isMinimal {
    NSGradient(colors: [color(0xF1F5FB), color(0xDFE8F5)])!.draw(in: panel, angle: 90)
    // Soft, original wallpaper with no decorative wave shapes.
    let blueGlow = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
        colors: [color(0xA9C7ED, 0.62).cgColor, color(0xA9C7ED, 0).cgColor] as CFArray,
        locations: [0, 1])!
    cg.drawRadialGradient(blueGlow, startCenter: CGPoint(x: 1308, y: 670), startRadius: 0,
        endCenter: CGPoint(x: 1308, y: 670), endRadius: 480, options: [])
    let whiteGlow = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
        colors: [color(0xFFFFFF, 0.9).cgColor, color(0xFFFFFF, 0).cgColor] as CFArray,
        locations: [0, 1])!
    cg.drawRadialGradient(whiteGlow, startCenter: CGPoint(x: 790, y: 380), startRadius: 0,
        endCenter: CGPoint(x: 790, y: 380), endRadius: 420, options: [])
}

(isMinimal ? color(0xF0F1F4) : color(0xFFFFFF, 0.7)).setFill()
NSRect(x: panel.minX, y: panel.minY, width: panel.width, height: 54).fill()
rounded(NSRect(x: 1030, y: 88, width: 57, height: 39), 7, color(0x000000, 0.055))
symbol(isEnabled ? "cup.and.saucer.fill" : "cup.and.saucer",
       NSRect(x: 1040, y: 96, width: 37, height: 24))
symbol("wifi", NSRect(x: 1111, y: 98, width: 26, height: 21))
symbol("battery.100", NSRect(x: 1160, y: 97, width: 34, height: 22))

let menu = NSRect(x: 833, y: 146, width: 372, height: 252)
withShadow(blur: 16, opacity: 0.13, offset: 6) {
    rounded(menu, 10, color(0xF8F9FB, 0.96), stroke: color(0xA9ADB8, 0.45), lineWidth: 0.65)
}
let rows: [(String, CGFloat, Bool)] = [
    ("Keep Awake", 163, isEnabled), ("Keep Display Awake", 200, copy.preventDisplaySleep),
    ("Launch at Login", 250, false), ("About & Help…", 300, false),
    ("Quit Keep Awake", 350, false)
]
for (key, y, checked) in rows {
    if checked { symbol("checkmark", NSRect(x: 848, y: y + 6, width: 16, height: 18), weight: .medium) }
    text(localized(key), x: 876, y: y, width: 306, size: 20,
         fill: !isEnabled && key == "Keep Display Awake" ? color(0xA3A3A8) : ink,
         height: 32)
}
for y: CGFloat in [239, 289, 339] {
    color(0x3C3C43, 0.13).setFill()
    NSRect(x: 847, y: y, width: 344, height: 1).fill()
}
NSGraphicsContext.restoreGraphicsState()
NSGraphicsContext.restoreGraphicsState()

// These pointer/outline overlays explain interaction; they are not additional controls.
if !isMinimal && !isOpenSource && isEnabled && copy.preventDisplaySleep {
    symbol("cursorarrow", NSRect(x: 1027, y: 111, width: 31, height: 42), fill: color(0xFFFFFF), weight: .bold)
    symbol("cursorarrow", NSRect(x: 1032, y: 115, width: 21, height: 32), fill: ink, weight: .bold)
} else if !isMinimal && !isOpenSource && isEnabled {
    rounded(NSRect(x: 841, y: 194, width: 356, height: 39), 6,
            color(0x007AFF, 0.035), stroke: color(0x007AFF, 0.65), lineWidth: 1.2)
    symbol("cursorarrow", NSRect(x: 1174, y: 217, width: 31, height: 42), fill: color(0xFFFFFF), weight: .bold)
    symbol("cursorarrow", NSRect(x: 1179, y: 221, width: 21, height: 32), fill: ink, weight: .bold)
}
if let caption = copy.sceneCaption {
    text(caption, x: 858, y: 423, width: 340, size: 16, fill: muted, height: 30)
}
if isOpenSource {
    // Code is extracted from the real project, not invented or presented as app UI.
    guard let repositoryURL = copy.repositoryURL,
          URL(string: repositoryURL)?.host == "github.com" else {
        fatalError("Missing public source repository URL")
    }
    let filename = "SleepAssertionManager.swift"
    let source = try String(contentsOf: root.appendingPathComponent("KeepAwake/\(filename)"), encoding: .utf8)
    let sourceLines = source.components(separatedBy: "\n")
    guard let start = sourceLines.firstIndex(where: {
        $0.contains("let (systemResult, systemID) = api.create(")
    }), start + 3 < sourceLines.count else { fatalError("Cannot locate core source excerpt") }
    let excerpt = sourceLines[start...start + 3].map { String($0.dropFirst(12)) }
    withShadow(blur: 12, opacity: 0.07, offset: 4) {
        rounded(NSRect(x: 746, y: 466, width: 510, height: 205), 12, color(0xFFFFFF, 0.97),
                stroke: color(0xD6DCE6), lineWidth: 0.65)
    }
    symbol("doc.plaintext", NSRect(x: 764, y: 482, width: 17, height: 20), fill: muted)
    text(filename, x: 792, y: 481, width: 438, size: 14, weight: .medium, fill: muted, height: 26)
    color(0xE8EBF0).setFill()
    NSRect(x: 747, y: 517, width: 508, height: 0.7).fill()
    for (index, line) in excerpt.enumerated() {
        let font = NSFont.monospacedSystemFont(ofSize: 11.5, weight: .regular)
        let lineColor = index == 2 ? color(0x346C49) : (index == 1 ? color(0x7454A8) : ink)
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: lineColor]
        let size = (line as NSString).size(withAttributes: attributes)
        requireFit(size.width <= 466, "Source excerpt overflows: \(line)")
        (line as NSString).draw(at: NSPoint(x: 768, y: 539 + CGFloat(index) * 27), withAttributes: attributes)
    }
}
if let steps = copy.steps {
    requireFit(steps.count == 3, "Expected a three-stage sleep flow")
    // Editorial explanation beneath the menu; these are not additional app controls.
    for (index, step) in steps.enumerated() {
        let centerX = 850 + CGFloat(index) * 168
        symbol(step.symbol, NSRect(x: centerX - 23, y: 529, width: 46, height: 38),
               fill: index == 0 ? accent : muted)
        let font = NSFont.systemFont(ofSize: 18, weight: .medium)
        let labelWidth = (step.label as NSString).size(withAttributes: [.font: font]).width
        requireFit(labelWidth <= 148, "Flow label overflows: \(step.label)")
        text(step.label, x: centerX - labelWidth / 2, y: 588, width: labelWidth + 1,
             size: 18, weight: .medium, height: 30)
        if index < 2 {
            symbol("arrow.right", NSRect(x: centerX + 70, y: 537, width: 24, height: 18),
                   fill: color(0xA3ACBA))
        }
    }
}
text(copy.interaction, x: 757, y: 735, width: 495, size: 18, weight: .medium, fill: muted)

NSGraphicsContext.restoreGraphicsState()
guard let image = cg.makeImage(),
      let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
    fatalError("Cannot encode PNG")
}
let file = output.appendingPathComponent("\(screen).png")
try png.write(to: file)
print(file.path)
