"use client";

import { useEffect } from "react";

/** Marks the page as scrolled (html[data-scrolled]) so the header can fade in its background. */
export default function ScrollState() {
  useEffect(() => {
    const root = document.documentElement;
    const update = () => {
      root.dataset.scrolled = window.scrollY > 8 ? "true" : "false";
    };
    update();
    window.addEventListener("scroll", update, { passive: true });
    return () => window.removeEventListener("scroll", update);
  }, []);
  return null;
}
