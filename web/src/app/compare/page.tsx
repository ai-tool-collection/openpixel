import type { Metadata } from "next";
import Link from "next/link";
import Sprite from "@/components/Sprite";
import { Footer, Header, Headline } from "@/components/Chrome";
import { art } from "@/lib/art";
import { REPO_URL } from "@/lib/github";

export const metadata: Metadata = {
  title: "Compare",
  description: "How OpenPixel compares with Aseprite, Pixelorama and MagicaVoxel: price, licence, 2D and 3D, and AI agents.",
};

const EDITORS = ["OpenPixel", "Aseprite", "Pixelorama", "MagicaVoxel"];

// Facts about other editors come from their own websites and stores. Keep the date below in step.
const ROWS: { label: string; cells: [string, string, string, string]; yes?: boolean[] }[] = [
  { label: "Price", cells: ["Free", "Paid (about $20), or compile the source for personal use", "Free, donations welcome", "Free"], yes: [true] },
  {
    label: "Source code",
    cells: ["Open source, MIT", "Source available under an EULA that forbids redistribution", "Open source, MIT", "Closed source"],
    yes: [true],
  },
  { label: "Platforms", cells: ["macOS", "Windows, macOS, Linux", "Windows, macOS, Linux, web", "Windows, macOS"] },
  { label: "2D sprites and animation", cells: ["Yes", "Yes", "Yes", "No"], yes: [true, true, true] },
  { label: "3D voxel models", cells: ["Yes, with the same tools as 2D", "No", "3D shape layers in 2D scenes", "Yes"], yes: [true, false, false, true] },
  {
    label: "AI agents",
    cells: ["Built-in MCP server; edits appear live and can be undone", "Through third-party tools", "Not built in", "Not built in"],
    yes: [true],
  },
  { label: "Automation", cells: ["MCP, headless mode", "Lua scripts, command line", "Extensions", "Console commands"] },
  { label: "Exports", cells: ["PNG, GIF, sprite sheets, SVG, HTML, .vox, OBJ", "PNG, GIF, sprite sheets and more", "PNG, GIF, sprite sheets and more", ".vox, OBJ, PLY and more"] },
  { label: "File format", cells: ["Plain JSON (.openpixel), also .vox", "Aseprite file (.aseprite)", "Pixelorama project (.pxo)", "MagicaVoxel file (.vox)"] },
];

export default function Compare() {
  return (
    <>
      <Header />
      <main>
        <section className="page-head wrap">
          <Sprite art={art.robot3d} scale={1} label="The OpenPixel agent as a turning voxel model" />
          <Headline as="h1" lead="OpenPixel compared" rest="with the editors you know." />
          <p className="lead-text">
            Every tool here makes great pixel art. OpenPixel is the one built for working with AI agents, in 2D and 3D,
            for free.
          </p>
        </section>

        <div className="wrap">
          <div className="compare-wrap">
            <table className="compare">
              <thead>
                <tr>
                  <th scope="col">
                    <span className="sr-only">Feature</span>
                  </th>
                  {EDITORS.map((e, i) => (
                    <th key={e} scope="col" className={i === 0 ? "us" : undefined}>
                      {e}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {ROWS.map((r) => (
                  <tr key={r.label}>
                    <th scope="row">{r.label}</th>
                    {r.cells.map((c, i) => (
                      <td key={i} className={`${i === 0 ? "us" : ""}${r.yes?.[i] ? " yes-cell" : ""}`.trim() || undefined}>
                        {r.yes?.[i] ? <span className="yes">{c}</span> : c}
                      </td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <p className="compare-note">
            Details about other editors are taken from their own websites and stores, checked in November 2026. Spotted
            something out of date? <a href={`${REPO_URL}/issues`}>Tell us on GitHub</a>. Product names are trademarks of
            their owners.
          </p>

          <div className="why">
            <article className="card">
              <h3>Agents are built in.</h3>
              <p>No plugin, no bridge script. Connect Claude, ChatGPT, Cursor or any MCP client in one line.</p>
            </article>
            <article className="card">
              <h3>2D and 3D in one app.</h3>
              <p>Draw a sprite, make it 3D, and export sheets, GIFs or .vox from the same file.</p>
            </article>
            <article className="card">
              <h3>Free for good.</h3>
              <p>MIT licensed and on GitHub. No paid tier to unlock, nothing to subscribe to.</p>
            </article>
          </div>

          <div className="row-buttons center">
            <a className="button primary large" href="/download/mac">
              Download for macOS
            </a>
            <Link className="button large" href="/">
              See all features
            </Link>
          </div>
        </div>
      </main>
      <Footer />
    </>
  );
}
