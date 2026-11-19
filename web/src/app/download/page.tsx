import type { Metadata } from "next";
import Link from "next/link";
import CopyCommand from "@/components/CopyCommand";
import Sprite from "@/components/Sprite";
import { Footer, Header, Headline } from "@/components/Chrome";
import { art } from "@/lib/art";
import { REPO_URL, formatDate, formatSize, latestRelease } from "@/lib/github";

export const revalidate = 600;

export const metadata: Metadata = {
  title: "Download",
  description: "Download OpenPixel for macOS. Free and open source, for Apple silicon and Intel Macs.",
};

const EXE = "/Applications/OpenPixel.app/Contents/MacOS/OpenPixel";

export default async function Download() {
  const release = await latestRelease();
  const size = formatSize(release?.dmgSize);
  const details = release
    ? [`Version ${release.version}`, formatDate(release.date), size].filter(Boolean).join(", ")
    : "The first release is on its way.";

  return (
    <>
      <Header />
      <main>
        <section className="page-head wrap">
          <Sprite art={art.chest} scale={4} label="Pixel-art treasure chest" />
          <Headline as="h1" lead="Download OpenPixel" rest="for macOS." />
          <p className="lead-text">Free and open source. No account, no subscription, no trial.</p>
        </section>

        <div className="wrap">
          <div className="card download-card">
            <div>
              <h2>OpenPixel for Mac</h2>
              <p>{details}</p>
              <p>macOS 13 Ventura or later. Apple silicon and Intel in one app.</p>
            </div>
            <a className="button primary large" href="/download/mac">
              Download .dmg
            </a>
          </div>
        </div>

        <article className="prose wrap">
          <h2>Install</h2>
          <ol className="steps">
            <li>
              <h3>Open the disk image</h3>
              <p>Double-click OpenPixel.dmg in your Downloads folder.</p>
            </li>
            <li>
              <h3>Drag OpenPixel to Applications</h3>
              <p>The app is signed and notarized by Apple, so it opens without warnings.</p>
            </li>
            <li>
              <h3>Stay up to date</h3>
              <p>OpenPixel checks for new versions once a day and asks before it installs one.</p>
            </li>
          </ol>

          <h2>Connect your agent</h2>
          <p>
            OpenPixel has an MCP server built in. Add it once and your agent can create, review and refine sprites and
            models. The Agents page in the app shows who is connected and has steps for every app below.
          </p>
          <h3>Claude Code</h3>
          <CopyCommand command={`claude mcp add --scope user openpixel -- ${EXE} --mcp`} />
          <h3>Codex</h3>
          <CopyCommand command={`codex mcp add openpixel -- ${EXE} --mcp`} />
          <h3>Claude, Cursor, OpenClaw, Hermes Agent and other MCP clients</h3>
          <p>Add a server that runs this command:</p>
          <CopyCommand command={`${EXE} --mcp`} />
          <h3>ChatGPT</h3>
          <p>
            ChatGPT connects over HTTPS. Run <code>OpenPixel --mcp-http 8765</code>, expose that port with a tunnel of
            your choice, and add the address it prints as a connector. Agents connected this way can only open and save
            files in <code>~/Documents/OpenPixel</code>.
          </p>

          <h2>Build it yourself</h2>
          <p>You need the Xcode command line tools.</p>
          <pre>
            <code>{`git clone ${REPO_URL}.git
cd openpixel/app
make`}</code>
          </pre>
          <p>
            Older versions are on <a href={`${REPO_URL}/releases`}>GitHub releases</a>. See what changed in
            the <Link href="/changelog">changelog</Link>.
          </p>
        </article>
      </main>
      <Footer />
    </>
  );
}
