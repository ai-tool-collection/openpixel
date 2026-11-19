import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// MARK: - Native file (.openpixel, JSON)

/// The .openpixel format is plain JSON so people and agents can read it:
/// {"format":"openpixel","version":1,"name":..,"size":[x,y,z],"palette":["#rrggbb",..],
///  "layers":[{"name":..,"visible":true,"locked":false}],"frames":[{"duration":100}],
///  "cels":[{"layer":0,"frame":0,"encoding":"zlib-base64","data":".."}]}
/// palette[0] is the empty slot. Cell order: x fastest, then z (back→front), then y (bottom→top).
public enum NativeFile {
    public static func encode(_ doc: Document) throws -> Data {
        var cels: [[String: Any]] = []
        for li in 0..<doc.layers.count {
            for fi in 0..<doc.frames.count where !doc.cels[li][fi].isEmpty {
                let raw = Data(doc.cels[li][fi].data)
                let z = try (raw as NSData).compressed(using: .zlib) as Data
                cels.append(["layer": li, "frame": fi, "encoding": "zlib-base64", "data": z.base64EncodedString()])
            }
        }
        let obj: [String: Any] = [
            "format": "openpixel", "version": 1, "name": doc.name,
            "size": [doc.sx, doc.sy, doc.sz],
            "palette": doc.palette.map { $0.a == 0 ? "transparent" : $0.hex },
            "layers": doc.layers.map { ["name": $0.name, "visible": $0.visible, "locked": $0.locked] },
            "frames": doc.frames.map { ["duration": $0.duration] },
            "cels": cels,
        ]
        return try JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys])
    }

    public static func decode(_ data: Data) throws -> Document {
        guard let o = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              o["format"] as? String == "openpixel",
              let size = o["size"] as? [Int], size.count == 3 else {
            throw PCError.invalid("not a OpenPixel file")
        }
        try Document.checkSize(size[0], size[1], size[2])
        var doc = Document(name: o["name"] as? String ?? "Untitled", sx: size[0], sy: size[1], sz: size[2])
        if let pal = o["palette"] as? [String] {
            doc.palette = [RGBA(0, 0, 0, 0)] + pal.dropFirst().prefix(255).map { RGBA.parse($0) ?? RGBA(0, 0, 0) }
        }
        let layers = (o["layers"] as? [[String: Any]]) ?? [["name": "Layer 1"]]
        let frames = (o["frames"] as? [[String: Any]]) ?? [["duration": 100]]
        // Every layer × frame holds a full grid, so a file can't ask for unbounded memory.
        guard layers.count <= Document.maxLayers, frames.count <= Document.maxFrames,
              layers.count * frames.count * doc.count <= Document.maxCells else {
            throw PCError.invalid("file has too many layers or frames")
        }
        doc.layers = layers.map { l in
            var layer = Layer(name: l["name"] as? String ?? "Layer")
            layer.visible = l["visible"] as? Bool ?? true
            layer.locked = l["locked"] as? Bool ?? false
            return layer
        }
        if doc.layers.isEmpty { doc.layers = [Layer(name: "Layer 1")] }
        doc.frames = frames.map { Frame(duration: max(1, $0["duration"] as? Int ?? 100)) }
        if doc.frames.isEmpty { doc.frames = [Frame()] }
        doc.cels = Array(repeating: Array(repeating: Grid(count: doc.count), count: doc.frames.count), count: doc.layers.count)
        for c in (o["cels"] as? [[String: Any]]) ?? [] {
            guard let li = c["layer"] as? Int, let fi = c["frame"] as? Int,
                  li >= 0, li < doc.layers.count, fi >= 0, fi < doc.frames.count,
                  let b64 = c["data"] as? String, let z = Data(base64Encoded: b64) else { continue }
            let raw = try (z as NSData).decompressed(using: .zlib) as Data
            guard raw.count == doc.count else { throw PCError.invalid("cel \(li)/\(fi) has the wrong size") }
            doc.cels[li][fi] = Grid(data: [UInt8](raw))
        }
        doc.dropColoursOutsidePalette()
        return doc
    }
}

// MARK: - Pictures (PNG, GIF)

