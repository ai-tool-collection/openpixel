import Foundation
import OpenPixelCore

/// `OpenPixel --mcp`: forwards every tool call to the open window when there is one (so the person sees
/// the agent's work live), and otherwise runs it on an in-process model.
enum MCPMode {
    static func run(headless: Bool, httpPort: UInt16? = nil, httpToken: String? = nil) {
        // Keep stdout for protocol messages only.
        setvbuf(stdout, nil, _IOLBF, 0)
        let local = LocalBackend(engine: Engine(doc: Document(name: "Untitled")))
        var remote: RemoteBackend?
        var server: MCPServer!
        var transport = "stdio"
        // Every new link to the window starts by saying which agent this is, so the Agents page can show it.
        func connect() -> RemoteBackend? {
            guard !headless, let r = RemoteBackend() else { return nil }
            var info = server.clientInfo
            info["pid"] = Int(getpid()); info["transport"] = transport
            r.hello(info)
            return r.broken ? nil : r
        }
        server = MCPServer {
            if headless { return local }
            if let r = remote, !r.broken { return r }
            remote = connect()
            if let r = remote { return r }
            return local
        }
        server.onInitialize = { _ in if remote == nil || remote!.broken { remote = connect() } }
        if let port = httpPort {
            let http = MCPHTTPServer(server: server, port: port, token: httpToken)
            // A tunnel can make this reachable from anywhere: keep file access to OpenPixel's own folder.
            server.pathPolicy = { try MCPHTTPServer.confine($0) }
            do { try http.start() } catch {
                FileHandle.standardError.write("Could not listen on port \(port): \(error)\n".data(using: .utf8)!)
                exit(1)
            }
            // Agents reached over HTTP are told apart from stdio ones on the Agents page.
            transport = "http"
            print("""
            OpenPixel MCP server \(MCPServer.version) on this computer only:
              \(http.localURL)
            To use it from ChatGPT, expose port \(port) with a tunnel (for example `cloudflared tunnel --url http://127.0.0.1:\(port)`)
            and add  https://<your-tunnel-address>\(http.path)  as a connector. Keep the address private: anyone with it can edit.
            Agents on this connection can only open and save files in \(MCPHTTPServer.filesFolder.path).
            """)
            dispatchMain()
        }
        FileHandle.standardError.write("OpenPixel MCP server \(MCPServer.version) ready (\(headless ? "headless" : "window when open, else headless")).\n".data(using: .utf8)!)
        server.runStdio()
    }
}
