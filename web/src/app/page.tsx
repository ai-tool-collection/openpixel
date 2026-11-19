import Image from "next/image";
import Link from "next/link";
import AgentCanvas from "@/components/AgentCanvas";
import { REPO_URL, formatSize, latestRelease } from "@/lib/github";
import { Header, Footer } from "@/components/Chrome";

export const revalidate = 600;

const AGENT_COMMAND = `claude mcp add --scope user openpixel -- \\
  /Applications/OpenPixel.app/Contents/MacOS/OpenPixel --mcp`;

export default async function Home() {
  const release = await latestRelease();
  const size = formatSize(release?.dmgSize);

  return (
    <>
      <Header />
      <main>
        <section className="hero wrap">
          <div className="hero-text">
            <h1>Draw pixel art with your AI agent.</h1>
            <p className="lede">
              OpenPixel is a free, open-source Mac app for 2D sprites and 3D voxel models. It has an MCP server built
              in, so Claude, ChatGPT, Cursor and other agents can draw, review and fix your art while you watch. You
              can undo anything they do.
            </p>
            <div className="cta">
              <a className="button primary" href="/download">
                Download for Mac
              </a>
              <a className="button" href={REPO_URL}>
                View the source
              </a>
            </div>
            <p className="fine">
              {release ? `Version ${release.version}, ` : ""}
              for macOS 13 or later on Apple silicon and Intel{size ? `, ${size}` : ""}. Updates install from inside
              the app.
            </p>
          </div>
          <AgentCanvas />
        </section>

        <section className="shot wrap" aria-label="The editor">
          <Image
            src="/editor.png"
            alt="The OpenPixel editor: a 32 by 32 treasure chest sprite on the canvas, layers on the left, colours and a live preview on the right"
            width={1440}
            height={900}
            priority
          />
        </section>

        <section className="features wrap">
          <h2>One editor for flat sprites and voxel models</h2>
          <div className="cols">
            <div>
              <h3>Sprites</h3>
              <p>
                Pencil, fill, line, rectangle, recolour and move, with mirror drawing. Layers, animation frames,
                onion skin, and palettes like PICO-8, DawnBringer 32 and Endesga 32.
              </p>
            </div>
            <div>
              <h3>Voxel models</h3>
              <p>
                The same tools in 3D, a live isometric preview that renders to crisp sprites, and Make 3D to give any
                sprite depth.
              </p>
            </div>
            <div>
              <h3>Exports</h3>
              <p>
                PNG, animated GIF, sprite sheets, SVG and a self-contained HTML page. Voxel models also export to
                MagicaVoxel .vox and OBJ.
              </p>
            </div>
          </div>
        </section>

        <section className="agents wrap" id="agents">
          <h2>Connect an agent in three steps</h2>
          <ol className="steps">
            <li>
              <h3>Install OpenPixel</h3>
              <p>Open the disk image and drag OpenPixel to Applications.</p>
            </li>
            <li>
              <h3>Add it to your agent</h3>
              <p>For Claude Code, run this once. Every other MCP client uses the same command in its settings.</p>
              <pre>
                <code>{AGENT_COMMAND}</code>
              </pre>
              <p>
                The Agents page inside OpenPixel shows which agents are connected and has setup steps for ChatGPT,
                Codex, Claude, Cursor, OpenClaw and Hermes Agent.
              </p>
            </li>
            <li>
              <h3>Ask for some art</h3>
              <p>
                Try <q>Make a 32×32 treasure chest in OpenPixel, review it, and fix anything that looks off.</q> Each
                change appears in the open window and in its Activity list.
              </p>
            </li>
          </ol>
        </section>

        <section className="source wrap">
          <h2>Open source, MIT licensed</h2>
          <p>
            Read the code, build it yourself, or send a pull request. The Mac app is written in Swift and needs the
            Xcode command line tools.
          </p>
          <pre>
            <code>{`git clone ${REPO_URL}.git
cd openpixel/app && make`}</code>
          </pre>
          <ul className="links">
            <li>
              <a href={`${REPO_URL}/blob/main/CONTRIBUTING.md`}>How to contribute</a>
            </li>
            <li>
              <a href={`${REPO_URL}/issues`}>Report a bug</a>
            </li>
            <li>
              <Link href="/changelog">What changed in each version</Link>
            </li>
          </ul>
        </section>
      </main>
      <Footer />
    </>
  );
}
