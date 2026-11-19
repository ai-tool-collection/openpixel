"use client";

import { useState } from "react";
import { copyText } from "@/lib/copy";

/** A small pill that copies `text`; "Copy" cross-fades to "Copied" for a moment. */
export default function CopyButton({ text, label = "Copy", className }: { text: string; label?: string; className?: string }) {
  const [copied, setCopied] = useState(false);
  const copy = async () => {
    if (await copyText(text)) {
      setCopied(true);
      window.setTimeout(() => setCopied(false), 1500);
    }
  };
  return (
    <button type="button" className={`pill${className ? ` ${className}` : ""}`} onClick={copy}>
      <span className={copied ? "swap out" : "swap"}>{label}</span>
      <span className={copied ? "swap" : "swap out"} aria-live="polite">
        {copied ? "Copied" : ""}
      </span>
    </button>
  );
}
