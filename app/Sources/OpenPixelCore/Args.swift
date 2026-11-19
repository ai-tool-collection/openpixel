import Foundation

/// Lenient reader for tool arguments coming from JSON (agents send numbers as Int or Double, points as
/// [x,y,z] or {"x":..}).
public struct Args {
    public let d: [String: Any]
    public init(_ d: [String: Any]) { self.d = d }

    public func has(_ k: String) -> Bool { d[k] != nil && !(d[k] is NSNull) }

    public func int(_ k: String) -> Int? {
        switch d[k] {
        case let v as Int: return v
        case let v as Double: return Int(v.rounded())
        case let v as NSNumber: return v.intValue
        case let v as String: return Int(v)
        default: return nil
        }
    }
    public func int(_ k: String, _ def: Int) -> Int { int(k) ?? def }
    public func req(_ k: String) throws -> Int {
        guard let v = int(k) else { throw PCError.invalid("missing number '\(k)'") }
        return v
    }

    public func double(_ k: String) -> Double? {
        switch d[k] {
        case let v as Double: return v
        case let v as Int: return Double(v)
        case let v as NSNumber: return v.doubleValue
        case let v as String: return Double(v)
        default: return nil
        }
    }

    public func string(_ k: String) -> String? { d[k] as? String }
    public func reqString(_ k: String) throws -> String {
        guard let v = string(k), !v.isEmpty else { throw PCError.invalid("missing text '\(k)'") }
        return v
    }

    public func bool(_ k: String, _ def: Bool) -> Bool {
        switch d[k] {
        case let v as Bool: return v
        case let v as NSNumber: return v.boolValue
        case let v as String: return ["true", "yes", "1"].contains(v.lowercased())
        default: return def
        }
    }

    public static func number(_ v: Any?) -> Double? {
        switch v {
        case let v as Double: return v
        case let v as Int: return Double(v)
        case let v as NSNumber: return v.doubleValue
        case let v as String: return Double(v)
        default: return nil
        }
    }

    public func point(_ k: String) -> (Double, Double, Double)? { Args.point(d[k]) }

    public static func point(_ v: Any?) -> (Double, Double, Double)? {
        if let a = v as? [Any], a.count >= 3, let x = number(a[0]), let y = number(a[1]), let z = number(a[2]) {
            return (x, y, z)
        }
        if let o = v as? [String: Any], let x = number(o["x"]), let y = number(o["y"]), let z = number(o["z"]) {
            return (x, y, z)
        }
        return nil
    }

    public func reqPoint(_ k: String) throws -> (Int, Int, Int) {
        guard let p = point(k) else { throw PCError.invalid("missing point '\(k)' as [x, y, z]") }
        return (Int(p.0.rounded()), Int(p.1.rounded()), Int(p.2.rounded()))
    }

    public func array(_ k: String) -> [Any]? { d[k] as? [Any] }
}
