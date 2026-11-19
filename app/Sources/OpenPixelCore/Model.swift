import Foundation

/// An RGBA colour. Palette index 0 is always "empty" (no voxel).
public struct RGBA: Equatable, Hashable {
    public var r: UInt8, g: UInt8, b: UInt8, a: UInt8
    public init(_ r: UInt8, _ g: UInt8, _ b: UInt8, _ a: UInt8 = 255) {
        self.r = r; self.g = g; self.b = b; self.a = a
    }

    public var hex: String { String(format: "#%02x%02x%02x", r, g, b) }

    public static func parse(_ text: String) -> RGBA? {
        var s = text.trimmingCharacters(in: .whitespaces).lowercased()
        if s.hasPrefix("#") { s.removeFirst() }
        if s.count == 3 { s = s.map { "\($0)\($0)" }.joined() }
        guard s.count == 6 || s.count == 8, let v = UInt64(s, radix: 16) else { return nil }
        if s.count == 6 {
            return RGBA(UInt8((v >> 16) & 255), UInt8((v >> 8) & 255), UInt8(v & 255))
        }
        return RGBA(UInt8((v >> 24) & 255), UInt8((v >> 16) & 255), UInt8((v >> 8) & 255), UInt8(v & 255))
    }

    func distance(to o: RGBA) -> Int {
        let dr = Int(r) - Int(o.r), dg = Int(g) - Int(o.g), db = Int(b) - Int(o.b)
        // Weighted RGB distance (perceptual enough for nearest-colour lookup).
        return 3 * dr * dr + 4 * dg * dg + 2 * db * db
    }
}

/// A layer: every frame has one cel per layer.
public struct Layer: Equatable {
    public var name: String
    public var visible = true
    public var locked = false
    public init(name: String) { self.name = name }
}

/// A frame of the animation. New frames last 100 ms.
public struct Frame: Equatable {
    public var duration: Int = 100
}

/// A dense voxel grid of palette indexes (0 = empty).
/// Coordinates: x grows to the right, y grows up, z grows toward the viewer (front).
public struct Grid: Equatable {
    public var data: [UInt8]
    public init(count: Int) { data = [UInt8](repeating: 0, count: count) }
    public init(data: [UInt8]) { self.data = data }
    public var isEmpty: Bool { !data.contains { $0 != 0 } }
}

public enum PCError: Error, CustomStringConvertible {
    case invalid(String)
    public var description: String {
        switch self { case .invalid(let s): return s }
    }
}

/// The whole model: size, palette, layers × frames of cels.
public struct Document: Equatable {
    public var name: String
    public private(set) var sx: Int
    public private(set) var sy: Int
    public private(set) var sz: Int
    public var palette: [RGBA]
    public var layers: [Layer]
    public var frames: [Frame]
    /// cels[layer][frame]
    public var cels: [[Grid]]

    public static let maxSize = 256
    public static let maxColors = 256
    /// Limits for files read from disk (each layer × frame is a full grid in memory).
    public static let maxLayers = 256
    public static let maxFrames = 1024
    public static let maxCells = 1 << 28

    /// Clears voxels whose colour index has no palette entry, so a damaged or hostile file can't make
    /// later code look up colours past the end of the palette.
    public mutating func dropColoursOutsidePalette() {
        let n = palette.count
        guard n < 256 else { return }
        for li in cels.indices { for fi in cels[li].indices where cels[li][fi].data.contains(where: { Int($0) >= n }) {
            for i in cels[li][fi].data.indices where Int(cels[li][fi].data[i]) >= n { cels[li][fi].data[i] = 0 }
        } }
    }

    public init(name: String = "Untitled", sx: Int = 32, sy: Int = 32, sz: Int = 32,
                palette: [RGBA] = Palettes.named("db32")!) {
        self.name = name
        self.sx = sx; self.sy = sy; self.sz = sz
        self.palette = palette
        layers = [Layer(name: "Layer 1")]
        frames = [Frame()]
        cels = [[Grid(count: sx * sy * sz)]]
    }