public enum ImageFiles {
    static func cgImage(_ p: Picture) -> CGImage? {
        let data = Data(p.pixels) as CFData
        guard let provider = CGDataProvider(data: data) else { return nil }
        return CGImage(width: p.width, height: p.height, bitsPerComponent: 8, bitsPerPixel: 32,
                       bytesPerRow: p.width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                       provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
    }

    public static func png(_ p: Picture) -> Data {
        let out = NSMutableData()
        guard let img = cgImage(p),
              let dest = CGImageDestinationCreateWithData(out, UTType.png.identifier as CFString, 1, nil) else { return Data() }
        CGImageDestinationAddImage(dest, img, nil)
        CGImageDestinationFinalize(dest)
        return out as Data
    }

    /// Animated GIF; delays in milliseconds. Transparent pixels stay transparent.
    public static func gif(_ frames: [Picture], delays: [Int], loop: Bool = true) -> Data {
        let out = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(out, UTType.gif.identifier as CFString, frames.count, nil) else { return Data() }
        let fileProps = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: loop ? 0 : 1]] as CFDictionary
        CGImageDestinationSetProperties(dest, fileProps)
        for (i, f) in frames.enumerated() {
            guard let img = cgImage(f) else { continue }
            let d = Double(i < delays.count ? delays[i] : 100) / 1000
            let props = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFUnclampedDelayTime: d, kCGImagePropertyGIFDelayTime: d]] as CFDictionary
            CGImageDestinationAddImage(dest, img, props)
        }
        CGImageDestinationFinalize(dest)
        return out as Data
    }

    /// Reads any image macOS understands into RGBA pixels.
    public static func read(_ url: URL) throws -> Picture {
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
              let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
            throw PCError.invalid("could not read image \(url.path)")
        }
        var p = Picture(width: img.width, height: img.height)
        p.pixels.withUnsafeMutableBytes { buf in
            guard let ctx = CGContext(data: buf.baseAddress, width: img.width, height: img.height, bitsPerComponent: 8,
                                      bytesPerRow: img.width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return }
            ctx.draw(img, in: CGRect(x: 0, y: 0, width: img.width, height: img.height))
        }
        // Un-premultiply.
        for i in 0..<(p.width * p.height) {
            let a = Int(p.pixels[i * 4 + 3])
            if a > 0 && a < 255 {
                for k in 0..<3 { p.pixels[i * 4 + k] = UInt8(min(255, Int(p.pixels[i * 4 + k]) * 255 / a)) }
            }
        }
        return p
    }
}

// MARK: - MagicaVoxel .vox

/// MagicaVoxel uses z-up; OpenPixel uses y-up with z toward the front.
/// Mapping: vox.x = x, vox.y = (sz-1-z), vox.z = y.
public enum VoxFile {
    public static func encode(_ doc: Document, frame: Int) throws -> Data {
        guard doc.sx <= 256, doc.sy <= 256, doc.sz <= 256 else { throw PCError.invalid(".vox models are at most 256 per side") }
        let grid = doc.composite(frame: frame)
        var xyzi = Data()
        var n: UInt32 = 0
        for y in 0..<doc.sy { for z in 0..<doc.sz { for x in 0..<doc.sx {
            let v = grid[doc.index(x, y, z)]
            if v == 0 { continue }
            xyzi.append(contentsOf: [UInt8(x), UInt8(doc.sz - 1 - z), UInt8(y), v])
            n += 1
        } } }
        func u32(_ v: UInt32) -> Data { withUnsafeBytes(of: v.littleEndian) { Data($0) } }
        func chunk(_ id: String, _ content: Data) -> Data {
            var d = Data(id.utf8); d += u32(UInt32(content.count)); d += u32(0); d += content; return d
        }
        let size = u32(UInt32(doc.sx)) + u32(UInt32(doc.sz)) + u32(UInt32(doc.sy))
        var rgba = Data()
        for i in 1...256 {
            let c = i < doc.palette.count ? doc.palette[i] : RGBA(0, 0, 0, 255)
            rgba.append(contentsOf: [c.r, c.g, c.b, 255])
        }
        let children = chunk("SIZE", size) + chunk("XYZI", u32(n) + xyzi) + chunk("RGBA", rgba)
        var out = Data("VOX ".utf8); out += u32(150)
        out += Data("MAIN".utf8); out += u32(0); out += u32(UInt32(children.count)); out += children
        return out
    }

