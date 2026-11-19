import Foundation

/// The welcome model, built with the same tools agents use (so it doubles as an example).
public enum Sample {
    public static let steps: [(String, [String: Any])] = [
        ("new_model", ["size_x": 24, "size_y": 24, "size_z": 24, "name": "Welcome island"]),
        ("set_layer", ["layer": 0, "name": "Ground"]),
        ("fill_box", ["from": [3, 0, 3], "to": [20, 1, 20], "color": "#8f563b"]),
        ("fill_box", ["from": [4, 0, 4], "to": [19, 0, 19], "color": "#663931"]),
        ("fill_box", ["from": [3, 2, 3], "to": [20, 2, 20], "color": "#6abe30"]),
        ("set_voxels", ["voxels": [[3, 2, 3], [20, 2, 3], [3, 2, 20], [20, 2, 20], [3, 1, 3], [20, 1, 3], [3, 1, 20], [20, 1, 20],
                                   [3, 0, 3], [20, 0, 3], [3, 0, 20], [20, 0, 20]], "mode": "erase"]),
        ("set_voxels", ["voxels": [[5, 3, 15, "#9badb7"], [6, 3, 15, "#847e87"], [5, 3, 16, "#847e87"], [18, 3, 5, "#9badb7"],
                                   [4, 2, 12, "#99e550"], [9, 2, 19, "#99e550"], [16, 2, 4, "#99e550"]]]),
        ("add_layer", ["name": "Tree"]),
        ("draw_cylinder", ["base": [7, 3, 8], "radius": 1, "length": 7, "color": "#663931"]),
        ("draw_sphere", ["center": [7, 12, 8], "radius": [4, 3.5, 4], "color": "#37946e"]),
        ("draw_sphere", ["center": [6, 13, 7], "radius": [3, 2.5, 3], "color": "#6abe30", "mode": "paint"]),
        ("draw_sphere", ["center": [5.5, 14, 6.5], "radius": 1.5, "color": "#99e550", "mode": "paint"]),
        ("add_layer", ["name": "House"]),
        ("fill_box", ["from": [11, 3, 10], "to": [18, 8, 17], "color": "#eec39a"]),
        ("fill_box", ["from": [11, 3, 10], "to": [11, 8, 10], "color": "#d9a066"]),
        ("fill_box", ["from": [18, 3, 10], "to": [18, 8, 10], "color": "#d9a066"]),
        ("fill_box", ["from": [11, 3, 17], "to": [11, 8, 17], "color": "#d9a066"]),
        ("fill_box", ["from": [18, 3, 17], "to": [18, 8, 17], "color": "#d9a066"]),
        ("fill_box", ["from": [10, 9, 9], "to": [19, 9, 18], "color": "#ac3232"]),
        ("fill_box", ["from": [11, 10, 9], "to": [18, 10, 18], "color": "#ac3232"]),
        ("fill_box", ["from": [12, 11, 9], "to": [17, 11, 18], "color": "#d95763"]),
        ("fill_box", ["from": [13, 12, 9], "to": [16, 12, 18], "color": "#d95763"]),
        ("fill_box", ["from": [14, 13, 9], "to": [15, 13, 18], "color": "#d95763"]),
        ("fill_box", ["from": [14, 3, 17], "to": [15, 5, 17], "color": "#663931"]),
        ("set_voxels", ["voxels": [[12, 6, 17, "#5fcde4"], [17, 6, 17, "#5fcde4"], [18, 6, 13, "#5fcde4"], [18, 6, 14, "#5fcde4"],
                                   [15, 4, 17, "#fbf236"]]]),
        ("fill_box", ["from": [16, 12, 12], "to": [16, 14, 12], "color": "#595652"]),
        ("set_active", ["layer": 2, "frame": 0]),
    ]

    /// The welcome sprite: a flat 32×32 canvas (the usual new-sprite size)
    /// with a two-frame blink animation, drawn with paint_slice text rows.
    public static let sprite: [(String, [String: Any])] = [
        ("new_sprite", ["width": 32, "height": 32, "name": "Mushroom"]),
        ("paint_slice", ["axis": "z", "index": 0, "offset": [0, 4],
                         "legend": ["o": "#222034", "R": "#d95763", "D": "#ac3232", "W": "#ffffff", "S": "#eec39a",
                                    "s": "#d9a066", "E": "#222034", "P": "#d77bba"],
                         "rows": [
                            "..........oooooooooooo..........",
                            ".......oooRRRRWWWRRRRRooo.......",
                            ".....ooRRRRRRWWWWWRRRRRRRoo.....",
                            "....oRRWWWRRRRWWWRRRRRWWRRRo....",
                            "...oRRWWWWWRRRRRRRRRRWWWWRRRo...",
                            "..oRRRWWWWWRRRRRRRRRRWWWWWRRRo..",
                            "..oRRRRWWWRRRRRRWWRRRRWWWRRRRo..",
                            ".oRRRRRRRRRRRRRWWWWRRRRRRRRRRRo.",
                            ".oDRRRRRRRRRRRRWWWWRRRRRRRRRRDo.",
                            ".oDDRRRWWRRRRRRRWWRRRRRRRRRRDDo.",
                            ".oDDDRWWWWRRRRRRRRRRRRWWRRRDDDo.",
                            "..oDDDDWWRRRRRRRRRRRRRRRRDDDDo..",
                            "...ooDDDDDDDDDDDDDDDDDDDDDDoo...",
                            ".....oooooooooooooooooooooo.....",
                            ".........oSSSSSSSSSSSso.........",
                            ".........oSSSSSSSSSSSso.........",
                            ".........oSSEESSSSEESso.........",
                            ".........oSSEESSSSEESso.........",
                            ".........oPPSSSSSSSSPPo.........",
                            ".........oSSSSSooSSSSso.........",
                            ".........osSSSSSSSSSSso.........",
                            ".........ossSSSSSSSSsso.........",
                            "..........osssssssssso..........",
                            "...........oooooooooo...........",
                         ]]),
        ("set_frame_duration", ["frame": 0, "duration_ms": 1200]),
        ("add_frame", ["after": 0, "copy": true]),
        ("set_pixels", ["frame": 1, "pixels": [[12, 20], [13, 20], [18, 20], [19, 20]], "color": "#eec39a"]),
        ("set_frame_duration", ["frame": 1, "duration_ms": 150]),
        ("set_active", ["layer": 0, "frame": 0]),
    ]

    public static func build(into engine: Engine, threeD: Bool = true) {
        for (tool, args) in (threeD ? steps : sprite) { _ = try? engine.execute(tool, args, source: "sample") }
        engine.markClean()
    }

    /// Runs the 3D sample as normal, undoable edits (Help menu).
    public static func open3D(in engine: Engine) {
        for (tool, args) in steps { _ = try? engine.execute(tool, args, source: "sample") }
    }
}

extension Engine {
    /// Forget history and the unsaved flag (used for the welcome model).
    public func markClean() {
        undoStack.removeAll(); redoStack.removeAll(); dirty = false
    }
}
