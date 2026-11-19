import Foundation
import OpenPixelCore

/// `OpenPixel --selftest`: exercises the engine and the MCP protocol without a window.
enum SelfTest {
    static func run() -> Bool {
        var ok = true
        func check(_ cond: Bool, _ what: String) {
            print((cond ? "ok   " : "FAIL ") + what)
            if !cond { ok = false }
        }
        let engine = Engine()
        Sample.build(into: engine)
        let info = (try? engine.execute("get_model_info", [:]))?.json ?? [:]
        check((info["voxels_in_active_frame"] as? Int ?? 0) > 500, "sample model has voxels (\(info["voxels_in_active_frame"] ?? 0))")
        check((info["layers"] as? [Any])?.count == 3, "sample has 3 layers")

        _ = try? engine.execute("new_model", ["size_x": 8, "size_y": 8, "size_z": 8])
        let r = try? engine.execute("paint_slice", ["axis": "z", "index": 2, "rows": ["..11..", ".1221.", "112211"], "depth": 2])
        check((r?.json["changed"] as? Int) == 24, "paint_slice extrudes 12 cells × 2 (got \(r?.json["changed"] ?? "nil"))")
        let s = try? engine.execute("get_slice", ["axis": "z", "index": 3])
        let rows = s?.json["rows"] as? [String] ?? []
        check(rows.count == 8 && rows[0] == "..11....", "get_slice reads back the same rows (\(rows.first ?? "-"))")
        _ = try? engine.execute("undo", [:])
        let after = (try? engine.execute("get_model_info", [:]))?.json["voxels_in_active_frame"] as? Int
        check(after == 0, "undo removes the slice")
        _ = try? engine.execute("redo", [:])
        _ = try? engine.execute("fill_box", ["from": [0, 0, 0], "to": [7, 0, 7], "color": "#ff0000"])
        _ = try? engine.execute("draw_sphere", ["center": [4, 5, 4], "radius": 2, "color": 5, "symmetry": "x"])
        let render = try? engine.execute("render_view", ["view": "iso", "scale": 4])
        check((render?.images.first?.count ?? 0) > 100, "render_view returns a PNG")
        let review = try? engine.execute("review_model", [:])
        check(review?.images.count == 1 && review?.json["issues"] != nil, "review_model returns a sheet and checks")
        _ = try? engine.execute("take_snapshot", [:])
        _ = try? engine.execute("set_voxels", ["voxels": [[0, 1, 0, 3]]])
        let diff = try? engine.execute("compare_snapshot", [:])
        check((diff?.json["added"] as? Int) == 1, "compare_snapshot sees one added voxel")

        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("openpixel-selftest-\(getpid())")
        try? FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        let file = tmp.appendingPathComponent("t.openpixel").path
        _ = try? engine.execute("save_model", ["path": file])
        let before = (try? engine.execute("get_model_info", [:]))?.json["voxels_in_active_frame"] as? Int
        _ = try? engine.execute("open_model", ["path": file])
        let reopened = (try? engine.execute("get_model_info", [:]))?.json["voxels_in_active_frame"] as? Int
        check(before != nil && before == reopened, "save and open keep every voxel (\(before ?? -1) = \(reopened ?? -1))")
        let vox = tmp.appendingPathComponent("t.vox").path
        _ = try? engine.execute("export_vox", ["path": vox])
        _ = try? engine.execute("open_model", ["path": vox])
        let fromVox = (try? engine.execute("get_model_info", [:]))?.json["voxels_in_active_frame"] as? Int
        check(fromVox == before, ".vox export and import round-trip (\(fromVox ?? -1))")
        for (tool, ext) in [("export_png", "png"), ("export_sheet", "png"), ("export_gif", "gif"), ("export_obj", "obj"), ("export_svg", "svg"), ("export_html", "html")] {
            let p = tmp.appendingPathComponent("out-\(tool).\(ext)").path
            _ = try? engine.execute(tool, ["path": p])
            check(FileManager.default.fileExists(atPath: p), "\(tool) writes a file")
        }

        // 2D sprites
        let sprite = Engine()
        Sample.build(into: sprite, threeD: false)
        let sInfo = (try? sprite.execute("get_model_info", [:]))?.json ?? [:]
        check(sInfo["kind"] as? String == "2d-sprite" && (sInfo["frames"] as? [Any])?.count == 2, "welcome sprite is 2D with 2 frames")
        _ = try? sprite.execute("set_pixels", ["pixels": [[0, 0, "#ff00ff"]]])
        let top = (try? sprite.execute("get_voxel", ["at": [0, 31, 0]]))?.json["hex"] as? String
        check(top == "#ff00ff", "set_pixels counts y from the top row")
        let png = tmp.appendingPathComponent("sprite.png").path
        try? FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        let exp = try? sprite.execute("export_png", ["path": png])
        check((exp?.json["width"] as? Int) == 32 && (exp?.json["height"] as? Int) == 32, "2D export_png is the sprite pixel for pixel (32×32)")
        if let pic = try? ImageFiles.read(URL(fileURLWithPath: png)) {
            check(pic.pixel(0) == RGBA(255, 0, 255), "exported pixel keeps its exact colour")
        }
        _ = try? sprite.execute("extrude_to_3d", ["depth": 4])
        let ext = (try? sprite.execute("get_model_info", [:]))?.json["size"] as? [Int]
        check(ext == [32, 32, 4], "extrude_to_3d makes the sprite 4 voxels deep")
        try? FileManager.default.removeItem(at: tmp)

        let server = MCPServer { LocalBackend(engine: engine) }
        let initRes = server.handle(#"{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18"}}"#) ?? ""
        check(initRes.contains("\"openpixel\""), "MCP initialize")
        let list = server.handle(#"{"jsonrpc":"2.0","id":2,"method":"tools/list"}"#) ?? ""
        check(list.contains("paint_slice") && !list.contains("ui_state"), "MCP tools/list hides editor-only tools")
        let call = server.handle(#"{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"render_view","arguments":{"view":"front"}}}"#) ?? ""
        check(call.contains("image/png"), "MCP tools/call returns an image")
        let bad = server.handle(#"{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"fill_box","arguments":{"from":[0,0,0]}}}"#) ?? ""
        check(bad.contains("\"isError\":true"), "MCP reports tool errors")
        check(server.handle(#"{"jsonrpc":"2.0","method":"notifications/initialized"}"#) == nil, "MCP ignores notifications")
        // Damaged and hostile files must fail with an error, never crash or read past the data.
        func chunk(_ id: String, _ len: UInt32, _ body: [UInt8]) -> [UInt8] {
            Array(id.utf8) + withUnsafeBytes(of: len.littleEndian, Array.init) + [0, 0, 0, 0] + body
        }
        let header = Array("VOX ".utf8) + [150, 0, 0, 0]
        let hostile: [(String, [UInt8])] = [
            ("truncated SIZE", header + chunk("SIZE", 12, [8, 0, 0, 0])),
            ("chunk longer than file", header + chunk("SIZE", 12, [2, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0]) + chunk("XYZI", 0xFFFF_FFF0, [1, 0, 0, 0])),
            ("huge model size", header + chunk("SIZE", 12, [0, 0, 0, 0x7F, 0, 0, 0, 0x7F, 0, 0, 0, 0x7F])),
            ("zero model size", header + chunk("SIZE", 12, [0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0])),
            ("short palette", header + chunk("SIZE", 12, [4, 0, 0, 0, 4, 0, 0, 0, 4, 0, 0, 0]) + chunk("RGBA", 8, [1, 2, 3, 4, 5, 6, 7, 8])),
            ("only a header", header),
        ]
        for (what, bytes) in hostile {
            check((try? VoxFile.decode(Data(bytes), name: "x")) == nil, ".vox \(what) is refused")
        }
        // Colour 200 with no palette: the voxel stays inside the model but is cleared, not looked up.
        let noPalette = header + chunk("SIZE", 12, [2, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0]) + chunk("XYZI", 8, [1, 0, 0, 0, 1, 1, 1, 200])
        if let d = try? VoxFile.decode(Data(noPalette), name: "x") {
            check(d.cels[0][0].data.allSatisfy { Int($0) < d.palette.count }, ".vox colours past the palette are dropped")
        } else { check(false, ".vox without palette opens") }
        let bigJSON = #"{"format":"openpixel","size":[256,256,256],"frames":[{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{}]}"#
        check((try? NativeFile.decode(Data(bigJSON.utf8))) == nil, ".openpixel asking for too much memory is refused")
        let shortPal = ##"{"format":"openpixel","size":[1,1,1],"palette":["transparent","#ff0000"],"cels":[{"layer":0,"frame":0,"encoding":"zlib-base64","data":"OwEA"}]}"##
        if let d = try? NativeFile.decode(Data(shortPal.utf8)) {
            check(d.cels[0][0].data.allSatisfy { Int($0) < d.palette.count }, ".openpixel colours past the palette are dropped")
        } else { check(false, ".openpixel with a short palette opens") }

        // Agents over HTTP only reach ~/Documents/OpenPixel (here: a test folder).
        let jail = tmp.appendingPathComponent("jail")
        try? FileManager.default.createDirectory(at: jail, withIntermediateDirectories: true)
        try? FileManager.default.createSymbolicLink(atPath: jail.appendingPathComponent("out").path, withDestinationPath: "/tmp")
        check((try? MCPHTTPServer.confine("a.png", root: jail))?.hasSuffix("/jail/a.png") == true, "HTTP paths: relative names land in the folder")
        for escape in ["/etc/hosts", "../escape.png", "~/x.png", "sub/../../x.png", "out/x.png", "out"] {
            check((try? MCPHTTPServer.confine(escape, root: jail)) == nil, "HTTP paths: \(escape) is refused")
        }
        try? FileManager.default.removeItem(at: tmp)
        if let i = CommandLine.arguments.firstIndex(of: "--selftest"), i + 1 < CommandLine.arguments.count {
            // Optional: write pictures of the welcome model into a folder for a visual check.
            let dir = CommandLine.arguments[i + 1]
            let demo = Engine()
            Sample.build(into: demo)
            _ = try? demo.execute("export_png", ["path": dir + "/sample-iso.png", "scale": 6])
            if let r = try? demo.execute("review_model", ["scale": 4]), let png = r.images.first {
                try? png.write(to: URL(fileURLWithPath: dir + "/sample-review.png"))
            }
            _ = try? demo.execute("export_sheet", ["path": dir + "/sample-sheet.png", "scale": 2])
            print("Pictures written to \(dir)")
        }
        print(ok ? "All checks passed." : "Some checks failed.")
        return ok
    }
}
