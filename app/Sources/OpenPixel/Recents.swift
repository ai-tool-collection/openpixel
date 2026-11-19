import Foundation
import AppKit
import OpenPixelCore

/// Recently opened or saved files for the home screen: path, name, size and a small preview picture,
/// kept in Application Support/OpenPixel (recents.json + thumbs/). Nothing leaves this computer.
final class Recents {
    struct Entry: Codable {
        var path: String
        var name: String
        var kind: String
        var size: [Int]
        var touched: Double
        var thumb: String?
    }

    let folder: URL
    private(set) var entries: [Entry] = []
    static let limit = 40

    init(folder: URL) {
        self.folder = folder
        try? FileManager.default.createDirectory(at: folder.appendingPathComponent("thumbs"), withIntermediateDirectories: true)
        if let d = try? Data(contentsOf: folder.appendingPathComponent("recents.json")),
           let list = try? JSONDecoder().decode([Entry].self, from: d) {
            entries = list
        }
    }

    static var defaultFolder: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("OpenPixel", isDirectory: true)
    }

    func save() {
        if let d = try? JSONEncoder().encode(entries) { try? d.write(to: folder.appendingPathComponent("recents.json"), options: .atomic) }
    }

    /// Records the engine's current file (after an open or a save) with a fresh preview.
    func touch(engine: Engine) {
        guard let url = engine.path else { return }
        let doc = engine.doc
        // Stable name per path (FNV-1a; Swift's hashValue changes between launches).
        var h: UInt64 = 0xcbf29ce484222325
        for b in url.path.utf8 { h = (h ^ UInt64(b)) &* 0x100000001b3 }
        let thumbName = String(format: "%016llx.png", h)
        let args: [String: Any] = ["frame": 0, "scale": engine.isSprite ? max(1, 128 / max(doc.sx, doc.sy)) : max(1, 160 / (max(doc.sx, doc.sy, doc.sz) * 2))]
        if let png = (try? engine.execute("render_view", args, source: "home"))?.images.first {
            try? png.write(to: folder.appendingPathComponent("thumbs").appendingPathComponent(thumbName), options: .atomic)
        }
        entries.removeAll { $0.path == url.path }
        entries.insert(Entry(path: url.path, name: url.deletingPathExtension().lastPathComponent,
                             kind: engine.isSprite ? "2d" : "3d", size: [doc.sx, doc.sy, doc.sz],
                             touched: Date().timeIntervalSince1970, thumb: thumbName), at: 0)
        if entries.count > Recents.limit { entries.removeLast(entries.count - Recents.limit) }
        save()
    }

    func remove(_ path: String) {
        entries.removeAll { $0.path == path }
        save()
    }

    /// The list for the home screen, with previews inlined and whether each file still exists.
    func listForPage() -> [[String: Any]] {
        entries.map { e in
            var o: [String: Any] = ["path": e.path, "name": e.name, "kind": e.kind, "size": e.size, "touched": e.touched,
                                    "folder": (e.path as NSString).deletingLastPathComponent.replacingOccurrences(of: NSHomeDirectory(), with: "~"),
                                    "exists": FileManager.default.fileExists(atPath: e.path)]
            if let t = e.thumb, let d = try? Data(contentsOf: folder.appendingPathComponent("thumbs").appendingPathComponent(t)) {
                o["thumb"] = "data:image/png;base64," + d.base64EncodedString()
            }
            return o
        }
    }

    /// Previews of the two built-in samples, made once.
    static func samplePreviews() -> [[String: Any]] {
        var out: [[String: Any]] = []
        for (id, threeD) in [("sample2d", false), ("sample3d", true)] {
            let e = Engine()
            Sample.build(into: e, threeD: threeD)
            let args: [String: Any] = threeD ? ["scale": 3] : ["scale": 4]
            let png = (try? e.execute("render_view", args, source: "home"))?.images.first
            out.append(["id": id, "name": threeD ? "Island (3D sample)" : "Mushroom (2D sample)",
                        "kind": threeD ? "3d" : "2d", "size": [e.doc.sx, e.doc.sy, e.doc.sz],
                        "thumb": png.map { "data:image/png;base64," + $0.base64EncodedString() } ?? NSNull()])
        }
        return out
    }
}
