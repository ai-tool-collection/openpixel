import Image from "next/image";
import Link from "next/link";
import { REPO_URL } from "@/lib/github";

export function Header() {
  return (
    <header className="site-header wrap">
      <Link href="/" className="brand">
        <Image src="/logo.svg" alt="" width={24} height={24} />
        OpenPixel
      </Link>
      <nav aria-label="Main">
        <Link href="/changelog">Changelog</Link>
        <a href={REPO_URL}>GitHub</a>
        <a className="button small primary" href="/download">
          Download
        </a>
      </nav>
    </header>
  );
}

export function Footer() {
  return (
    <footer className="site-footer wrap">
      <p>
        OpenPixel is free software under the MIT licence. Agent names and logos belong to their owners and only show
        which apps work with OpenPixel.
      </p>
      <nav aria-label="Footer">
        <a href={REPO_URL}>Source code</a>
        <a href={`${REPO_URL}/security/policy`}>Security</a>
        <Link href="/changelog">Changelog</Link>
      </nav>
    </footer>
  );
}
