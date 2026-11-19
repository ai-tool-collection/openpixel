import Image from "next/image";
import Link from "next/link";
import AppWindow from "@/components/AppWindow";
import CopyCommand from "@/components/CopyCommand";
import Showcase from "@/components/Showcase";
import Sprite from "@/components/Sprite";
import { Footer, Header, Headline } from "@/components/Chrome";
import { art } from "@/lib/art";
import { REPO_URL } from "@/lib/github";

const MCP_COMMAND = "claude mcp add openpixel -- /Applications/OpenPixel.app/Contents/MacOS/OpenPixel --mcp";

const AGENTS = [
  { name: "Claude", logo: "claude-color.svg" },
  { name: "Claude Code", logo: "claudecode-color.svg" },
  { name: "ChatGPT", logo: "openai.svg", mono: true },
  { name: "Codex", logo: "codex-color.svg" },
  { name: "Cursor", logo: "cursor.svg", mono: true },
  { name: "OpenClaw", logo: "openclaw-color.svg" },
  { name: "Hermes Agent", logo: "hermesagent.svg", mono: true },
  { name: "Any MCP client", logo: null },
];

const GALLERY = [
  { a: art.slime, scale: 12, name: "Slime", note: "6 frames", bg: "forest" },
  { a: art.mushroom, scale: 2, name: "Mushroom house", note: "22×24×22 voxels", bg: "plum" },
  { a: art.campfire, scale: 11, name: "Campfire", note: "4 frames", bg: "night" },
  { a: art.tree, scale: 2, name: "Tree island", note: "24×28×24 voxels", bg: "sky" },
  { a: art.coin, scale: 11, name: "Coin", note: "8 frames", bg: "rust" },
  { a: art.robot3d, scale: 2, name: "Agent, made 3D", note: "18×18×8 voxels", bg: "steel" },
];

const DB32 =
  "000000 222034 45283c 663931 8f563b df7126 d9a066 eec39a fbf236 99e550 6abe30 37946e 4b692f 524b24 323c39 3f3f74 306082 5b6ee1 639bff 5fcde4 cbdbfc ffffff 9badb7 847e87 696a6a 595652 76428a ac3232 d95763 d77bba 8f974a 8a6f30".split(
    " ",
  );

const MORE = [
  "Pencil, eraser, fill, line, rectangle and move",
  "Recolour and eyedropper",
  "500 steps of undo",
  "Colour ramps and gradients",
  "Import PNGs from any editor",
  "PNG, SVG and HTML export",
  "Turnaround renders in 8 angles",
  "Recent files with previews",
  "Headless mode for scripts and CI",
  "MCP over HTTP for ChatGPT",
  "Updates itself, signed and notarized",
  "Apple silicon and Intel",
];

