import type { Metadata } from "next";
import { DOWNLOAD_URL, REPO_URL, X_URL } from "@/lib/github";

/**
 * Search and social metadata shared by every page. The preview cards in public/og are made by
 * scripts/og/make-og.sh; bump CARD_VERSION when you regenerate them so X, Slack and others fetch the new ones.
 */

export const SITE_URL = (process.env.NEXT_PUBLIC_SITE_URL || "http://localhost:3000").replace(/\/$/, "");
export const SITE_NAME = "OpenPixel";
export const X_HANDLE = `@${X_URL.replace(/\/$/, "").split("/").pop()}`;

const CARD_VERSION = 2;
const CARD_ALT =
  "OpenPixel is an agentic pixel editor for sprites and voxel worlds: a 32×32 pixel-art treasure chest drawn in OpenPixel, next to the prompt that made it.";
export const OG_IMAGE = { url: `/og/opengraph.png?v=${CARD_VERSION}`, width: 1200, height: 630, alt: CARD_ALT, type: "image/png" };
export const TWITTER_IMAGE = { url: `/og/twitter.png?v=${CARD_VERSION}`, width: 1200, height: 600, alt: CARD_ALT };

/** Title, description, canonical address and matching Open Graph and X fields for one page. */
export function pageMeta({
  path,
  title,
  description,
  absoluteTitle = false,
}: {
  path: string;
  title: string;
  description: string;
  /** Use the title as written, without " · OpenPixel" after it. */
  absoluteTitle?: boolean;
}): Metadata {
  const full = absoluteTitle ? title : `${title} · ${SITE_NAME}`;
  return {
    title: absoluteTitle ? { absolute: title } : title,
    description,
    alternates: { canonical: path },
    openGraph: { title: full, description, url: path, siteName: SITE_NAME, type: "website", locale: "en_US", images: [OG_IMAGE] },
    twitter: {
      card: "summary_large_image",
      title: full,
      description,
      site: X_HANDLE,
      creator: X_HANDLE,
      images: [TWITTER_IMAGE],
    },
  };
}

const abs = (path: string) => `${SITE_URL}${path}`;

const ORG_ID = abs("/#organization");

/** Who makes OpenPixel and where to find it. */
const organization = {
  "@type": "Organization",
  "@id": ORG_ID,
  name: SITE_NAME,
  url: abs("/"),
  logo: abs("/icon.png"),
  sameAs: [REPO_URL, X_URL],
};

/** Structured data for the home page: the site, its publisher and the app itself. */
export function homeJsonLd(version?: string) {
  return {
    "@context": "https://schema.org",
    "@graph": [
      { "@type": "WebSite", "@id": abs("/#website"), name: SITE_NAME, url: abs("/"), publisher: { "@id": ORG_ID } },
      organization,
      {
        "@type": "SoftwareApplication",
        "@id": abs("/#app"),
        name: SITE_NAME,
        description:
          "Free, open-source pixel art and voxel editor for the Mac with a built-in MCP server, so AI agents can draw, review and refine sprites, animations and 3D models with you.",
        applicationCategory: "DesignApplication",
        applicationSubCategory: "Pixel art and voxel editor",
        operatingSystem: "macOS 13 or later",
        processorRequirements: "Apple silicon or Intel",
        ...(version ? { softwareVersion: version } : {}),
        url: abs("/"),
        downloadUrl: DOWNLOAD_URL,
        installUrl: abs("/downloads"),
        releaseNotes: abs("/changelog"),
        image: abs("/icon.png"),
        screenshot: [abs("/editor.png"), abs("/editor-3d.png")],
        isAccessibleForFree: true,
        license: `${REPO_URL}/blob/main/LICENSE`,
        offers: { "@type": "Offer", price: "0", priceCurrency: "USD" },
        author: { "@id": ORG_ID },
        publisher: { "@id": ORG_ID },
        featureList: [
          "2D pixel art canvas with layers, frames, onion skin and palettes",
          "3D voxel models with isometric pixel-art previews",
          "Built-in MCP server for Claude, Codex, Cursor and other AI agents",
          "Exports to PNG, SVG, animated GIF, sprite sheets, MagicaVoxel .vox and OBJ",
        ],
      },
    ],
  };
}

/** Breadcrumbs from the home page down to this page; `trail` is [name, path] pairs after Home. */
export function breadcrumbJsonLd(trail: [string, string][]) {
  return {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: [["Home", "/"] as [string, string], ...trail].map(([name, path], i) => ({
      "@type": "ListItem",
      position: i + 1,
      name,
      item: abs(path),
    })),
  };
}
