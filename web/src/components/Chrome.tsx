import Image from "next/image";
import Link from "next/link";
import { REPO_URL } from "@/lib/github";

export function Header() {
  return (
    <header className="site-header">
      <div className="wrap header-row">
        <Link href="/" className="brand">
          <Image src="/logo.svg" alt="" width={20} height={20} />
          OpenPixel
        </Link>
        <nav aria-label="Main">
          <Link href="/compare">Compare</Link>
          <Link href="/changelog">Changelog</Link>
          <a href={REPO_URL}>GitHub</a>
          <Link className="button small" href="/download">
            Download
          </Link>
        </nav>
      </div>
    </header>
  );
}

export function Footer() {
  return (
    <footer className="site-footer">
      <div className="wrap footer-grid">
        <div className="footer-brand">
          <Link href="/" className="brand">
            <Image src="/logo.svg" alt="" width={20} height={20} />
            OpenPixel
          </Link>
          <p>Free and open source pixel art for the Mac. MIT licence.</p>
        </div>
        <nav aria-label="Product">
          <h2>Product</h2>
          <Link href="/download">Download</Link>
          <Link href="/compare">Compare</Link>
          <Link href="/changelog">Changelog</Link>
        </nav>
        <nav aria-label="Open source">
          <h2>Open source</h2>
          <a href={REPO_URL}>Source code</a>
          <a href={`${REPO_URL}/blob/main/CONTRIBUTING.md`}>Contribute</a>
          <a href={`${REPO_URL}/security/policy`}>Security</a>
        </nav>
        <nav aria-label="Legal">
          <h2>Legal</h2>
          <Link href="/legal/privacy">Privacy</Link>
          <Link href="/legal/terms">Terms</Link>
          <Link href="/legal/licenses">Licences</Link>
        </nav>
      </div>
      <p className="wrap footer-note">
        Agent names and logos belong to their owners and only show which apps work with OpenPixel.
      </p>
    </footer>
  );
}

/** A two-tone heading: the statement, then its continuation in a quieter grey. */
export function Headline({ as: Tag = "h2", lead, rest, className }: { as?: "h1" | "h2"; lead: string; rest: string; className?: string }) {
  return (
    <Tag className={`headline${className ? ` ${className}` : ""}`}>
      {lead}
      <br />
      <span>{rest}</span>
    </Tag>
  );
}
