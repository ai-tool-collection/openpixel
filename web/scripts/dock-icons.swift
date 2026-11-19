// Renders the dock icons for the website's hero from the apps installed on this Mac, the way macOS draws
// them in the Dock (dark appearance), as 256×256 PNGs in web/public/dock/.
//
//   swift web/scripts/dock-icons.swift
//
// Apps that aren't installed are skipped (the page then falls back to its drawn tile).
import AppKit

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let out = root.appendingPathComponent("public/dock", isDirectory: true)
try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

// Also used for the compare pages: the icons of apps we compare with, when installed.
let compareIcons: [(String, String)] = [
    ("aseprite", "/Applications/Aseprite.app"),
]

let icons: [(String, String)] = [
    ("finder", "/System/Library/CoreServices/Finder.app"),
    ("chrome", "/Applications/Google Chrome.app"),
    ("claude", "/Applications/Claude.app"),
    ("codex", "/Applications/Codex.app"),
    ("grok", "/Applications/Grok Bot.app"),
    ("cursor", "/Applications/Cursor.app"),
    ("hermes", "/Applications/Hermes.app"),
    // Claude Code has no Mac app of its own (its URL helper only carries the generic app icon).
    ("claudecode", "/Applications/Claude Code.app"),
    ("openclaw", "/Applications/OpenClaw.app"),
    ("trash", "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/TrashIcon.icns"),
]

let size = 256
let dark = NSAppearance(named: .darkAqua)!
NSApplication.shared.appearance = dark

/// For apps that aren't installed: their logo (from public/agents) on a dark tile shaped like macOS's dark icons.
let fallbackLogos = ["codex": "dock/codex-mark.svg", "openclaw": "agents/openclaw-color.svg", "claudecode": "agents/claudecode-color.svg"]

func drawTile(name: String, logo _: String) throws {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: size, height: size)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    // Same box as the system icons: 224 px wide, 16 px in from the sides, a soft shadow below.
    let tile = NSRect(x: 16, y: 16, width: 224, height: 224)
    let path = NSBezierPath(roundedRect: tile, xRadius: 52, yRadius: 52)
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
    shadow.shadowOffset = NSSize(width: 0, height: -2)
    shadow.shadowBlurRadius = 4
    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    NSColor(white: 0.13, alpha: 1).setFill()
    path.fill()
    NSGraphicsContext.restoreGraphicsState()
    NSGradient(starting: NSColor(white: 0.20, alpha: 1), ending: NSColor(white: 0.12, alpha: 1))!.draw(in: path, angle: -90)
    NSColor(white: 1, alpha: 0.10).setStroke()
    let rim = NSBezierPath(roundedRect: tile.insetBy(dx: 0.75, dy: 0.75), xRadius: 51, yRadius: 51)
    rim.lineWidth = 1.5
    rim.stroke()
    // The logo itself is drawn by the browser on top of this tile (public/dock/codex-mark.svg): macOS's SVG
    // renderer drops the cut-outs in it.
    NSGraphicsContext.restoreGraphicsState()
    try rep.representation(using: .png, properties: [:])!.write(to: out.appendingPathComponent("\(name).png"))
}

// OpenPixel's own icon uses the classic grid (artwork 824 of 1024 px); macOS 26 icons fill 896 of 1024.
// Draw it enlarged so it sits in the dock at the same size as the others.
do {
    let svg = NSImage(contentsOf: root.appendingPathComponent("public/app-icon.svg"))!
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: size, height: size)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let scale = 896.0 / 824.0, side = Double(size) * scale, inset = (side - Double(size)) / 2
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
    shadow.shadowOffset = NSSize(width: 0, height: -2)
    shadow.shadowBlurRadius = 4
    shadow.set()
    svg.draw(in: NSRect(x: -inset, y: -inset + 2, width: side, height: side))
    NSGraphicsContext.restoreGraphicsState()
    try rep.representation(using: .png, properties: [:])!.write(to: out.appendingPathComponent("openpixel.png"))
    print("wrote openpixel.png")
}

for (name, path) in compareIcons where FileManager.default.fileExists(atPath: path) {
    let icon = NSWorkspace.shared.icon(forFile: path)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: size, height: size)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    dark.performAsCurrentDrawingAppearance {
        icon.draw(in: NSRect(x: 0, y: 0, width: size, height: size), from: .zero, operation: .copy, fraction: 1)
    }
    NSGraphicsContext.restoreGraphicsState()
    let dir = root.appendingPathComponent("public/compare", isDirectory: true)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    try rep.representation(using: .png, properties: [:])!.write(to: dir.appendingPathComponent("\(name).png"))
    print("wrote compare/\(name).png")
}

for (name, path) in icons {
    guard FileManager.default.fileExists(atPath: path) else {
        if let logo = fallbackLogos[name] {
            try drawTile(name: name, logo: logo)
            print("drew \(name).png (app not installed: a dark tile with its logo)")
        } else {
            print("skip \(name): not installed")
        }
        continue
    }
    // An .icns file is the picture itself; for an app, ask macOS for its Dock icon.
    let icon = path.hasSuffix(".icns") ? NSImage(contentsOfFile: path)! : NSWorkspace.shared.icon(forFile: path)
    guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
                                     samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                                     bytesPerRow: 0, bitsPerPixel: 0) else { continue }
    rep.size = NSSize(width: size, height: size)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.imageInterpolation = .high
    dark.performAsCurrentDrawingAppearance {
        icon.draw(in: NSRect(x: 0, y: 0, width: size, height: size), from: .zero, operation: .copy, fraction: 1)
    }
    NSGraphicsContext.restoreGraphicsState()
    let file = out.appendingPathComponent("\(name).png")
    try rep.representation(using: .png, properties: [:])!.write(to: file)
    print("wrote \(file.lastPathComponent)")
}

// A plain dark tile for agents without a Mac app (the page draws their mark on top).
try drawTile(name: "tile", logo: "")
print("drew tile.png")
