import Foundation

/// An 8-bit RGBA picture.
public struct Picture {
    public var width: Int
    public var height: Int
    public var pixels: [UInt8]
    public init(width: Int, height: Int, fill: RGBA = RGBA(0, 0, 0, 0)) {
        self.width = width; self.height = height
        pixels = [UInt8](repeating: 0, count: max(width * height * 4, 0))
        if fill.a != 0 { for i in 0..<(width * height) { setPixel(i, fill) } }
    }
    @inline(__always) public mutating func setPixel(_ i: Int, _ c: RGBA) {
        pixels[i * 4] = c.r; pixels[i * 4 + 1] = c.g; pixels[i * 4 + 2] = c.b; pixels[i * 4 + 3] = c.a
    }
    @inline(__always) public func pixel(_ i: Int) -> RGBA {
        RGBA(pixels[i * 4], pixels[i * 4 + 1], pixels[i * 4 + 2], pixels[i * 4 + 3])
    }
    /// Draws another picture on top (alpha over) at (ox, oy).
    public mutating func blit(_ p: Picture, at ox: Int, _ oy: Int) {
        for y in 0..<p.height {
            let ty = y + oy
            if ty < 0 || ty >= height { continue }
            for x in 0..<p.width {
                let tx = x + ox
                if tx < 0 || tx >= width { continue }
                let s = p.pixel(y * p.width + x)
                if s.a == 0 { continue }
                if s.a == 255 { setPixel(ty * width + tx, s); continue }
                let d = pixel(ty * width + tx), a = Int(s.a)
                let mix: (UInt8, UInt8) -> UInt8 = { UInt8((Int($0) * a + Int($1) * (255 - a)) / 255) }
                setPixel(ty * width + tx, RGBA(mix(s.r, d.r), mix(s.g, d.g), mix(s.b, d.b), UInt8(max(Int(d.a), a))))
            }
        }
    }
}

/// Named camera angles. Isometric uses the 2:1 pixel-art angle (yaw 45°, pitch 30°).
public enum ViewPreset {
    public static func angles(_ name: String) -> (yaw: Double, pitch: Double)? {
        switch name.lowercased() {
        case "front": return (0, 0)
        case "right": return (90, 0)
        case "back": return (180, 0)
        case "left": return (270, 0)
        case "top": return (0, 90)
        case "bottom": return (0, -90)
        case "iso", "isometric", "iso-front-right": return (45, 30)
        case "iso-back-right": return (135, 30)
        case "iso-back-left": return (225, 30)
        case "iso-front-left": return (315, 30)
        default: return nil
        }
    }
    public static let all = ["iso", "iso-front-left", "iso-back-right", "iso-back-left",
                             "front", "back", "left", "right", "top", "bottom"]
}

public struct RenderOptions {
    public var yaw: Double = 45
    public var pitch: Double = 30
    /// Pixels per voxel edge.
    public var scale: Int = 4
    /// Dark outline around the silhouette (classic pixel-art look).
    public var outline = true
    /// Darken pixels where depth jumps, so separate blocks read clearly.
    public var edges = true
    public var background = RGBA(0, 0, 0, 0)
    public var padding = 1
    /// Fit the picture to the whole model space instead of the occupied part.
    public var showBounds = false
    /// No light shading: colours come out exactly as in the palette (2D sprites).
    public var flat = false
    public init() {}
}

/// Software ray caster: one orthographic ray per output pixel, walked through the grid (Amanatides–Woo).
/// Crisp pixels, exact for front/side/top views and clean 2:1 for isometric.
public enum Renderer {
    struct V3 { var x, y, z: Double
        static func - (a: V3, b: V3) -> V3 { V3(x: a.x - b.x, y: a.y - b.y, z: a.z - b.z) }
        static func + (a: V3, b: V3) -> V3 { V3(x: a.x + b.x, y: a.y + b.y, z: a.z + b.z) }
        static func * (a: V3, s: Double) -> V3 { V3(x: a.x * s, y: a.y * s, z: a.z * s) }
        func dot(_ b: V3) -> Double { x * b.x + y * b.y + z * b.z }
        func cross(_ b: V3) -> V3 { V3(x: y * b.z - z * b.y, y: z * b.x - x * b.z, z: x * b.y - y * b.x) }
    }