    /// Reads a .vox file. Every read is bounds-checked: these files come from the internet, so a short or
    /// malformed file must fail with an error, never read or write outside the data.
    public static func decode(_ data: Data, name: String) throws -> Document {
        let b = [UInt8](data)
        guard b.count >= 8, String(bytes: b[0..<4], encoding: .ascii) == "VOX " else { throw PCError.invalid("not a .vox file") }
        let bad = PCError.invalid("damaged .vox file")
        func u32(_ o: Int) throws -> Int {
            guard o >= 0, o + 4 <= b.count else { throw bad }
            return Int(b[o]) | Int(b[o + 1]) << 8 | Int(b[o + 2]) << 16 | Int(b[o + 3]) << 24
        }
        var size: (Int, Int, Int)?
        var voxels: [(Int, Int, Int, UInt8)] = []
        var palette: [RGBA]?
        var o = 8
        while o + 12 <= b.count {
            let id = String(bytes: b[o..<o + 4], encoding: .ascii) ?? ""
            let len = try u32(o + 4), kids = try u32(o + 8)
            let body = o + 12
            // The chunk's own content must fit inside the file (children may be cut off; we stop there).
            guard len <= b.count - body else { throw bad }
            switch id {
            case "MAIN": o = body + len; continue
            case "SIZE":
                guard len >= 12 else { throw bad }
                if size == nil { size = (try u32(body), try u32(body + 4), try u32(body + 8)) }
            case "XYZI":
                guard len >= 4 else { throw bad }
                if voxels.isEmpty {
                    let n = min(try u32(body), (len - 4) / 4)
                    voxels.reserveCapacity(n)
                    for i in 0..<n {
                        let p = body + 4 + i * 4
                        voxels.append((Int(b[p]), Int(b[p + 1]), Int(b[p + 2]), b[p + 3]))
                    }
                }
            case "RGBA":
                guard len >= 1024 else { throw bad }
                var pal = [RGBA(0, 0, 0, 0)]
                for i in 0..<255 { let p = body + i * 4; pal.append(RGBA(b[p], b[p + 1], b[p + 2], 255)) }
                palette = pal
            default: break
            }
            o = body + len + kids
        }
        guard let s = size else { throw PCError.invalid(".vox file has no model") }
        // MagicaVoxel's z is OpenPixel's y.
        try Document.checkSize(s.0, s.2, s.1)
        var doc = Document(name: name, sx: s.0, sy: s.2, sz: s.1)
        if let p = palette { doc.palette = trimmedPalette(p, used: Set(voxels.map { $0.3 })) } else {
            doc.palette = Palettes.named("db32")!
        }
        for (x, vy, vz, c) in voxels { doc.set(0, 0, x, vz, doc.sz - 1 - vy, c) }
        doc.dropColoursOutsidePalette()
        return doc
    }

    /// Keep all 256 slots so indexes stay valid, but drop trailing unused black entries.
    static func trimmedPalette(_ p: [RGBA], used: Set<UInt8>) -> [RGBA] {
        var last = 1
        for i in 1..<p.count where used.contains(UInt8(i)) || p[i] != RGBA(0, 0, 0, 255) { last = i }
        return Array(p.prefix(last + 1))
    }
}

// MARK: - Wavefront OBJ (one quad per visible face, one material per colour)

