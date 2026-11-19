import type { MetadataRoute } from "next";
import { SITE_URL } from "@/lib/seo";

export default function robots(): MetadataRoute.Robots {
  return {
    // /downloads/mac only redirects to the disk image on GitHub: nothing there to index.
    rules: { userAgent: "*", allow: "/", disallow: "/downloads/mac" },
    sitemap: `${SITE_URL}/sitemap.xml`,
    host: SITE_URL,
  };
}