    public static func render(_ doc: Document, frame: Int, grid: [UInt8]? = nil, _ o: RenderOptions) -> Picture {
        let vox = grid ?? doc.composite(frame: frame)
        let sx = doc.sx, sy = doc.sy, sz = doc.sz
        let yaw = o.yaw * .pi / 180, pitch = max(-89.999, min(89.999, o.pitch)) * .pi / 180
        // v points from the scene toward the camera.
        let v = V3(x: sin(yaw) * cos(pitch), y: sin(pitch), z: cos(yaw) * cos(pitch))
        let f = v * -1
        let r = V3(x: cos(yaw), y: 0, z: -sin(yaw))
        let u = r.cross(f)
        let c = V3(x: Double(sx) / 2, y: Double(sy) / 2, z: Double(sz) / 2)

        // Fit the image to the occupied part of the model (or the whole box when empty).
        var lo = (sx, sy, sz), hi = (0, 0, 0)
        for y in 0..<sy { for z in 0..<sz { for x in 0..<sx where vox[(y * sz + z) * sx + x] != 0 {
            lo = (min(lo.0, x), min(lo.1, y), min(lo.2, z)); hi = (max(hi.0, x + 1), max(hi.1, y + 1), max(hi.2, z + 1))
        } } }
        if o.showBounds || lo.0 > hi.0 { lo = (0, 0, 0); hi = (sx, sy, sz) }
        var minA = Double.infinity, maxA = -Double.infinity, minB = Double.infinity, maxB = -Double.infinity
        for cx in [lo.0, hi.0] { for cy in [lo.1, hi.1] { for cz in [lo.2, hi.2] {
            let p = V3(x: Double(cx), y: Double(cy), z: Double(cz)) - c
            let a = p.dot(r), b = p.dot(u)
            minA = min(minA, a); maxA = max(maxA, a); minB = min(minB, b); maxB = max(maxB, b)
        } } }
        let s = Double(max(o.scale, 1))
        let pad = o.padding + (o.outline ? 1 : 0)
        let w = Int(((maxA - minA) * s).rounded(.up)) + pad * 2
        let h = Int(((maxB - minB) * s).rounded(.up)) + pad * 2
        var pic = Picture(width: max(w, 1), height: max(h, 1), fill: o.background)
        var depth = [Double](repeating: .infinity, count: pic.width * pic.height)
        var hitMask = [Bool](repeating: false, count: pic.width * pic.height)
        let far = Double(sx + sy + sz) * 2

        // Light comes from the upper left of the viewer, so shading stays readable at any angle.
        let light = (r * -0.45 + u * 1.0 + v * 0.55)
        let ln = sqrt(light.dot(light))
        let L = light * (1 / ln)

        let pal = doc.palette
        vox.withUnsafeBufferPointer { g in
            for py in 0..<pic.height {
                for px in 0..<pic.width {
                    let a = minA + (Double(px - pad) + 0.5) / s
                    let b = maxB - (Double(py - pad) + 0.5) / s
                    let origin = c + r * a + u * b + v * far
                    guard let (hit, t, normal) = cast(g, sx, sy, sz, origin, f) else { continue }
                    let col = pal[Int(hit)]
                    let n = V3(x: Double(normal.0), y: Double(normal.1), z: Double(normal.2))
                    let lambert = max(0, n.dot(L))
                    let shade = o.flat ? 1.0 : 0.62 + 0.38 * lambert
                    let i = py * pic.width + px
                    pic.setPixel(i, RGBA(UInt8(min(255, Double(col.r) * shade)), UInt8(min(255, Double(col.g) * shade)),
                                         UInt8(min(255, Double(col.b) * shade)), 255))
                    depth[i] = t
                    hitMask[i] = true
                }
            }
        }

        if o.edges {
            // Darken pixels sitting on a depth step toward the camera (silhouettes of nearer blocks).
            let step = 0.9
            var out = pic
            for py in 0..<pic.height { for px in 0..<pic.width {
                let i = py * pic.width + px
                guard hitMask[i] else { continue }
                var edge = false
                for (nx, ny) in [(px + 1, py), (px - 1, py), (px, py + 1), (px, py - 1)]
                where nx >= 0 && ny >= 0 && nx < pic.width && ny < pic.height {
                    let j = ny * pic.width + nx
                    if hitMask[j] && depth[j] - depth[i] < -step { edge = false; break }
                    if hitMask[j] && depth[j] - depth[i] > step { edge = true }
                }
                if edge {
                    let p = pic.pixel(i)
                    out.setPixel(i, RGBA(UInt8(Double(p.r) * 0.78), UInt8(Double(p.g) * 0.78), UInt8(Double(p.b) * 0.78), p.a))
                }
            } }
            pic = out
        }

        if o.outline {
            var out = pic
            for py in 0..<pic.height { for px in 0..<pic.width {
                let i = py * pic.width + px
                if hitMask[i] { continue }
                var near: RGBA?
                for (nx, ny) in [(px + 1, py), (px - 1, py), (px, py + 1), (px, py - 1)]
                where nx >= 0 && ny >= 0 && nx < pic.width && ny < pic.height && hitMask[ny * pic.width + nx] {
                    near = pic.pixel(ny * pic.width + nx); break
                }
                if let n = near {
                    out.setPixel(i, RGBA(UInt8(Double(n.r) * 0.25), UInt8(Double(n.g) * 0.25), UInt8(Double(n.b) * 0.25), 255))
                }
            } }
            pic = out
        }
        return pic
    }

