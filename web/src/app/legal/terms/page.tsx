import type { Metadata } from "next";
import JsonLd from "@/components/JsonLd";
import { breadcrumbJsonLd, pageMeta } from "@/lib/seo";
import Link from "next/link";
import { Footer, Header, Headline } from "@/components/Chrome";
import { REPO_URL } from "@/lib/github";

export const metadata: Metadata = pageMeta({
  path: "/legal/terms",
  title: "Terms",
  description: "Terms for using OpenPixel and this website.",
});

export default function Terms() {
  return (
    <>
      <Header />
      <JsonLd data={breadcrumbJsonLd([["Terms", "/legal/terms"]])} />
      <main>
        <section className="page-head wrap">
          <Headline as="h1" lead="Terms." rest="Free software, plainly stated." />
        </section>
        <article className="prose wrap">
          <p className="updated">Last updated 19 November 2026</p>

          <h2>The software</h2>
          <p>
            OpenPixel is released under the{" "}
            <a href={`${REPO_URL}/blob/main/LICENSE`} target="_blank" rel="noopener noreferrer">
              MIT licence
            </a>
            . You may use, copy, change and share it, including commercially, as long as you keep the copyright and
            licence notice. The licence is the agreement that governs the software; nothing on this page limits it.
          </p>

          <h2>Your art is yours</h2>
          <p>
            Everything you make with OpenPixel belongs to you. We claim no rights to your sprites, models, exports or
            files, and you can use them for any purpose.
          </p>

          <h2>No warranty</h2>
          <p>
            OpenPixel is provided &ldquo;as is&rdquo;, without warranty of any kind, as the MIT licence says. Keep
            backups of work that matters. To the extent the law allows, the maintainers are not liable for any damage
            arising from the use of the software or this website.
          </p>

          <h2>AI agents and other services</h2>
          <p>
            OpenPixel works with AI agents and services made by others, such as Claude, ChatGPT, Codex and Cursor. Using
            them is between you and their providers, under their terms. You are responsible for what you ask an agent to
            do with OpenPixel, and for sharing an <code>--mcp-http</code> address only with people and services you
            trust.
          </p>

          <h2>This website</h2>
          <p>
            Use this website lawfully and don&apos;t try to disrupt it. Downloads come from GitHub. Product names and
            logos of other companies shown here are their trademarks and only indicate compatibility.
          </p>

          <h2>Third-party components</h2>
          <p>
            OpenPixel includes open-source components under their own licences. See{" "}
            <Link href="/legal/licenses">licences</Link>.
          </p>

          <h2>Contact</h2>
          <p>
            Questions about these terms: open an issue on{" "}
            <a href={`${REPO_URL}/issues`} target="_blank" rel="noopener noreferrer">
              GitHub
            </a>
            .
          </p>
        </article>
      </main>
      <Footer />
    </>
  );
}
