import type { CSSProperties } from "react";
import type { Art } from "@/lib/art";

/**
 * An animated pixel-art sprite from a sheet exported by OpenPixel. Plain CSS: the sheet slides one cell per step,
 * pixels stay crisp at any whole-number scale, and people who prefer reduced motion see the first frame.
 */
export default function Sprite({
  art,
  scale = 4,
  label,
  paused = false,
  frame = 0,
  className,
}: {
  art: Art;
  scale?: number;
  label?: string;
  paused?: boolean;
  /** With `paused`, which frame to show. */
  frame?: number;
  className?: string;
}) {
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
