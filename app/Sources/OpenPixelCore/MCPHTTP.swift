import Foundation
import Network

/// MCP over HTTP ("streamable HTTP" with plain JSON replies) for agents that can't start a local program,
/// such as ChatGPT connectors. It listens on this computer only (127.0.0.1); to reach it from the internet
/// the person runs a tunnel of their choice. The endpoint path holds a random secret, so only someone who has
/// the full address can use it.
public final class MCPHTTPServer {
    let mcp: MCPServer
    let port: UInt16
    public let token: String
    let queue = DispatchQueue(label: "openpixel.mcp-http")
    var listener: NWListener?
    var sessionID = UUID().uuidString

    public init(server: MCPServer, port: UInt16, token: String? = nil) {
        mcp = server
        self.port = port
        self.token = token ?? (0..<3).map { _ in String(format: "%08x", UInt32.random(in: 0...UInt32.max)) }.joined()
    }

    public var path: String { "/mcp/\(token)" }

    /// The only folder HTTP agents may read or write: ~/Documents/OpenPixel.
    public static var filesFolder: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("OpenPixel", isDirectory: true)
    }

    /// Maps a path from an HTTP agent into `filesFolder` (relative paths are taken from there) and refuses
    /// anything that ends up outside it, including through `..` or symbolic links.
    public static func confine(_ raw: String, root folder: URL = filesFolder) throws -> String {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let root = folder.resolvingSymlinksInPath().standardizedFileURL.path
        let expanded = NSString(string: raw).expandingTildeInPath
        let u = (expanded.hasPrefix("/") ? URL(fileURLWithPath: expanded) : URL(fileURLWithPath: root).appendingPathComponent(expanded))
            .standardizedFileURL
        let resolved = u.deletingLastPathComponent().resolvingSymlinksInPath().appendingPathComponent(u.lastPathComponent).path
        var isLink = false
        if let type = try? FileManager.default.attributesOfItem(atPath: resolved)[.type] as? FileAttributeType { isLink = type == .typeSymbolicLink }
        guard resolved.hasPrefix(root + "/"), !isLink else {
            throw PCError.invalid("over HTTP, files must be inside \(root) (got \(raw))")
        }
        return resolved
    }

    /// Compares without stopping at the first difference, so response timing doesn't reveal the token.
    static func sameSecret(_ a: String, _ b: String) -> Bool {
        let x = Array(a.utf8), y = Array(b.utf8)
        guard x.count == y.count else { return false }
        var diff: UInt8 = 0
        for i in 0..<x.count { diff |= x[i] ^ y[i] }
        return diff == 0
    }
    public var localURL: String { "http://127.0.0.1:\(port)\(path)" }

    public func start() throws {
        let params = NWParameters.tcp
        params.requiredInterfaceType = .loopback
        params.allowLocalEndpointReuse = true
        guard let p = NWEndpoint.Port(rawValue: port) else { throw PCError.invalid("bad port \(port)") }
        let l = try NWListener(using: params, on: p)
        l.newConnectionHandler = { [weak self] c in self?.serve(c) }
        l.start(queue: queue)
        listener = l
    }

    func serve(_ c: NWConnection) {
        c.start(queue: queue)
        receive(c, Data())
    }

    func receive(_ c: NWConnection, _ buffer: Data) {
        c.receive(minimumIncompleteLength: 1, maximumLength: 1 << 20) { [weak self] data, _, done, error in
            guard let self else { return }
            var buf = buffer
            if let d = data { buf.append(d) }
            if let (head, body, complete) = Self.parse(buf), complete {
                self.respond(c, head, body)
            } else if done || error != nil || buf.count > 32 << 20 {
                c.cancel()
            } else {
                self.receive(c, buf)
            }
        }
    }

    /// Splits a request into its head and body once the whole body has arrived.
    static func parse(_ buf: Data) -> (String, Data, Bool)? {
        guard let r = buf.range(of: Data("\r\n\r\n".utf8)) else { return nil }
        let head = String(decoding: buf[..<r.lowerBound], as: UTF8.self)
        let body = buf[r.upperBound...]
        var length = 0
        for line in head.split(separator: "\r\n") {
            let parts = line.split(separator: ":", maxSplits: 1)
            if parts.count == 2, parts[0].lowercased() == "content-length" { length = Int(parts[1].trimmingCharacters(in: .whitespaces)) ?? 0 }
        }
        return (head, Data(body.prefix(length)), body.count >= length)
    }

    func respond(_ c: NWConnection, _ head: String, _ body: Data) {
        let first = head.split(separator: "\r\n").first.map(String.init) ?? ""
        let parts = first.split(separator: " ")
        let method = parts.first.map(String.init) ?? ""
        let target = parts.count > 1 ? String(parts[1]).components(separatedBy: "?")[0] : ""
        guard Self.sameSecret(target, path) else { return send(c, 404, "{\"error\":\"not found\"}") }
        switch method {
        case "POST":
            let text = String(decoding: body, as: UTF8.self)
            var replies: [String] = []
            if text.trimmingCharacters(in: .whitespaces).hasPrefix("[") {
                // A batch: answer each request in it.
                let items = (try? JSONSerialization.jsonObject(with: body) as? [Any]) ?? []
                for item in items {
                    if let d = try? JSONSerialization.data(withJSONObject: item), let r = mcp.handle(String(decoding: d, as: UTF8.self)) { replies.append(r) }
                }
                if replies.isEmpty { return send(c, 202, "") }
                return send(c, 200, "[" + replies.joined(separator: ",") + "]")
            }
            guard let r = mcp.handle(text) else { return send(c, 202, "") }
            send(c, 200, r)
        case "DELETE":
            sessionID = UUID().uuidString
            send(c, 200, "")
        default:
            send(c, 405, "{\"error\":\"use POST\"}", extra: "Allow: POST, DELETE\r\n")
        }
    }

    func send(_ c: NWConnection, _ status: Int, _ body: String, extra: String = "") {
        let reason = [200: "OK", 202: "Accepted", 404: "Not Found", 405: "Method Not Allowed"][status] ?? "OK"
        let bytes = Data(body.utf8)
        var head = "HTTP/1.1 \(status) \(reason)\r\nContent-Length: \(bytes.count)\r\nConnection: close\r\nMcp-Session-Id: \(sessionID)\r\n" + extra
        if !body.isEmpty { head += "Content-Type: application/json\r\n" }
        head += "\r\n"
        c.send(content: Data(head.utf8) + bytes, completion: .contentProcessed { _ in c.cancel() })
    }
}