export default function Home() {
  return (
    <>
      <Header />
      <main>
        {/* Hero */}
        <section className="hero">
          <div className="wrap hero-inner">
            <Sprite art={art.robot} scale={4} label="OpenPixel's agent, a small robot with a blinking antenna" />
            <Headline as="h1" lead="OpenPixel is an agentic pixel editor" rest="for sprites and voxel worlds." />
            <CopyCommand command={MCP_COMMAND} label="Copy" />
            <a className="button primary large" href="/download/mac">
              Download for macOS
            </a>
            <p className="hero-note">
              Free and open source. <a href={REPO_URL}>View on GitHub</a>
            </p>
          </div>
          <div className="wrap-wide">
            <AppWindow
              src="/editor.png"
              alt="The OpenPixel editor with a 32×32 treasure chest on the canvas while agents work on it"
              title="Pirate Treasure Chest"
              priority
            />
          </div>
        </section>

        {/* What you can make */}
        <section className="block">
          <div className="wrap center">
            <Headline lead="Start from a sentence." rest="Agents draft it, you perfect every pixel." />
            <Showcase />
          </div>
        </section>

        {/* Gallery */}
        <section className="block">
          <div className="wrap">
            <Headline lead="Made in OpenPixel," rest="yours to keep." />
          </div>
          <div className="gallery" tabIndex={0} aria-label="Pixel art made in OpenPixel">
            {GALLERY.map((g) => (
              <figure key={g.name} className={`gallery-card bg-${g.bg}`}>
                <div className="gallery-art">
                  <Sprite art={g.a} scale={g.scale} />
                </div>
                <figcaption>
                  {g.name}
                  <span>{g.note}</span>
                </figcaption>
              </figure>
            ))}
          </div>
          <p className="wrap gallery-note">
            Every sprite and model on this page was drawn by an agent through OpenPixel&apos;s MCP server. The script is
            in the repository.
          </p>
        </section>

        {/* Agents */}
        <section className="block" id="agents">
          <div className="wrap">
            <Headline lead="Draw with Claude, ChatGPT" rest="and any other agent." />
            <ul className="agent-grid">
              {AGENTS.map((a) => (
                <li key={a.name}>
                  {a.logo ? (
                    <Image src={`/agents/${a.logo}`} alt="" width={28} height={28} className={a.mono ? "mono-logo" : undefined} />
                  ) : (
                    <Sprite art={art.robot} scale={2} paused />
                  )}
                  <span>{a.name}</span>
                </li>
              ))}
            </ul>
            <p className="lead-text">
              Connect over MCP with one command,
              <br />
              or run OpenPixel headless from your scripts and CI.
            </p>
          </div>
        </section>

        {/* Agents on the canvas */}
        <section className="block">
          <div className="wrap">
            <Headline lead="Agents draw right on your canvas." rest="Watch every stroke, undo any of them." />
          </div>
          <div className="wrap-wide">
            <AppWindow
              src="/editor-3d.png"
              alt="The OpenPixel editor in 3D view with a voxel mushroom house"
              title="Mushroom house"
            />
          </div>
          <div className="wrap trio">
            <article className="card">
              <h3>Review loop.</h3>
              <p>Agents render their work from every angle, spot what looks off, and fix it before you ask.</p>
              <div className="card-art">
                <Sprite art={art.tree} scale={1} label="A voxel tree turning so every side can be checked" />
              </div>
            </article>
            <article className="card">
              <h3>Make 3D.</h3>
              <p>Turn any sprite into a voxel model with one click, or one tool call.</p>
              <div className="card-art make3d">
                <Sprite art={art.chest} scale={3} label="The flat treasure chest sprite" />
                <span className="arrow" aria-hidden="true" />
                <Sprite art={art.chest3d} scale={1} label="The same chest as a turning voxel model" />
              </div>
            </article>
            <article className="card">
              <h3>Works headless.</h3>
              <p>No window needed. Agents can build, render and export from a terminal or a CI job.</p>
              <div className="card-art">
                <pre className="mini-code">
                  <code>{`$ OpenPixel --mcp --headless
→ new_sprite   32×32
→ paint_slice  12 rows
→ export_gif   slime.gif`}</code>
                </pre>
              </div>
            </article>
          </div>
        </section>

        {/* Open source */}
        <section className="block">
          <div className="wrap">
            <Headline lead="Free and open source." rest="No account, no subscription, no catch." />
            <div className="quad">
              <div>
                <h3>MIT licence</h3>
                <p>Read it, fork it, build it into your own tools. The whole app is on GitHub.</p>
              </div>
              <div>
                <h3>Your files, plain JSON</h3>
                <p>An .openpixel file is readable JSON, so people, scripts and agents all understand it.</p>
              </div>
              <div>
                <h3>Nothing phones home</h3>
                <p>No sign-in, no analytics. The only request it makes is a daily check for updates.</p>
              </div>
              <div>
                <h3>Signed and notarized</h3>
                <p>Releases carry a Developer ID, are notarized by Apple, and every update is verified before it installs.</p>
              </div>
            </div>
            <div className="row-buttons">
              <a className="button" href={REPO_URL}>
                Read the code
              </a>
              <a className="button ghost" href={`${REPO_URL}/blob/main/CONTRIBUTING.md`}>
                Contribute
              </a>
            </div>
          </div>
        </section>

        {/* Features */}
        <section className="block">
          <div className="wrap">
            <Headline lead="The pixel tools you expect." rest="Feel right at home." />
            <div className="features">
              <article className="card feature">
                <h3>Native and fast</h3>
                <div className="feature-art">
                  <Sprite art={art.robot} scale={6} />
                </div>
                <p>Built in Swift for the Mac. It opens in a blink and stays out of your way.</p>
              </article>
              <article className="card feature">
                <h3>Layers and frames</h3>
                <div className="feature-art">
                  <Sprite art={art.campfire} scale={6} />
                </div>
                <p>Stack layers, add frames, set each frame&apos;s timing and press play.</p>
              </article>
              <article className="card feature">
                <h3>Onion skin</h3>
                <div className="feature-art onion">
                  <Sprite art={art.slime} scale={6} paused frame={1} className="ghost" />
                  <Sprite art={art.slime} scale={6} paused frame={2} />
                </div>
                <p>See the frame before and after while you draw the in-betweens.</p>
              </article>
              <article className="card feature">
                <h3>Mirror drawing</h3>
                <div className="feature-art mirror">
                  <Sprite art={art.robot} scale={6} paused />
                </div>
                <p>Draw one half and the other follows, across X, Y or Z.</p>
              </article>
              <article className="card feature">
                <h3>Palettes</h3>
                <div className="feature-art">
                  <div className="swatches" aria-hidden="true">
                    {DB32.map((c) => (
                      <i key={c} style={{ background: `#${c}` }} />
                    ))}
                  </div>
                </div>
                <p>DawnBringer, PICO-8, Endesga and your own. Swap a palette and every pixel follows.</p>
              </article>
              <article className="card feature">
                <h3>Isometric preview</h3>
                <div className="feature-art">
                  <Image src={art.mushroom.still!} alt="" width={124} height={129} className="pixel" />
                </div>
                <p>A live 2:1 pixel-art render of your model, sharp at every size.</p>
              </article>
              <article className="card feature">
                <h3>Sprite sheets</h3>
                <div className="feature-art">
                  <Image src={art.coin.src} alt="" width={art.coin.w * art.coin.frames * 2} height={art.coin.h * 2} className="pixel" />
                </div>
                <p>Every frame and every angle in one PNG, ready for your game engine.</p>
              </article>
              <article className="card feature">
                <h3>Animated GIFs</h3>
                <div className="feature-art">
                  <Sprite art={art.potion} scale={6} />
                </div>
                <p>Export animations and turntables to share anywhere.</p>
              </article>
              <article className="card feature">
                <h3>MagicaVoxel and OBJ</h3>
                <div className="feature-art">
                  <Sprite art={art.robot3d} scale={1} />
                </div>
                <p>Open and save .vox, export OBJ for Blender, Unity and Godot.</p>
              </article>
            </div>
            <ul className="more">
              {MORE.map((m) => (
                <li key={m}>{m}</li>
              ))}
            </ul>
            <p className="more-end">This list goes on and on…</p>
          </div>
        </section>

        {/* Closing */}
        <section className="block closing">
          <div className="wrap center">
            <div className="closing-sprites" aria-hidden="true">
              <Sprite art={art.coin} scale={4} />
              <Sprite art={art.slime} scale={4} />
              <Sprite art={art.potion} scale={4} />
            </div>
            <Headline lead="Start drawing" rest="your ideas today." />
            <p className="lead-text">Draw with agents, refine every pixel, and ship it straight to your game.</p>
            <div className="row-buttons center">
              <a className="button primary large" href="/download/mac">
                Download for macOS
              </a>
              <Link className="button large" href="/compare">
                Compare editors
              </Link>
            </div>
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
