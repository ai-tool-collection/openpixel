import type { Metadata, Viewport } from "next";
import { Schibsted_Grotesk, JetBrains_Mono } from "next/font/google";
import "./globals.css";

// Fonts are downloaded at build time and served from this site: visitors make no requests to Google.
const sans = Schibsted_Grotesk({ subsets: ["latin"], variable: "--font-sans", display: "swap" });
const mono = JetBrains_Mono({ subsets: ["latin"], variable: "--font-mono", display: "swap", weight: ["400", "500"] });

const site = process.env.NEXT_PUBLIC_SITE_URL || "http://localhost:3000";

export const metadata: Metadata = {
  metadataBase: new URL(site),
  title: "OpenPixel — pixel art with your AI agent",
  description:
    "A free, open-source Mac app for 2D sprites and 3D voxel models, with an MCP server built in so AI agents can draw, review and fix pixel art with you.",
  icons: { icon: "/icon.png", apple: "/icon.png" },
  openGraph: {
    title: "OpenPixel",
    description: "Pixel art and voxel models on the Mac, drawn with you or by your AI agent.",
    images: [{ url: "/editor.png", width: 1440, height: 900, alt: "The OpenPixel editor with a pixel-art treasure chest" }],
    type: "website",
  },
};

export const viewport: Viewport = { themeColor: "#e9eaed" };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${sans.variable} ${mono.variable}`}>
      <body>{children}</body>
    </html>
  );
}
