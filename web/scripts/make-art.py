#!/usr/bin/env python3
"""Draws the website's pixel art with OpenPixel itself.

Starts `OpenPixel --mcp --headless` and talks MCP to it, exactly like an AI agent would: new_sprite, paint_slice,
add_frame, extrude_to_3d, draw_sphere, export_sheet… The sprites are described below as text rows (some drawn by
hand, some generated), and every picture on the site is exported by OpenPixel.

    python3 web/scripts/make-art.py            (build the app first: cd app && make)

Writes web/public/art/*.png and web/src/lib/art.ts (frame counts and sizes for the <Sprite> component).
"""
import json
import math
import os
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
APP = os.path.join(ROOT, "app", "OpenPixel.app", "Contents", "MacOS", "OpenPixel")
OUT = os.path.join(ROOT, "web", "public", "art")
MANIFEST = os.path.join(ROOT, "web", "src", "lib", "art.ts")
CHEST = os.path.join(ROOT, "web", "scripts", "treasure-chest.openpixel")


class Agent:
    """A minimal MCP client over stdio."""

    def __init__(self):
        self.p = subprocess.Popen([APP, "--mcp", "--headless"], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                  stderr=subprocess.DEVNULL, text=True, bufsize=1)
        self.n = 0
        self.rpc("initialize", {"protocolVersion": "2025-06-18", "clientInfo": {"name": "openpixel-website", "version": "1"}})
        self.p.stdin.write(json.dumps({"jsonrpc": "2.0", "method": "notifications/initialized"}) + "\n")

    def rpc(self, method, params):
        self.n += 1
        self.p.stdin.write(json.dumps({"jsonrpc": "2.0", "id": self.n, "method": method, "params": params}) + "\n")
        self.p.stdin.flush()
        reply = json.loads(self.p.stdout.readline())
        if "error" in reply:
            raise RuntimeError(f"{method}: {reply['error']}")
        return reply["result"]

    def call(self, tool, **args):
        r = self.rpc("tools/call", {"name": tool, "arguments": args})
        text = next((c["text"] for c in r["content"] if c["type"] == "text"), "{}")
        if r.get("isError"):
            raise RuntimeError(f"{tool}: {text}")
        try:
            return json.loads(text)
        except json.JSONDecodeError:
            return text

    def close(self):
        self.p.stdin.close()
        self.p.wait(timeout=10)


# ---------------------------------------------------------------- palette (Endesga 32 + the OpenPixel orange)

C = {
    "ink": "#181425", "navy": "#262b44", "slate": "#3a4466", "steel": "#5a6988", "fog": "#8b9bb4", "mist": "#c0cbdc",
    "white": "#ffffff", "pine": "#193c3e", "forest": "#265c42", "leaf": "#3e8948", "grass": "#63c74d",
    "rust": "#be4a2f", "orange": "#f77622", "gold": "#feae34", "sun": "#fee761", "bark": "#733e39",
    "wood": "#b86f50", "sand": "#e4a672", "plum": "#3e2731", "red": "#e43b44", "wine": "#a22633",
    "pink": "#f6757a", "sky": "#0099db", "cyan": "#2ce8f5", "deep": "#124e89", "accent": "#ff4a1c",
    "ember": "#733e39",
}


def grid(w, h):
    return [["." for _ in range(w)] for _ in range(h)]


def rows(g):
    return ["".join(r) for r in g]


def outline(g, key="o"):
    """Turns the edge pixels of every shape into outline pixels."""
    h, w = len(g), len(g[0])
    edge = []
    for y in range(h):
        for x in range(w):
            if g[y][x] == ".":
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if not (0 <= nx < w and 0 <= ny < h) or g[ny][nx] == ".":
                    edge.append((x, y))
                    break
    for x, y in edge:
        g[y][x] = key
    return g


# ---------------------------------------------------------------- sprites