    public var count: Int { sx * sy * sz }

    @inline(__always) public func inBounds(_ x: Int, _ y: Int, _ z: Int) -> Bool {
        x >= 0 && y >= 0 && z >= 0 && x < sx && y < sy && z < sz
    }

    /// Storage order: x fastest, then z, then y (one horizontal slice per y).
    @inline(__always) public func index(_ x: Int, _ y: Int, _ z: Int) -> Int {
        (y * sz + z) * sx + x
    }

    public func get(_ layer: Int, _ frame: Int, _ x: Int, _ y: Int, _ z: Int) -> UInt8 {
        guard inBounds(x, y, z) else { return 0 }
        return cels[layer][frame].data[index(x, y, z)]
    }

    public mutating func set(_ layer: Int, _ frame: Int, _ x: Int, _ y: Int, _ z: Int, _ c: UInt8) {
        guard inBounds(x, y, z) else { return }
        cels[layer][frame].data[index(x, y, z)] = c
    }

    /// All visible layers of a frame merged: upper layers cover lower ones.
    public func composite(frame: Int, onlyVisible: Bool = true) -> [UInt8] {
        var out = [UInt8](repeating: 0, count: count)
        for (li, layer) in layers.enumerated() where layer.visible || !onlyVisible {
            cels[li][frame].data.withUnsafeBufferPointer { src in
                out.withUnsafeMutableBufferPointer { dst in
                    for i in 0..<src.count where src[i] != 0 { dst[i] = src[i] }
                }
            }
        }
        return out
    }

    // MARK: structure

    public mutating func resize(_ nx: Int, _ ny: Int, _ nz: Int, anchor: String = "bottom-center") throws {
        try Document.checkSize(nx, ny, nz)
        // Keep the model standing on the ground and centred unless asked otherwise.
        let ox: Int, oz: Int
        if anchor == "origin" { ox = 0; oz = 0 } else { ox = (nx - sx) / 2; oz = (nz - sz) / 2 }
        let old = self
        sx = nx; sy = ny; sz = nz
        for li in 0..<layers.count {
            for fi in 0..<frames.count {
                var g = Grid(count: count)
                for y in 0..<min(old.sy, ny) {
                    for z in 0..<old.sz {
                        for x in 0..<old.sx {
                            let v = old.cels[li][fi].data[old.index(x, y, z)]
                            if v == 0 { continue }
                            let tx = x + ox, tz = z + oz
                            if inBounds(tx, y, tz) { g.data[index(tx, y, tz)] = v }
                        }
                    }
                }
                cels[li][fi] = g
            }
        }
    }

    public static func checkSize(_ x: Int, _ y: Int, _ z: Int) throws {
        for v in [x, y, z] where v < 1 || v > maxSize {
            throw PCError.invalid("each size must be between 1 and \(maxSize) (got \(x)×\(y)×\(z))")
        }
    }

    public mutating func addLayer(name: String, at: Int? = nil) -> Int {
        let i = min(max(at ?? layers.count, 0), layers.count)
        layers.insert(Layer(name: name), at: i)
        cels.insert(Array(repeating: Grid(count: count), count: frames.count), at: i)
        return i
    }

    public mutating func removeLayer(_ i: Int) throws {
        guard layers.count > 1 else { throw PCError.invalid("a model needs at least one layer") }
        layers.remove(at: i); cels.remove(at: i)
    }

    public mutating func addFrame(after: Int, copy: Bool) -> Int {
        let i = after + 1
        frames.insert(Frame(duration: frames[after].duration), at: i)
        for li in 0..<layers.count {
            cels[li].insert(copy ? cels[li][after] : Grid(count: count), at: i)
        }
        return i
    }

    public mutating func removeFrame(_ i: Int) throws {
        guard frames.count > 1 else { throw PCError.invalid("a model needs at least one frame") }
        frames.remove(at: i)
        for li in 0..<layers.count { cels[li].remove(at: i) }
    }
}
