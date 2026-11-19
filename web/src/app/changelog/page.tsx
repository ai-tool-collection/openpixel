import type { Metadata } from "next";
import Markdown from "react-markdown";
import { Header, Footer } from "@/components/Chrome";
import { REPO_URL, allReleases, formatDate } from "@/lib/github";

export const revalidate = 600;

export const metadata: Metadata = {
  title: "Changelog — OpenPixel",
  description: "What changed in each version of OpenPixel.",
};

export default async function Changelog() {
  const releases = await allReleases();
  return (
    <>
      <Header />
      <main className="wrap changelog">
        <h1>Changelog</h1>
        {releases.length === 0 ? (
          <p className="empty">
            No releases are published yet. Follow the project on <a href={REPO_URL}>GitHub</a> to hear about the first
            one.
          </p>
        ) : (
          releases.map((r) => (
            <article key={r.tag} className="release">
              <header>
                <h2>
                  <a href={r.url}>{r.name}</a>
                </h2>
                <p className="meta">
                  <time dateTime={r.date}>{formatDate(r.date)}</time>
                  {r.prerelease ? <span className="pre">Pre-release</span> : null}
                </p>
              </header>
              {/* Release notes are Markdown from GitHub; raw HTML in them is not rendered. */}
              <div className="notes">
                <Markdown skipHtml>{r.notes || "No notes for this release."}</Markdown>
              </div>
            </article>
          ))
        )}
      </main>
      <Footer />
    </>
  );
}
