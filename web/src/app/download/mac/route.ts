import { DOWNLOAD_URL } from "@/lib/github";

// /download/mac always sends people to the newest stable OpenPixel.dmg on GitHub.
export function GET() {
  return new Response(null, { status: 302, headers: { Location: DOWNLOAD_URL, "Cache-Control": "no-store" } });
}
