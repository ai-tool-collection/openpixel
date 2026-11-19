import Image from "next/image";

type Cursor = { name: string; path: "a" | "b" | "c"; tone: "accent" | "cyan" | "lime" };

const CURSORS: Cursor[] = [
  { name: "Claude", path: "a", tone: "accent" },
  { name: "Codex", path: "b", tone: "cyan" },
  { name: "Cursor", path: "c", tone: "lime" },
];

/**
 * A Mac window showing the editor. The picture is a placeholder for a screen recording; the agent cursors
 * moving across it are drawn by CSS.
 */
export default function AppWindow({
  src,
  alt,
  title,
  cursors = true,
  priority = false,
}: {
  src: string;
  alt: string;
  title: string;
  cursors?: boolean;
  priority?: boolean;
}) {
  return (
    <div className="window">
      <div className="window-bar">
        <span className="lights" aria-hidden="true">
          <i />
          <i />
          <i />
        </span>
        <span className="window-title">
          <Image src="/logo.svg" alt="" width={14} height={14} />
          <b>OpenPixel</b>
          <span>{title}</span>
          <span className="saved">Saved</span>
        </span>
      </div>
      <div className="window-body">
        <Image src={src} alt={alt} width={1440} height={900} priority={priority} sizes="(max-width: 1240px) 100vw, 1200px" />
        {cursors ? (
          <div className="cursors" aria-hidden="true">
            {CURSORS.map((c) => (
              <span key={c.name} className={`agent-cursor path-${c.path} tone-${c.tone}`}>
                <svg width="16" height="18" viewBox="0 0 16 18">
                  <path d="M1 1l13 7.5-6 1.2L5.2 16z" />
                </svg>
                <span className="tag">{c.name}</span>
              </span>
            ))}
          </div>
        ) : null}
      </div>
    </div>
  );
}
