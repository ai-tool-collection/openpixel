import type { Metadata } from "next";
import JsonLd from "@/components/JsonLd";
import { breadcrumbJsonLd, pageMeta } from "@/lib/seo";
import Image from "next/image";
import Link from "next/link";
import { Footer, Header } from "@/components/Chrome";
import { COMPETITORS, KINDS } from "@/lib/compare";

export const metadata: Metadata = pageMeta({
  path: "/compare",
  title: "Compare OpenPixel with other pixel art editors",
  absoluteTitle: true,
  description:
    "OpenPixel next to Aseprite, LibreSprite, Pixelorama, Piskel, Pixilart, PixelLab, Pyxel Edit, Pro Motion NG, MagicaVoxel, Goxel and more, from AI agents and 3D to price and licence.",
});

export default function Compare() {
  return (
    <>
      <Header />
      <JsonLd data={breadcrumbJsonLd([["Compare", "/compare"]])} />
      <main className="cmp">
        <section className="cmp-hero">
          <Image className="cmp-mark" src="/dock/openpixel.png" alt="" width={128} height={128} priority unoptimized />
          <h1 className="cmp-title">Compare OpenPixel</h1>
          <p className="cmp-lede">
            See how OpenPixel compares with other pixel art and voxel editors, from AI agents and 3D to price and
            licence.
          </p>
        </section>
        {KINDS.map(({ kind, title }) => (
          <section key={kind} className="cmp-group" aria-labelledby={`cmp-${kind}`}>
            <h2 id={`cmp-${kind}`} className="cmp-group-title">
              {title}
            </h2>
            <div className="cmp-cards">
              {COMPETITORS.filter((c) => c.kind === kind).map((c) => (
                <Link key={c.slug} href={`/compare/${c.slug}`} className="cmp-card">
                  <div className="cmp-card-logos" aria-hidden="true">
                    <Image src="/dock/openpixel.png" alt="" width={128} height={128} unoptimized />
                    <span>vs</span>
                    <Image
                      className={c.pixelLogo ? "pixel" : undefined}
                      src={c.logo}
                      alt=""
                      width={128}
                      height={128}
                      unoptimized
                    />
                  </div>
                  <h3>OpenPixel vs {c.name}</h3>
                  <p>{c.card}</p>
                </Link>
              ))}
            </div>
          </section>
        ))}
      </main>
      <Footer />
    </>
  );
}