def slime_frames():
    """A bouncing slime: squash, stretch, jump, land."""
    legend = {"o": C["pine"], "d": C["forest"], "g": C["leaf"], "l": C["grass"], "h": "#a6e15a", "k": C["ink"], "w": C["white"]}
    poses = [(14, 9, 0), (16, 7, 0), (12, 11, 1), (11, 12, 4), (12, 11, 2), (16, 7, 0)]
    frames = []
    for w, h, lift in poses:
        g = grid(20, 20)
        base, cx = 19 - lift, 9.5
        for y in range(base - h + 1, base + 1):
            up = (base - y + 0.5) / h
            hw = (w / 2) * max(0.0, 1 - up ** 2.4) ** (1 / 2.4)
            for x in range(20):
                if abs(x + 0.5 - cx) <= hw:
                    t = (x + 0.5 - (cx - hw)) / max(1, 2 * hw)
                    g[y][x] = "l" if (t < 0.35 and up > 0.55) else ("d" if (t > 0.78 or up < 0.18) else "g")
        outline(g)
        top = base - h + 1
        # Shine and eyes
        if top + 2 <= base:
            g[top + 2][int(cx - w * 0.22)] = "h"
            g[top + 2][int(cx - w * 0.22) + 1] = "h"
        ey = base - int(h * 0.45)
        for ex in (int(cx - w * 0.2), int(cx + w * 0.2) - 1):
            g[ey][ex] = "w"
            g[ey + 1][ex] = "k"
        frames.append(rows(g))
    return 20, 20, legend, frames, 110


def coin_frames():
    """A spinning gold coin."""
    legend = {"o": C["plum"], "r": C["orange"], "f": C["gold"], "s": C["sun"], "e": C["rust"]}
    frames = []
    for i in range(8):
        a = i / 8 * math.pi
        w = max(2, round(14 * abs(math.cos(a))))
        g = grid(16, 16)
        for y in range(1, 15):
            dy = (y + 0.5 - 8) / 7
            hw = (w / 2) * math.sqrt(max(0, 1 - dy * dy))
            for x in range(16):
                dx = x + 0.5 - 8
                if abs(dx) <= max(0.6, hw):
                    inner = abs(dx) < hw - 1.6 and abs(dy) < 0.72
                    g[y][x] = "f" if inner else "r"
                    if inner and dx < -hw * 0.3 and dy < 0.1:
                        g[y][x] = "s"
        if w > 3:
            outline(g)
        else:  # edge-on: a thin bright rim with dark caps
            g[1][7] = g[1][8] = g[14][7] = g[14][8] = "o"
        if w >= 8:  # the engraved mark
            for y in range(5, 11):
                g[y][8 if w > 10 else 8] = "e"
        frames.append(rows(g))
    return 16, 16, legend, frames, 80


def campfire_frames():
    legend = {"o": C["plum"], "b": C["bark"], "w": C["wood"], "y": C["sun"], "g": C["gold"], "r": C["orange"], "t": C["red"], "s": C["fog"]}
    logs = [
        "....................",
        "..oo............oo..",
        ".owwoo........oowwo.",
        ".obwwwoooooooowwwbo.",
        "..oobbwwwwwwwwbboo..",
        "....oooooooooooo....",
    ]
    heights = [[4, 7, 10, 12, 13, 11, 8, 5], [5, 8, 12, 11, 13, 12, 7, 4], [3, 8, 11, 13, 12, 10, 9, 5], [5, 7, 10, 12, 14, 11, 7, 4]]
    frames = []
    for f, hs in enumerate(heights):
        g = grid(20, 20)
        for i, h in enumerate(hs):
            x = 6 + i
            for k in range(h):
                y = 15 - k
                frac = k / h
                core = 2 <= i <= 5 and frac < 0.55
                g[y][x] = "y" if core and frac < 0.35 else ("g" if core else ("r" if frac < 0.8 else "t"))
        # A spark that drifts up
        sx, sy = (5 + f * 3) % 14 + 3, 3 - (f % 2)
        g[sy][sx] = "g"
        for r, line in enumerate(logs):
            for x, ch in enumerate(line):
                if ch != ".":
                    g[14 + r][x] = ch
        frames.append(rows(g))
    return 20, 20, legend, frames, 120


ROBOT = [
    "........aa........",
    "........oo........",
    "...oooooooooooo...",
    "..ollllllllllllo..",
    "..olssssssssssdo..",
    "..olseessseessdo..",
    "..olseessseessdo..",
    "..olssssssssssdo..",
    "..olsssmmmmsssdo..",
    "..olssssssssssdo..",
    "..oddddddddddddo..",
    "...oooooooooooo...",
    "......olllld......",
    ".....olllllldo....",
    ".....oddddddddo...",
    "......oooooooo....",
]


def robot_frames():
    """The agent: a little robot that blinks and pings its antenna."""
    legend = {"o": C["navy"], "l": C["mist"], "d": C["fog"], "s": C["ink"], "e": C["cyan"], "m": C["sky"], "a": C["accent"], "q": C["bark"]}
    frames = []
    for lift, antenna, blink in [(0, "a", False), (1, "q", False), (1, "a", False), (0, "q", True)]:
        g = grid(18, 18)
        for y, line in enumerate(ROBOT):
            line = line.replace("a", antenna)
            if blink and y in (5, 6):
                line = line.replace("e", "s" if y == 5 else "m")
            for x, ch in enumerate(line):
                if ch != ".":
                    g[y + 1 + lift][x] = ch
        frames.append(rows(g))
    return 18, 18, legend, frames, 180


