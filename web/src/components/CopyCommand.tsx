"use client";

import { useState } from "react";

/** A command with a Copy button, styled like the prompt bar in the app's Agents page. */
export default function CopyCommand({ command, label = "Copy" }: { command: string; label?: string }) {
  const [copied, setCopied] = useState(false);
  const copy = async () => {
    try {
      await navigator.clipboard.writeText(command);
      setCopied(true);
      window.setTimeout(() => setCopied(false), 1600);
    } catch {
      // Clipboard blocked: the command stays selectable.
    }
  };
  return (
    <div className="command">
      <code>{command}</code>
      <button type="button" onClick={copy} aria-live="polite">
        {copied ? "Copied" : label}
      </button>
    </div>
  );
}