public enum ObjFile {
    public static func encode(_ doc: Document, frame: Int, mtlName: String) -> (obj: String, mtl: String) {
        let g = doc.composite(frame: frame)
        var obj = "# OpenPixel export\nmtllib \(mtlName)\n"
        var faces: [UInt8: [String]] = [:]
        var verts = 0
        func solid(_ x: Int, _ y: Int, _ z: Int) -> Bool { doc.inBounds(x, y, z) && g[doc.index(x, y, z)] != 0 }
        let dirs: [((Int, Int, Int), [(Double, Double, Double)])] = [
            ((1, 0, 0), [(1, 0, 0), (1, 1, 0), (1, 1, 1), (1, 0, 1)]),
            ((-1, 0, 0), [(0, 0, 1), (0, 1, 1), (0, 1, 0), (0, 0, 0)]),
            ((0, 1, 0), [(0, 1, 1), (1, 1, 1), (1, 1, 0), (0, 1, 0)]),
            ((0, -1, 0), [(0, 0, 0), (1, 0, 0), (1, 0, 1), (0, 0, 1)]),
            ((0, 0, 1), [(1, 0, 1), (1, 1, 1), (0, 1, 1), (0, 0, 1)]),
            ((0, 0, -1), [(0, 0, 0), (0, 1, 0), (1, 1, 0), (1, 0, 0)]),
        ]
        for y in 0..<doc.sy { for z in 0..<doc.sz { for x in 0..<doc.sx {
            let v = g[doc.index(x, y, z)]
            if v == 0 { continue }
            for (n, quad) in dirs where !solid(x + n.0, y + n.1, z + n.2) {
                for q in quad { obj += "v \(Double(x) + q.0) \(Double(y) + q.1) \(Double(z) + q.2)\n" }
                faces[v, default: []].append("f \(verts + 1) \(verts + 2) \(verts + 3) \(verts + 4)")
                verts += 4
            }
        } } }
        var mtl = "# OpenPixel palette\n"
        for (c, list) in faces.sorted(by: { $0.key < $1.key }) {
            obj += "usemtl c\(c)\n" + list.joined(separator: "\n") + "\n"
            let col = Int(c) < doc.palette.count ? doc.palette[Int(c)] : RGBA(0, 0, 0, 255)
            mtl += String(format: "newmtl c%d\nKd %.4f %.4f %.4f\n", Int(c), Double(col.r) / 255, Double(col.g) / 255, Double(col.b) / 255)
        }
        return (obj, mtl)
    }
}

// MARK: - SVG and HTML

/// Pixel art as vector files: each run of same-coloured pixels in a row becomes one rectangle, so the
/// picture stays sharp at any size. HTML pages embed the SVGs inline (no outside files) and play animations.
public enum WebFiles {
    /// An SVG whose user units are picture pixels, displayed `zoom` times larger.
    public static func svg(_ p: Picture, zoom: Int = 1, id: String? = nil) -> String {
        var rects = ""
        rects.reserveCapacity(p.width * p.height * 8)
        for y in 0..<p.height {
            var x = 0
            while x < p.width {
                let c = p.pixel(y * p.width + x)
                if c.a == 0 { x += 1; continue }
                var end = x + 1
                while end < p.width && p.pixel(y * p.width + end) == c { end += 1 }
                rects += "<rect x=\"\(x)\" y=\"\(y)\" width=\"\(end - x)\" height=\"1\" fill=\"\(c.hex)\""
                if c.a < 255 { rects += String(format: " fill-opacity=\"%.3f\"", Double(c.a) / 255) }
                rects += "/>"
                x = end
            }
        }
        let z = max(1, zoom)
        let idAttr = id.map { " id=\"\($0)\"" } ?? ""
        return "<svg xmlns=\"http://www.w3.org/2000/svg\"\(idAttr) width=\"\(p.width * z)\" height=\"\(p.height * z)\" " +
            "viewBox=\"0 0 \(p.width) \(p.height)\" shape-rendering=\"crispEdges\">\(rects)</svg>"
    }

    /// A self-contained web page showing the frames (animated when there are several).
    public static func html(title: String, frames: [Picture], delays: [Int], zoom: Int) -> String {
        let safe = title.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;")
        let svgs = frames.enumerated().map { i, f in
            "<div class=\"f\"\(i == 0 ? "" : " hidden")>" + svg(f, zoom: zoom) + "</div>"
        }.joined(separator: "\n")
        let player = frames.count < 2 ? "" : """
        <script>
        const d = \(delays); const f = [...document.querySelectorAll('.f')]; let i = 0;
        (function next() { f.forEach((e, k) => e.hidden = k !== i); setTimeout(() => { i = (i + 1) % f.length; next(); }, d[i] || 100); })();
        </script>
        """
        return """
        <!doctype html>
        <html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
        <title>\(safe)</title>
        <style>
        html,body{margin:0;height:100%;background:#1e1e1e;color:#a0a0a0;font:12px -apple-system,BlinkMacSystemFont,sans-serif}
        main{min-height:100%;display:grid;place-items:center;align-content:center;gap:14px}
        .f svg{display:block;max-width:90vw;max-height:80vh;width:auto;height:auto}
        </style></head>
        <body><main>
        \(svgs)
        <div>\(safe) · made with OpenPixel</div>
        </main>
        \(player)
        </body></html>
        """
    }
}
