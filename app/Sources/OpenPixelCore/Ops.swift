import Foundation

/// How a drawing operation treats voxels it touches.
public enum PaintMode: String {
    case replace   // place the colour everywhere it draws
    case paint     // only recolour voxels that already exist
    case add       // only fill empty cells
    case erase     // remove voxels
}

/// Mirror drawing across the model's centre (symmetry mode, in 3 axes).
public struct Symmetry: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let x = Symmetry(rawValue: 1)
    public static let y = Symmetry(rawValue: 2)
    public static let z = Symmetry(rawValue: 4)

    public static func parse(_ s: String?) -> Symmetry {
        var m: Symmetry = []
        for ch in (s ?? "").lowercased() {
            if ch == "x" { m.insert(.x) } else if ch == "y" { m.insert(.y) } else if ch == "z" { m.insert(.z) }
        }
        return m
    }
}

/// A drawing pen bound to one cel (layer + frame).
public struct Pen {
    public var layer: Int
    public var frame: Int
    public var color: UInt8
    public var mode: PaintMode = .replace
    public var symmetry: Symmetry = []
    public init(layer: Int, frame: Int, color: UInt8, mode: PaintMode = .replace, symmetry: Symmetry = []) {
        self.layer = layer; self.frame = frame; self.color = color; self.mode = mode; self.symmetry = symmetry
    }
}

extension Document {
    /// Writes one voxel through the pen (with its mode and symmetry). Returns how many cells changed.
    @discardableResult
    public mutating func put(_ x: Int, _ y: Int, _ z: Int, _ pen: Pen) -> Int {
        var changed = 0
        let xs = pen.symmetry.contains(.x) ? Set([x, sx - 1 - x]) : [x]
        let ys = pen.symmetry.contains(.y) ? Set([y, sy - 1 - y]) : [y]
        let zs = pen.symmetry.contains(.z) ? Set([z, sz - 1 - z]) : [z]
        for px in xs { for py in ys { for pz in zs { changed += putOne(px, py, pz, pen) } } }
        return changed
    }

    @inline(__always)
    mutating func putOne(_ x: Int, _ y: Int, _ z: Int, _ pen: Pen) -> Int {
        guard inBounds(x, y, z) else { return 0 }
        let i = index(x, y, z)
        let old = cels[pen.layer][pen.frame].data[i]
        let new: UInt8
        switch pen.mode {
        case .replace: new = pen.color
        case .paint: if old == 0 { return 0 }; new = pen.color
        case .add: if old != 0 { return 0 }; new = pen.color
        case .erase: new = 0
        }
        if old == new { return 0 }
        cels[pen.layer][pen.frame].data[i] = new
        return 1
    }

    public mutating func box(_ a: (Int, Int, Int), _ b: (Int, Int, Int), hollow: Bool, _ pen: Pen) -> Int {
        let x0 = min(a.0, b.0), x1 = max(a.0, b.0)
        let y0 = min(a.1, b.1), y1 = max(a.1, b.1)
        let z0 = min(a.2, b.2), z1 = max(a.2, b.2)
        var n = 0
        for y in stride(from: max(y0, 0), through: min(y1, sy - 1), by: 1) {
            for z in stride(from: max(z0, 0), through: min(z1, sz - 1), by: 1) {
                for x in stride(from: max(x0, 0), through: min(x1, sx - 1), by: 1) {
                    if hollow && x != x0 && x != x1 && y != y0 && y != y1 && z != z0 && z != z1 { continue }
                    n += put(x, y, z, pen)
                }
            }
        }
        return n
    }

    /// Ellipsoid centred at c (may be fractional) with radii r.
    public mutating func ellipsoid(center c: (Double, Double, Double), radii r: (Double, Double, Double),
                                   hollow: Bool, _ pen: Pen) -> Int {
        let rx = max(r.0, 0.5), ry = max(r.1, 0.5), rz = max(r.2, 0.5)
        var n = 0
        let inside: (Double, Double, Double) -> Bool = { x, y, z in
            let dx = (x - c.0) / rx, dy = (y - c.1) / ry, dz = (z - c.2) / rz
            return dx * dx + dy * dy + dz * dz <= 1.0 + 1e-9
        }
        for y in Int((c.1 - ry).rounded(.down))...Int((c.1 + ry).rounded(.up)) {
            for z in Int((c.2 - rz).rounded(.down))...Int((c.2 + rz).rounded(.up)) {
                for x in Int((c.0 - rx).rounded(.down))...Int((c.0 + rx).rounded(.up)) {
                    let fx = Double(x), fy = Double(y), fz = Double(z)
                    guard inside(fx, fy, fz) else { continue }
                    if hollow && inside(fx + 1, fy, fz) && inside(fx - 1, fy, fz) && inside(fx, fy + 1, fz)
                        && inside(fx, fy - 1, fz) && inside(fx, fy, fz + 1) && inside(fx, fy, fz - 1) { continue }
                    n += put(x, y, z, pen)
                }
            }
        }
        return n
    }

