// Release data from GitHub, fetched on the server and cached, so visitors never call GitHub themselves.

export const REPO = process.env.GITHUB_REPO || "sophne/openpixel";
export const REPO_URL = `https://github.com/${REPO}`;
export const X_URL = process.env.NEXT_PUBLIC_X_URL || "https://x.com/eminvkc";
/**
 * Whether releases are signed with a Developer ID and notarized by Apple. Until then builds are ad-hoc signed and
 * macOS asks people to confirm the first launch; the site says so. Set NEXT_PUBLIC_NOTARIZED=true once releases
 * are notarized (see RELEASING.md).
 */
export const NOTARIZED = process.env.NEXT_PUBLIC_NOTARIZED === "true";
/** Always the newest stable release: GitHub redirects this to the current OpenPixel.dmg. */
export const DOWNLOAD_URL = `${REPO_URL}/releases/latest/download/OpenPixel.dmg`;

export type Release = {
  tag: string;
  version: string;
  name: string;
  date: string;
  url: string;
  notes: string;
  prerelease: boolean;
  dmgSize?: number;
};

type ApiAsset = { name: string; size: number };
type ApiRelease = {
  tag_name: string;
  name: string | null;
  published_at: string | null;
  html_url: string;
  body: string | null;
  prerelease: boolean;
  draft: boolean;
  assets: ApiAsset[];
};

async function api<T>(path: string): Promise<T | null> {
  const headers: Record<string, string> = {
    Accept: "application/vnd.github+json",
    "X-GitHub-Api-Version": "2022-11-28",
    "User-Agent": "openpixel-website",
  };
  if (process.env.GITHUB_TOKEN) headers.Authorization = `Bearer ${process.env.GITHUB_TOKEN}`;
  try {
    const res = await fetch(`https://api.github.com/repos/${REPO}${path}`, {
      headers,
      next: { revalidate: 600 },
      signal: AbortSignal.timeout(5000),
    });
    if (!res.ok) return null;
    return (await res.json()) as T;
  } catch {
    // GitHub unreachable, rate-limited, or the repository is still private: the page shows its fallback.
    return null;
  }
}

function toRelease(r: ApiRelease): Release {
  return {
    tag: r.tag_name,
    version: r.tag_name.replace(/^v/, ""),
    name: r.name || r.tag_name,
    date: r.published_at ?? "",
    url: r.html_url,
    notes: r.body ?? "",
    prerelease: r.prerelease,
    dmgSize: r.assets.find((a) => a.name === "OpenPixel.dmg")?.size,
  };
}

export async function latestRelease(): Promise<Release | null> {
  const r = await api<ApiRelease>("/releases/latest");
  return r ? toRelease(r) : null;
}

export async function allReleases(): Promise<Release[]> {
  const list = await api<ApiRelease[]>("/releases?per_page=30");
  return (list ?? []).filter((r) => !r.draft).map(toRelease);
}

export function formatSize(bytes?: number): string | null {
  if (!bytes) return null;
  return `${(bytes / 1024 / 1024).toFixed(1)} MB`;
}

export function formatDate(iso: string): string {
  if (!iso) return "";
  return new Date(iso).toLocaleDateString("en-GB", { day: "numeric", month: "long", year: "numeric" });
}