def potion_frames():
    legend = {"o": C["plum"], "c": C["wood"], "k": C["bark"], "g": C["mist"], "p": C["red"], "d": C["wine"], "b": C["pink"], "w": C["white"]}
    bubbles = [[(6, 13), (9, 11)], [(6, 12), (9, 10), (8, 14)], [(7, 11), (8, 13)], [(7, 10), (9, 12), (6, 14)]]
    frames = []
    for f in range(4):
        g = grid(16, 18)
        for y in range(1, 4):
            for x in range(6, 10):
                g[y][x] = "c" if y < 3 else "g"
        g[1][6] = g[1][9] = "k"
        for y in range(4, 6):
            for x in range(6, 10):
                g[y][x] = "g"
        cx, cy, r = 7.5, 11, 5.6
        for y in range(5, 17):
            for x in range(16):
                if (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= r * r:
                    g[y][x] = "p" if y >= 9 else "g"
                    if y >= 9 and x + 0.5 > cx + 2.5:
                        g[y][x] = "d"
        outline(g)
        g[10][4] = g[11][4] = g[12][4] = "w"  # glass shine
        g[9][5] = "b"
        for bx, by in bubbles[f]:
            if g[by][bx] in "pd":
                g[by][bx] = "b"
        frames.append(rows(g))
    return 16, 18, legend, frames, 160


def draw_sprite(agent, name, spec):
    w, h, legend, frames, ms = spec
    agent.call("new_sprite", width=w, height=h, name=name)
    for i, f in enumerate(frames):
        if i > 0:
            agent.call("add_frame", copy=False)
        agent.call("paint_slice", axis="z", index=0, rows=f, legend=legend, frame=i)
    agent.call("set_frame_duration", duration_ms=ms, all_frames=True)
    path = os.path.join(OUT, f"{name}.png")
    sheet = agent.call("export_sheet", path=path, views=["front"], scale=1)
    agent.call("review_model")  # what an agent does after each step; the result is not saved
    return {"src": f"/art/{name}.png", "w": w, "h": h, "frames": len(frames), "ms": ms, "axis": "x", "sheet": sheet}


# ---------------------------------------------------------------- voxel models

def tree_island(agent):
    agent.call("new_model", size_x=24, size_y=28, size_z=24, name="Tree island")
    agent.call("fill_box", **{"from": [2, 0, 2], "to": [21, 2, 21], "color": C["bark"]})
    agent.call("fill_box", **{"from": [2, 1, 2], "to": [21, 2, 21], "color": C["wood"]})
    agent.call("fill_box", **{"from": [2, 3, 2], "to": [21, 3, 21], "color": C["grass"]})
    agent.call("fill_box", **{"from": [4, 0, 4], "to": [19, 0, 19], "color": C["plum"]})
    agent.call("draw_cylinder", base=[11.5, 4, 11.5], radius=1.6, length=10, color=C["bark"])
    agent.call("draw_sphere", center=[11.5, 15, 11.5], radius=6, color=C["leaf"])
    agent.call("draw_sphere", center=[8.5, 17, 10.5], radius=4, color=C["grass"])
    agent.call("draw_sphere", center=[14.5, 18, 13.5], radius=4, color=C["grass"])
    agent.call("draw_sphere", center=[11.5, 20, 11.5], radius=3.5, color="#a6e15a")
    agent.call("draw_sphere", center=[11.5, 12, 11.5], radius=[6, 2, 6], color=C["forest"])
    flowers = [[5, 4, 6, C["red"]], [17, 4, 5, C["sun"]], [6, 4, 17, C["sun"]], [18, 4, 16, C["red"]], [15, 4, 19, "#ffffff"]]
    agent.call("set_voxels", voxels=flowers)
    agent.call("set_voxels", voxels=[[3, 4, 13, C["fog"]], [4, 4, 13, C["mist"]], [3, 4, 14, C["fog"]]])


def mushroom_house(agent):
    agent.call("new_model", size_x=22, size_y=24, size_z=22, name="Mushroom house")
    agent.call("draw_cylinder", base=[10.5, 0, 10.5], radius=10, length=1, color=C["grass"])
    agent.call("draw_cylinder", base=[10.5, 1, 10.5], radius=5, length=9, color=C["sand"])
    agent.call("fill_box", **{"from": [9, 1, 15], "to": [12, 5, 15], "color": C["bark"]})
    agent.call("set_voxels", voxels=[[11, 3, 15, C["gold"]], [6, 6, 13, C["sun"]], [15, 6, 13, C["sun"]]])
    agent.call("draw_sphere", center=[10.5, 13, 10.5], radius=[10, 6, 10], color=C["red"])
    agent.call("draw_sphere", center=[10.5, 10.5, 10.5], radius=[9, 2, 9], color=C["wine"])
    # White spots sit just on the cap's upper surface.
    spots = []
    for k in range(18):
        a = k * 2.399
        t = 0.18 + (k % 5) * 0.13          # 0 = top of the cap, 1 = its rim
        x = 10.5 + math.cos(a) * 10.2 * math.sin(t * math.pi / 2)
        z = 10.5 + math.sin(a) * 10.2 * math.sin(t * math.pi / 2)
        y = 13 + 6.2 * math.cos(t * math.pi / 2)
        for dx in (0, 1):
            spots.append([int(x) + dx, int(y), int(z), "#ffffff"])
    agent.call("set_voxels", voxels=spots)
    agent.call("draw_cylinder", base=[16.5, 1, 4.5], radius=1, length=2, color=C["sand"])
    agent.call("draw_sphere", center=[16.5, 3.5, 4.5], radius=[2, 1, 2], color=C["red"])


def turntable(agent, name, scale=4):
    path = os.path.join(OUT, f"{name}.png")
    sheet = agent.call("export_sheet", path=path, views=["turnaround8"], scale=scale)
    still = os.path.join(OUT, f"{name}-iso.png")
    agent.call("export_png", path=still, view="iso", scale=scale * 2)
    return {"src": f"/art/{name}.png", "still": f"/art/{name}-iso.png", "frames": 8, "ms": 220, "axis": "x", "sheet": sheet}


def main():
    if not os.path.exists(APP):
        sys.exit("Build the app first: cd app && make")
    os.makedirs(OUT, exist_ok=True)
    agent = Agent()
    art = {}
    for name, spec in [("slime", slime_frames()), ("coin", coin_frames()), ("campfire", campfire_frames()),
                       ("robot", robot_frames()), ("potion", potion_frames())]:
        art[name] = draw_sprite(agent, name, spec)
        print("drew", name)

    # The treasure chest: the 2D sprite, then Make 3D.
    agent.call("open_model", path=CHEST)
    agent.call("export_png", path=os.path.join(OUT, "chest.png"), view="front", scale=1)
    art["chest"] = {"src": "/art/chest.png", "w": 32, "h": 32, "frames": 1, "ms": 0, "axis": "x"}
    agent.call("extrude_to_3d", depth=6)
    art["chest3d"] = turntable(agent, "chest3d", scale=3)
    print("drew chest")

    # The robot, made 3D the same way.
    agent.call("new_sprite", width=18, height=18, name="robot")
    agent.call("paint_slice", axis="z", index=0, rows=robot_frames()[3][0], legend=robot_frames()[2])
    agent.call("extrude_to_3d", depth=8)
    art["robot3d"] = turntable(agent, "robot3d", scale=4)
    print("drew robot3d")

    tree_island(agent)
    art["tree"] = turntable(agent, "tree", scale=4)
    print("drew tree")
    mushroom_house(agent)
    art["mushroom"] = turntable(agent, "mushroom", scale=4)
    print("drew mushroom")
    agent.close()

    # Cell sizes come from the exported sheets.
    try:
        from PIL import Image
    except ImportError:
        Image = None
    for name, a in art.items():
        path = os.path.join(ROOT, "web", "public", a["src"].lstrip("/"))
        if Image:
            iw, ih = Image.open(path).size
            if a["axis"] == "x":
                a["w"], a["h"] = iw // a["frames"], ih
            else:
                a["w"], a["h"] = iw, ih // a["frames"]
        a.pop("sheet", None)

    with open(MANIFEST, "w") as f:
        f.write("// Generated by web/scripts/make-art.py: every picture was drawn and exported by OpenPixel.\n")
        f.write("export type Art = { src: string; still?: string; w: number; h: number; frames: number; ms: number; axis: \"x\" | \"y\" };\n\n")
        f.write("export const art = " + json.dumps(art, indent=2) + " satisfies Record<string, Art>;\n")
    print("wrote", MANIFEST)


if __name__ == "__main__":
    main()