    /// Cylinder along an axis: base centre, radius, length along the axis.
    public mutating func cylinder(base: (Double, Double, Double), radius: Double, length: Int, axis: String,
                                  hollow: Bool, _ pen: Pen) -> Int {
        var n = 0
        let r = max(radius, 0.5)
        let ri = Int(r.rounded(.up))
        let inside: (Double, Double) -> Bool = { a, b in a * a + b * b <= r * r + 1e-9 }
        for t in 0..<max(length, 1) {
            for a in -ri...ri {
                for b in -ri...ri {
                    let da = Double(a), db = Double(b)
                    guard inside(da, db) else { continue }
                    let edge = !(inside(da + 1, db) && inside(da - 1, db) && inside(da, db + 1) && inside(da, db - 1))
                    if hollow && !edge && t != 0 && t != length - 1 { continue }
                    let x: Int, y: Int, z: Int
                    switch axis {
                    case "x": x = Int(base.0) + t; y = Int((base.1 + da).rounded()); z = Int((base.2 + db).rounded())
                    case "z": x = Int((base.0 + da).rounded()); y = Int((base.1 + db).rounded()); z = Int(base.2) + t
                    default: x = Int((base.0 + da).rounded()); y = Int(base.1) + t; z = Int((base.2 + db).rounded())
                    }
                    n += put(x, y, z, pen)
                }
            }
        }
        return n
    }

    /// 3D line (DDA through the larger axis) with an optional cube brush radius.
    public mutating func line(_ a: (Int, Int, Int), _ b: (Int, Int, Int), radius: Int, _ pen: Pen) -> Int {
        let dx = b.0 - a.0, dy = b.1 - a.1, dz = b.2 - a.2
        let steps = max(abs(dx), abs(dy), abs(dz), 1)
        var n = 0
        for i in 0...steps {
            let t = Double(i) / Double(steps)
            let x = Int((Double(a.0) + Double(dx) * t).rounded())
            let y = Int((Double(a.1) + Double(dy) * t).rounded())
            let z = Int((Double(a.2) + Double(dz) * t).rounded())
            if radius <= 0 { n += put(x, y, z, pen); continue }
            for oy in -radius...radius { for oz in -radius...radius { for ox in -radius...radius {
                if ox * ox + oy * oy + oz * oz <= radius * radius { n += put(x + ox, y + oy, z + oz, pen) }
            } } }
        }
        return n
    }

    /// 6-connected flood fill of the region that has the same value as the start cell.
    /// When the start is empty, the fill is limited to the start's horizontal slice (like a 2D bucket)
    /// unless `volume` is true.
    public mutating func floodFill(_ s: (Int, Int, Int), volume: Bool, _ pen: Pen) -> Int {
        guard inBounds(s.0, s.1, s.2) else { return 0 }
        let target = get(pen.layer, pen.frame, s.0, s.1, s.2)
        let replacement: UInt8 = pen.mode == .erase ? 0 : pen.color
        if target == replacement { return 0 }
        let flat = target == 0 && !volume
        var seen = [Bool](repeating: false, count: count)
        var stack = [(s.0, s.1, s.2)]
        var cells: [(Int, Int, Int)] = []
        seen[index(s.0, s.1, s.2)] = true
        while let (x, y, z) = stack.popLast() {
            cells.append((x, y, z))
            let nbs = flat ? [(x+1,y,z),(x-1,y,z),(x,y,z+1),(x,y,z-1)]
                           : [(x+1,y,z),(x-1,y,z),(x,y+1,z),(x,y-1,z),(x,y,z+1),(x,y,z-1)]
            for (nx, ny, nz) in nbs where inBounds(nx, ny, nz) {
                let i = index(nx, ny, nz)
                if !seen[i] && cels[pen.layer][pen.frame].data[i] == target { seen[i] = true; stack.append((nx, ny, nz)) }
            }
        }
        var p = pen; p.mode = pen.mode == .erase ? .erase : .replace; p.symmetry = []
        var n = 0
        for (x, y, z) in cells { n += put(x, y, z, p) }
        return n
    }

    public mutating func replaceColor(layer: Int, frame: Int, from: UInt8, to: UInt8) -> Int {
        var n = 0
        for i in 0..<count where cels[layer][frame].data[i] == from { cels[layer][frame].data[i] = to; n += 1 }
        return n
    }

    /// Moves every voxel of a cel; voxels pushed outside are lost (or wrap when asked).
    public mutating func translate(layer: Int, frame: Int, dx: Int, dy: Int, dz: Int, wrap: Bool) {
        let old = cels[layer][frame]
        var g = Grid(count: count)
        for y in 0..<sy { for z in 0..<sz { for x in 0..<sx {
            let v = old.data[index(x, y, z)]
            if v == 0 { continue }
            var nx = x + dx, ny = y + dy, nz = z + dz
            if wrap { nx = ((nx % sx) + sx) % sx; ny = ((ny % sy) + sy) % sy; nz = ((nz % sz) + sz) % sz }
            if inBounds(nx, ny, nz) { g.data[index(nx, ny, nz)] = v }
        } } }
        cels[layer][frame] = g
    }

