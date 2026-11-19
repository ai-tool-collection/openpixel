import type { Metadata } from "next";
import JsonLd from "@/components/JsonLd";
import { breadcrumbJsonLd, pageMeta } from "@/lib/seo";
import Markdown from "react-markdown";
import Sprite from "@/components/Sprite";
import { Footer, Header, Headline } from "@/components/Chrome";
import { art } from "@/lib/art";
import { REPO_URL, allReleases, formatDate } from "@/lib/github";

export const revalidate = 600;

export const metadata: Metadata = pageMeta({
  path: "/changelog",
  title: "Changelog",
  description: "What changed in each version of OpenPixel, release by release.",
});

export default async function Changelog() {
  const releases = await allReleases();
  return (
    <>
      <Header />
      <JsonLd data={breadcrumbJsonLd([["Changelog", "/changelog"]])} />
      <main>
        <section className="page-head wrap">
          <Sprite art={art.campfire} scale={4} label="A flickering campfire" />
          <Headline as="h1" lead="Changelog." rest="Everything new, release by release." />
        </section>
        <div className="prose wrap">
          {releases.length === 0 ? (
            <div className="card empty-state">
              <Sprite art={art.slime} scale={4} />
              <h2>No releases yet</h2>
              <p>
                The first version is on its way.{" "}
                <a href={REPO_URL} target="_blank" rel="noopener noreferrer">
                  Watch the repository on GitHub
                </a>{" "}
                to hear when it ships.
              </p>
            </div>
          ) : (
            releases.map((r) => (
              <article key={r.tag} className="release">
                <div className="release-head">
                  <h2>
                    <a href={r.url} target="_blank" rel="noopener noreferrer">
                      {r.name}
                    </a>
                    {r.prerelease ? <span className="pill">Pre-release</span> : null}
                  </h2>
                  <time className="meta" dateTime={r.date}>
                    {formatDate(r.date)}
                  </time>
                </div>
                {/* Release notes are Markdown from GitHub; raw HTML in them is not rendered. */}
                <div className="notes">
                  <Markdown
                    skipHtml
                    components={{
                      // Links in release notes point to GitHub and elsewhere: open them in a new tab.
                      a: ({ href, children }) =>
                        href && /^https?:/.test(href) ? (
                          <a href={href} target="_blank" rel="noopener noreferrer">
                            {children}
                          </a>
                        ) : (
                          <a href={href}>{children}</a>
                        ),
                    }}
                  >
                    {r.notes || "No notes for this release."}
                  </Markdown>
                </div>
              </article>
            ))
          )}
        </div>
      </main>
      <Footer />
    </>
  );
}
