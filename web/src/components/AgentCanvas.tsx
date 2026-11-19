"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { palette, rows } from "@/lib/chest";

// A replay of an agent drawing the treasure chest through OpenPixel's MCP tools: the sprite is painted
// colour by colour, reviewed, then extruded into a voxel model and rendered in isometric view.

const W = 32;
const H = 32;
const DEPTH = 4;
const KEYS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";

type Pixel = { x: number; y: number; c: number };
type Call = { tool: string; args: string; pixels?: Pixel[]; view?: "2d" | "3d" };

function luminance(hex: string) {
  const n = parseInt(hex.slice(1), 16);
  return 0.2126 * ((n >> 16) & 255) + 0.7152 * ((n >> 8) & 255) + 0.0722 * (n & 255);
}

function shade(hex: string, f: number) {
  const n = parseInt(hex.slice(1), 16);
  const ch = (v: number) => Math.max(0, Math.min(255, Math.round(f > 0 ? v + (255 - v) * f : v * (1 + f))));
  return `rgb(${ch((n >> 16) & 255)},${ch((n >> 8) & 255)},${ch(n & 255)})`;
}

function buildCalls(): Call[] {
  const byColour = new Map<number, Pixel[]>();
  rows.forEach((row, y) =>
    [...row].forEach((ch, x) => {
      if (ch === ".") return;
      const c = KEYS.indexOf(ch);
      if (!byColour.has(c)) byColour.set(c, []);
      byColour.get(c)!.push({ x, y, c });
    }),
  );
  // Outline first (darkest), highlights last, the way a pixel artist works.
  const order = [...byColour.keys()].sort((a, b) => luminance(palette[a]) - luminance(palette[b]));
  const calls: Call[] = [
    { tool: "new_sprite", args: `{ width: ${W}, height: ${H} }`, view: "2d" },
    { tool: "add_colors", args: `{ colors: ${palette.length} }` },
  ];
  for (const c of order) {
    const px = byColour.get(c)!;
    calls.push({ tool: "set_pixels", args: `{ color: "${palette[c]}", pixels: ${px.length} }`, pixels: px });
  }
  calls.push({ tool: "review_model", args: "{}" });
  calls.push({ tool: "extrude_to_3d", args: `{ depth: ${DEPTH} }`, view: "3d" });
  calls.push({ tool: "render_view", args: `{ view: "iso" }` });
  return calls;
}

function drawChecker(ctx: CanvasRenderingContext2D, size: number) {
  const cell = size / 16;
  for (let y = 0; y < 16; y++)
    for (let x = 0; x < 16; x++) {
      ctx.fillStyle = (x + y) % 2 ? "#d4d5d8" : "#c4c5c9";
      ctx.fillRect(x * cell, y * cell, cell + 0.5, cell + 0.5);
    }
}

function draw2D(ctx: CanvasRenderingContext2D, size: number, pixels: Pixel[]) {
  drawChecker(ctx, size);
  const p = size / W;
  for (const { x, y, c } of pixels) {
    ctx.fillStyle = palette[c];
    ctx.fillRect(Math.floor(x * p), Math.floor(y * p), Math.ceil(p), Math.ceil(p));
  }
}

function draw3D(ctx: CanvasRenderingContext2D, size: number, pixels: Pixel[], layers: number) {
  drawChecker(ctx, size);
  const solid = new Set(pixels.map((v) => `${v.x},${v.y}`));
  // World: X right, Y up, Z toward the viewer. 2:1 isometric, the usual pixel-art angle.
  // The model spans 36 cells across and 50 down in this projection; fit that into the square with a margin.
  const s = size / 52;
  const ox = size / 2 - ((W - DEPTH) / 2) * s;
  const oy = (H + 1) * s;
  const P = (X: number, Y: number, Z: number): [number, number] => [ox + (X - Z) * s, oy + ((X + Z) * s) / 2 - Y * s];
  const poly = (pts: [number, number][], fill: string) => {
    ctx.beginPath();
    ctx.moveTo(pts[0][0], pts[0][1]);
    for (const q of pts.slice(1)) ctx.lineTo(q[0], q[1]);
    ctx.closePath();
    ctx.fillStyle = fill;
    ctx.fill();
    ctx.strokeStyle = fill;
    ctx.lineWidth = 0.6;
    ctx.stroke();
  };
  const cubes: { X: number; Y: number; Z: number; c: number }[] = [];
  for (const { x, y, c } of pixels) for (let Z = 0; Z < layers; Z++) cubes.push({ X: x, Y: H - 1 - y, Z, c });
  cubes.sort((a, b) => a.X + a.Z - (b.X + b.Z) || a.Y - b.Y);
  for (const { X, Y, Z, c } of cubes) {
    const col = palette[c];
    const y = H - 1 - Y;
    // Only faces with nothing in front of them are drawn.
    if (!solid.has(`${X},${y - 1}`))
      poly([P(X, Y + 1, Z), P(X + 1, Y + 1, Z), P(X + 1, Y + 1, Z + 1), P(X, Y + 1, Z + 1)], shade(col, 0.22));
    if (!solid.has(`${X + 1},${y}`))
      poly([P(X + 1, Y, Z), P(X + 1, Y + 1, Z), P(X + 1, Y + 1, Z + 1), P(X + 1, Y, Z + 1)], shade(col, -0.32));
    if (Z === layers - 1) poly([P(X, Y, Z + 1), P(X + 1, Y, Z + 1), P(X + 1, Y + 1, Z + 1), P(X, Y + 1, Z + 1)], col);
  }
}