    public mutating func flip(layer: Int, frame: Int, axis: String) {
        let old = cels[layer][frame]
        var g = Grid(count: count)
        for y in 0..<sy { for z in 0..<sz { for x in 0..<sx {
            let v = old.data[index(x, y, z)]
            if v == 0 { continue }
            switch axis {
            case "x": g.data[index(sx - 1 - x, y, z)] = v
            case "y": g.data[index(x, sy - 1 - y, z)] = v
            default: g.data[index(x, y, sz - 1 - z)] = v
            }
        } } }
        cels[layer][frame] = g
    }

    /// Copies one half onto the other, across the centre plane of an axis.
    /// `keep` = "low" keeps the low side (x<mid, left / bottom / back) and mirrors it to the high side.
    public mutating func mirror(layer: Int, frame: Int, axis: String, keep: String) {
        let lowKept = keep != "high"
        for y in 0..<sy { for z in 0..<sz { for x in 0..<sx {
            let (mx, my, mz): (Int, Int, Int)
            let isLow: Bool
            switch axis {
            case "x": (mx, my, mz) = (sx - 1 - x, y, z); isLow = x < sx - 1 - x
            case "y": (mx, my, mz) = (x, sy - 1 - y, z); isLow = y < sy - 1 - y
            default: (mx, my, mz) = (x, y, sz - 1 - z); isLow = z < sz - 1 - z
            }
            if isLow == lowKept && (mx, my, mz) != (x, y, z) {
                cels[layer][frame].data[index(mx, my, mz)] = cels[layer][frame].data[index(x, y, z)]
            }
        } } }
    }

    /// Rotates a cel by quarter turns around an axis through the model's centre.
    /// Cells that land outside the box are dropped (use a cube-shaped model to keep everything).
    public mutating func rotate(layer: Int, frame: Int, axis: String, turns: Int) {
        let t = ((turns % 4) + 4) % 4
        if t == 0 { return }
        for _ in 0..<t {
            let old = cels[layer][frame]
            var g = Grid(count: count)
            let cx = Double(sx - 1) / 2, cy = Double(sy - 1) / 2, cz = Double(sz - 1) / 2
            for y in 0..<sy { for z in 0..<sz { for x in 0..<sx {
                let v = old.data[index(x, y, z)]
                if v == 0 { continue }
                let px = Double(x) - cx, py = Double(y) - cy, pz = Double(z) - cz
                var nx = px, ny = py, nz = pz
                // Counter-clockwise when looking from the positive end of the axis.
                switch axis {
                case "x": ny = -pz; nz = py
                case "z": nx = -py; ny = px
                default: nx = pz; nz = -px
                }
                let ix = Int((nx + cx).rounded()), iy = Int((ny + cy).rounded()), iz = Int((nz + cz).rounded())
                if inBounds(ix, iy, iz) { g.data[index(ix, iy, iz)] = v }
            } } }
            cels[layer][frame] = g
        }
    }

    /// Recolours existing voxels along an axis using a ramp of palette indexes (low end → high end).
    public mutating func gradient(layer: Int, frame: Int, axis: String, ramp: [UInt8], onlyColor: UInt8?) -> Int {
        guard !ramp.isEmpty else { return 0 }
        let len = axis == "x" ? sx : axis == "z" ? sz : sy
        var n = 0
        for y in 0..<sy { for z in 0..<sz { for x in 0..<sx {
            let i = index(x, y, z)
            let v = cels[layer][frame].data[i]
            if v == 0 { continue }
            if let only = onlyColor, v != only { continue }
            let p = axis == "x" ? x : axis == "z" ? z : y
            let k = len <= 1 ? 0 : min(ramp.count - 1, p * ramp.count / len)
            if ramp[k] != v { cels[layer][frame].data[i] = ramp[k]; n += 1 }
        } } }
        return n
    }

    // MARK: slices (2D views agents can read and write as text)

    /// Maps a slice (axis, depth index) + 2D (column, row) into a 3D cell.
    /// - axis "y": a horizontal layer seen from above; columns = x, rows = z from back (0) to front.
    /// - axis "z": a vertical slice seen from the front; columns = x, rows = y from top to bottom.
    /// - axis "x": a vertical slice seen from the side; columns = z from back to front, rows = y from top to bottom.
    public func sliceCell(axis: String, index k: Int, col: Int, row: Int) -> (Int, Int, Int) {
        switch axis {
        case "y": return (col, k, row)
        case "x": return (k, sy - 1 - row, col)
        default: return (col, sy - 1 - row, k)
        }
    }

    public func sliceSize(axis: String) -> (cols: Int, rows: Int, depth: Int) {
        switch axis {
        case "y": return (sx, sz, sy)
        case "x": return (sz, sy, sx)
        default: return (sx, sy, sz)
        }
    }
}
