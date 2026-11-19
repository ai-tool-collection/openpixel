import type { Metadata, Viewport } from "next";
import { Inter, JetBrains_Mono } from "next/font/google";
import "./globals.css";

// Fonts are downloaded at build time and served from this site: visitors make no requests to Google.
const sans = Inter({ subsets: ["latin"], variable: "--font-sans", display: "swap", axes: ["opsz"] });
const mono = JetBrains_Mono({ subsets: ["latin"], variable: "--font-mono", display: "swap", weight: ["400", "500"] });

const site = process.env.NEXT_PUBLIC_SITE_URL || "http://localhost:3000";

export const metadata: Metadata = {
  metadataBase: new URL(site),
  title: { default: "OpenPixel: the agentic pixel editor for Mac", template: "%s · OpenPixel" },
  description:
    "Free, open-source pixel art and voxel editor for the Mac with a built-in MCP server. Draw sprites, animations and 3D models with Claude, ChatGPT, Cursor or any agent.",
  icons: { icon: "/icon.png", apple: "/icon.png" },
  openGraph: {
    title: "OpenPixel",
    description: "The agentic pixel editor for sprites and voxel worlds. Free and open source.",
    images: [{ url: "/editor.png", width: 1440, height: 900, alt: "The OpenPixel editor" }],
    type: "website",
  },
};

export const viewport: Viewport = { themeColor: "#1e1e1e", colorScheme: "dark" };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${sans.variable} ${mono.variable}`}>
      <body>{children}</body>
    </html>
  );
}
