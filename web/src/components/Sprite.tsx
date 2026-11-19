import type { CSSProperties } from "react";
import type { Art } from "@/lib/art";

/**
 * An animated pixel-art sprite from a sheet exported by OpenPixel. Plain CSS: the sheet slides one cell per step,
 * pixels stay crisp at any whole-number scale, and people who prefer reduced motion see the first frame.
 * With `fluid`, the sprite fills its container's width (keeping its proportions) instead of using `scale`.
 */
export default function Sprite({
  art,
  scale = 4,
  label,
  paused = false,
  frame = 0,
  fluid = false,
  className,
}: {
  art: Art;
  scale?: number;
  label?: string;
  paused?: boolean;
  /** With `paused`, which frame to show. */
  frame?: number;
  /** Fill the container's width instead of a fixed pixel size. */
  fluid?: boolean;
  className?: string;
}) {
  if (fluid) {
    // Sizes in percentages: the sheet is `frames` cells wide, and frame k sits at k / (frames - 1) of the way.
    const last = Math.max(1, art.frames - 1);
    const style = {
      width: "100%",
      aspectRatio: `${art.w} / ${art.h}`,
      backgroundImage: `url(${art.src})`,
      backgroundSize: `${art.frames * 100}% 100%`,
      backgroundPosition: frame ? `${(frame / last) * 100}% 0` : "0% 0",
      "--sprite-steps": art.frames,
      "--sprite-time": `${art.frames * art.ms}ms`,
    } as CSSProperties;
    return (
      <span
        role={label ? "img" : undefined}
        aria-label={label}
        aria-hidden={label ? undefined : true}
        className={`sprite fluid${art.frames > 1 && !paused ? " playing" : ""}${className ? ` ${className}` : ""}`}
        style={style}
      />
    );
  }
  const w = art.w * scale;
  const h = art.h * scale;
  const style = {
    width: w,
    height: h,
    backgroundImage: `url(${art.src})`,
    backgroundSize: `${w * art.frames}px ${h}px`,
    backgroundPosition: frame ? `-${w * frame}px 0` : undefined,
    "--sprite-end": `-${w * art.frames}px`,
    "--sprite-steps": art.frames,
    "--sprite-time": `${art.frames * art.ms}ms`,
  } as CSSProperties;
  return (
    <span
      role={label ? "img" : undefined}
      aria-label={label}
      aria-hidden={label ? undefined : true}
      className={`sprite${art.frames > 1 && !paused ? " playing" : ""}${className ? ` ${className}` : ""}`}
      style={style}
    />
  );
}
