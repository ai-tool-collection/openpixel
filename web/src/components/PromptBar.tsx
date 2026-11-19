"use client";

import { useEffect, useRef, useState } from "react";
import { copyText } from "@/lib/copy";

/**
 * A prompt bar that types out things you can ask an agent to do with OpenPixel, like the prompt on pen.dev.
 * - Types at a slightly uneven human pace, holds the finished prompt, then deletes it quickly and moves on.
 * - When a prompt is longer than the bar, the text slides left so the caret stays in view and the start fades
 *   out under a soft mask. Nothing is cut off at the end.
 * - Pauses while off screen or in a background tab. With reduced motion, shows one finished prompt, no typing.
 * - Create copies the prompt (with "Use OpenPixel" in front, so the agent picks the right tools) and says where
 *   to paste it. The prompt is the real thing: it works as written once an agent is connected.
 */

/** Prompts written the way you'd type them to an agent. */
const PROMPTS = [
  "Draw a 32×32 treasure chest, then review it and fix anything that looks off",
  "Animate a bouncing slime in 6 frames and export it as a sprite sheet",
  "Turn my knight sprite into a voxel model and render it in isometric",
  "Build a mushroom house out of voxels and save it as a MagicaVoxel file",
  "Recolour this tileset to the PICO-8 palette and keep the shading",
  "Make a 4-frame campfire that flickers at 120 ms a frame",
];

const line = (i: number) => PROMPTS[i];

const TYPE_MS = [42, 93]; // per character, varied so it reads as typing rather than a ticker
const DELETE_MS = 14;
const HOLD_MS = 1900;
const GAP_MS = 380;

export default function PromptBar() {
  const [index, setIndex] = useState(0);
  const [text, setText] = useState("");
  const [copied, setCopied] = useState(false);
  const [overflow, setOverflow] = useState(false);
  const bar = useRef<HTMLDivElement>(null);
  const viewport = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      const id = window.setTimeout(() => setText(line(0)), 0);
      return () => window.clearTimeout(id);
    }
    let timer = 0;
    let visible = true;
    let i = 0;
    let shown = "";
    let phase: "type" | "hold" | "delete" = "type";

    const step = () => {
      if (!visible || document.hidden) return; // resumes from here when visible again
      const full = line(i);
      let wait: number;
      if (phase === "type") {
        shown = full.slice(0, shown.length + 1);
        wait = shown.length === full.length ? HOLD_MS : TYPE_MS[0] + Math.random() * (TYPE_MS[1] - TYPE_MS[0]);
        if (shown.length === full.length) phase = "hold";
      } else if (phase === "hold") {
        phase = "delete";
        wait = 0;
      } else {
        shown = shown.slice(0, -1);
        wait = DELETE_MS;
        if (shown.length === 0) {
          phase = "type";
          i = (i + 1) % PROMPTS.length;
          setIndex(i);
          wait = GAP_MS;
        }
      }
      setText(shown);
      timer = window.setTimeout(step, wait);
    };

    const resume = () => {
      window.clearTimeout(timer);
      if (visible && !document.hidden) timer = window.setTimeout(step, 120);
    };
    const io = new IntersectionObserver(([entry]) => {
      visible = entry.isIntersecting;
      resume();
    });
    if (bar.current) io.observe(bar.current);
    document.addEventListener("visibilitychange", resume);
    timer = window.setTimeout(step, 700);
    return () => {
      window.clearTimeout(timer);
      io.disconnect();
      document.removeEventListener("visibilitychange", resume);
    };
  }, []);

  // Fade the start only while the text is wider than the bar.
  useEffect(() => {
    const v = viewport.current;
    if (!v) return;
    const next = v.scrollWidth > v.clientWidth + 1;
    if (next !== overflow) {
      const id = window.requestAnimationFrame(() => setOverflow(next));
      return () => window.cancelAnimationFrame(id);
    }
  }, [text, overflow]);

  const create = async () => {
    if (await copyText(`Use OpenPixel: ${PROMPTS[index]}.`)) {
      setCopied(true);
      window.setTimeout(() => setCopied(false), 4000);
    }
  };

  return (
    <div className="prompt">
      <div ref={bar} className="prompt-bar">
        <span className="sr-only">Example prompt for your agent: {line(index)}</span>
        <div ref={viewport} className={`prompt-viewport${overflow ? " overflowing" : ""}`} aria-hidden="true">
          <div className="prompt-track">
            <span className="prompt-text">{text}</span>
            <span className="prompt-caret" />
          </div>
        </div>
        <button type="button" className="prompt-button" onClick={create} aria-label="Create: copy this prompt for your agent">
          <span className={copied ? "swap out" : "swap"}>Create</span>
          <span className={copied ? "swap" : "swap out"} aria-hidden={!copied}>
            Copied
          </span>
        </button>
      </div>
      <p className={`prompt-hint${copied ? " shown" : ""}`} aria-live="polite">
        {copied ? (
          <>
            Prompt copied. Paste it into Claude, Codex or Cursor with OpenPixel connected.{" "}
            <a href="/downloads#agents">Connect an agent</a>
          </>
        ) : null}
      </p>
    </div>
  );
}
