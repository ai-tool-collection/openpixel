"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { GTM_ID, OPEN_EVENT, loadAnalytics, stopAnalytics, storeChoice, storedChoice, type Choice } from "@/lib/consent";

/**
 * Asks once whether we may use Google Analytics. Nothing from Google loads until "Allow" is pressed, and
 * "Decline" is just as easy. Slides in shortly after the page appears, never takes focus and never blocks the page.
 * "Cookie settings" in the footer opens it again; declining after allowing deletes the Analytics cookies.
 */
export default function CookieBanner() {
  const [open, setOpen] = useState(false);

  useEffect(() => {
    if (!GTM_ID) return;
    const choice = storedChoice();
    if (choice === "granted") loadAnalytics();
    // A short pause so the banner arrives after the page, not with it.
    const id = choice ? 0 : window.setTimeout(() => setOpen(true), 700);
    const reopen = () => setOpen(true);
    window.addEventListener(OPEN_EVENT, reopen);
    return () => {
      window.clearTimeout(id);
      window.removeEventListener(OPEN_EVENT, reopen);
    };
  }, []);

  if (!GTM_ID) return null;

  const choose = (choice: Choice) => {
    storeChoice(choice);
    if (choice === "granted") loadAnalytics();
    else stopAnalytics();
    setOpen(false);
  };

  return (
    <section className={`cookie${open ? " open" : ""}`} aria-label="Cookie consent" inert={!open}>
      <p>
        Can we use Google Analytics to count visits? It sets cookies only if you allow it, and helps us see which pages
        are useful. <Link href="/legal/privacy#analytics">Privacy policy</Link>
      </p>
      <div className="cookie-actions">
        <button type="button" className="cookie-button" onClick={() => choose("denied")}>
          Decline
        </button>
        <button type="button" className="cookie-button" onClick={() => choose("granted")}>
          Allow
        </button>
      </div>
    </section>
  );
}

/** The footer link that opens the banner again, so a choice can be changed at any time. */
export function CookieSettingsLink() {
  if (!GTM_ID) return null;
  return (
    <button type="button" className="footer-button" onClick={() => window.dispatchEvent(new Event(OPEN_EVENT))}>
      Cookie settings
    </button>
  );
}