    /// Walks a ray through the grid; returns the first solid cell's value, distance and face normal.
    @inline(__always)
    static func cast(_ g: UnsafeBufferPointer<UInt8>, _ sx: Int, _ sy: Int, _ sz: Int,
                     _ o: V3, _ d: V3) -> (UInt8, Double, (Int, Int, Int))? {
        // Slab test against the box.
        var tmin = 0.0, tmax = Double.infinity
        var enterAxis = -1
        @inline(__always) func slab(_ oc: Double, _ dc: Double, _ size: Double, _ k: Int) -> Bool {
            if abs(dc) < 1e-12 { return oc >= 0 && oc <= size }
            var t1 = (0 - oc) / dc, t2 = (size - oc) / dc
            if t1 > t2 { swap(&t1, &t2) }
            if t1 > tmin { tmin = t1; enterAxis = k }
            tmax = min(tmax, t2)
            return tmin <= tmax
        }
        if !slab(o.x, d.x, Double(sx), 0) || !slab(o.y, d.y, Double(sy), 1) || !slab(o.z, d.z, Double(sz), 2) {
            return nil
        }
        let p = o + d * (tmin + 1e-7)
        var ix = min(max(Int(p.x.rounded(.down)), 0), sx - 1)
        var iy = min(max(Int(p.y.rounded(.down)), 0), sy - 1)
        var iz = min(max(Int(p.z.rounded(.down)), 0), sz - 1)
        let stepX = d.x > 0 ? 1 : -1, stepY = d.y > 0 ? 1 : -1, stepZ = d.z > 0 ? 1 : -1
        let tdx = abs(d.x) < 1e-12 ? Double.infinity : abs(1 / d.x)
        let tdy = abs(d.y) < 1e-12 ? Double.infinity : abs(1 / d.y)
        let tdz = abs(d.z) < 1e-12 ? Double.infinity : abs(1 / d.z)
        var tmx = abs(d.x) < 1e-12 ? Double.infinity : ((Double(ix) + (stepX > 0 ? 1 : 0)) - o.x) / d.x
        var tmy = abs(d.y) < 1e-12 ? Double.infinity : ((Double(iy) + (stepY > 0 ? 1 : 0)) - o.y) / d.y
        var tmz = abs(d.z) < 1e-12 ? Double.infinity : ((Double(iz) + (stepZ > 0 ? 1 : 0)) - o.z) / d.z
        var axis = enterAxis
        var t = tmin
        while true {
            let v = g[(iy * sz + iz) * sx + ix]
            if v != 0 {
                let n: (Int, Int, Int)
                switch axis {
                case 0: n = (-stepX, 0, 0)
                case 1: n = (0, -stepY, 0)
                case 2: n = (0, 0, -stepZ)
                default: n = (0, 1, 0)
                }
                return (v, t, n)
            }
            if tmx < tmy && tmx < tmz {
                ix += stepX; t = tmx; tmx += tdx; axis = 0
                if ix < 0 || ix >= sx { return nil }
            } else if tmy < tmz {
                iy += stepY; t = tmy; tmy += tdy; axis = 1
                if iy < 0 || iy >= sy { return nil }
            } else {
                iz += stepZ; t = tmz; tmz += tdz; axis = 2
                if iz < 0 || iz >= sz { return nil }
            }
        }
    }

    /// Picks a scale so the longest side of the picture is close to `target` pixels.
    public static func autoScale(_ doc: Document, target: Int) -> Int {
        let longest = Double(max(doc.sx, doc.sy, doc.sz)) * 1.75
        return max(1, min(32, Int(Double(target) / longest)))
    }

    /// Several pictures side by side in a grid with optional labels drawn by the platform layer.
    public static func sheet(_ pics: [Picture], columns: Int, gap: Int = 4, background: RGBA = RGBA(0, 0, 0, 0)) -> (Picture, [(Int, Int, Int, Int)]) {
        let cols = max(1, min(columns, pics.count))
        let rows = (pics.count + cols - 1) / cols
        let cw = pics.map { $0.width }.max() ?? 1, ch = pics.map { $0.height }.max() ?? 1
        var sheet = Picture(width: cols * cw + (cols + 1) * gap, height: rows * ch + (rows + 1) * gap, fill: background)
        var rects: [(Int, Int, Int, Int)] = []
        for (i, p) in pics.enumerated() {
            let x = gap + (i % cols) * (cw + gap) + (cw - p.width) / 2
            let y = gap + (i / cols) * (ch + gap) + (ch - p.height) / 2
            sheet.blit(p, at: x, y)
            rects.append((gap + (i % cols) * (cw + gap), gap + (i / cols) * (ch + gap), cw, ch))
        }
        return (sheet, rects)
    }
}