const calls = buildCalls();
const all = calls.flatMap((c) => c.pixels ?? []);

export default function AgentCanvas() {
  const canvas = useRef<HTMLCanvasElement>(null);
  const [step, setStep] = useState(0); // calls finished
  const [view, setView] = useState<"2d" | "3d">("2d");
  const [playing, setPlaying] = useState(false);
  const timers = useRef<number[]>([]);

  const paint = useCallback(
    (v: "2d" | "3d", pixels: Pixel[], layers = DEPTH) => {
      const el = canvas.current;
      if (!el) return;
      const size = el.clientWidth;
      const dpr = window.devicePixelRatio || 1;
      if (el.width !== Math.round(size * dpr)) {
        el.width = Math.round(size * dpr);
        el.height = Math.round(size * dpr);
      }
      const ctx = el.getContext("2d")!;
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      ctx.imageSmoothingEnabled = false;
      if (v === "2d") draw2D(ctx, size, pixels);
      else draw3D(ctx, size, pixels, layers);
    },
    [],
  );

  const stop = () => {
    timers.current.forEach((t) => window.clearTimeout(t));
    timers.current = [];
  };

  const play = useCallback(() => {
    stop();
    setPlaying(true);
    setView("2d");
    setStep(0);
    let t = 300;
    const drawn: Pixel[] = [];
    const at = (ms: number, fn: () => void) => timers.current.push(window.setTimeout(fn, ms));
    at(0, () => paint("2d", []));
    calls.forEach((call, i) => {
      if (call.pixels) {
        // Each call lands in a few quick strokes so you can see it being drawn.
        const strokes = Math.min(6, Math.ceil(call.pixels.length / 12));
        const per = Math.ceil(call.pixels.length / strokes);
        for (let k = 0; k < strokes; k++) {
          at(t + k * 40, () => {
            drawn.push(...call.pixels!.slice(k * per, (k + 1) * per));
            paint("2d", drawn);
          });
        }
        t += strokes * 40 + 70;
      } else if (call.tool === "extrude_to_3d") {
        at(t, () => setView("3d"));
        for (let d = 1; d <= DEPTH; d++) at(t + (d - 1) * 140, () => paint("3d", all, d));
        t += DEPTH * 140 + 200;
      } else {
        t += call.tool === "review_model" ? 600 : 350;
      }
      at(t, () => setStep(i + 1));
    });
    at(t, () => setPlaying(false));
  }, [paint]);

  useEffect(() => {
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reduce) {
      // No animation: show the finished model straight away.
      const id = window.setTimeout(() => {
        setStep(calls.length);
        setView("3d");
        paint("3d", all);
      }, 0);
      return () => window.clearTimeout(id);
    }
    const id = window.setTimeout(play, 0);
    return () => {
      window.clearTimeout(id);
      stop();
    };
  }, [play, paint]);

  useEffect(() => {
    const onResize = () => {
      if (!playing) paint(view, all);
    };
    window.addEventListener("resize", onResize);
    return () => window.removeEventListener("resize", onResize);
  }, [playing, view, paint]);

  const show = (v: "2d" | "3d") => {
    stop();
    setPlaying(false);
    setStep(calls.length);
    setView(v);
    paint(v, all);
  };

  const visible = calls.slice(Math.max(0, step - 6), step);

  return (
    <figure className="agent-canvas" aria-label="An AI agent drawing a treasure chest in OpenPixel, then turning it into a 3D model">
      <div className="ac-bar">
        <span className="ac-title">Pirate Treasure Chest</span>
        <span className="ac-size">{view === "2d" ? "32×32 sprite" : "32×32×4 model"}</span>
        <div className="ac-seg" role="group" aria-label="View">
          <button type="button" aria-pressed={view === "2d"} onClick={() => show("2d")}>2D</button>
          <button type="button" aria-pressed={view === "3d"} onClick={() => show("3d")}>3D</button>
        </div>
      </div>
      <canvas ref={canvas} className="ac-canvas" role="img" aria-label="Treasure chest pixel art" />
      <div className="ac-log">
        <div className="ac-log-head">
          <span>Activity</span>
          <button type="button" className="ac-replay" onClick={play} disabled={playing}>
            {playing ? "Drawing…" : "Play again"}
          </button>
        </div>
        <ol aria-live="off">
          {visible.map((c, i) => (
            <li key={`${step}-${i}`}>
              <span className="who">agent</span>
              <code className="tool">{c.tool}</code>
              <code className="args">{c.args}</code>
            </li>
          ))}
        </ol>
      </div>
    </figure>
  );
}
