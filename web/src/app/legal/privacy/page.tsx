import type { Metadata } from "next";
import { Footer, Header, Headline } from "@/components/Chrome";
import { REPO_URL } from "@/lib/github";

export const metadata: Metadata = { title: "Privacy", description: "What OpenPixel and this website collect: almost nothing." };

export default function Privacy() {
  return (
    <>
      <Header />
      <main>
        <section className="page-head wrap">
          <Headline as="h1" lead="Privacy." rest="Short, because there is little to say." />
        </section>
        <article className="prose wrap">
          <p className="updated">Last updated 19 November 2026</p>
          <p>
            OpenPixel is free, open-source software made by the OpenPixel maintainers (
            <a href="https://github.com/sophne">sophne on GitHub</a>). We don&apos;t sell anything, don&apos;t run ads and
            don&apos;t want your data. This page explains exactly what the app and this website do.
          </p>

          <h2>The OpenPixel app</h2>
          <ul>
            <li>No account, no sign-in, no analytics, no crash reporting, no tracking.</li>
            <li>Your sprites and models stay on your Mac, in the files and folders you choose.</li>
            <li>
              <strong>Update checks.</strong> Once a day the app downloads a small file (appcast.xml) from GitHub to see
              whether a new version exists, and downloads the update from GitHub if you install it. GitHub receives your IP
              address and the app&apos;s version, as with any download. The app sends no other information about your Mac.
              To turn automatic checks off, run{" "}
              <code>defaults write com.sophne.openpixel SUEnableAutomaticChecks -bool false</code>.
            </li>
            <li>
              <strong>AI agents.</strong> The MCP server runs on your Mac. What an agent sees and sends to its provider
              (for example Anthropic, OpenAI or Cursor) is decided by that agent and covered by its provider&apos;s terms
              and privacy policy, not ours.
            </li>
            <li>
              <strong>Agents page.</strong> To show which agents are set up, the app reads their settings files on your Mac.
              It never changes them and never sends them anywhere.
            </li>
            <li>
              <strong>HTTP mode.</strong> <code>--mcp-http</code> listens on your Mac only. It becomes reachable from
              elsewhere only if you start a tunnel yourself; that tunnel provider&apos;s terms then apply.
            </li>
          </ul>

          <h2>This website</h2>
          <ul>
            <li>No cookies, no analytics, no tracking pixels, no third-party scripts. Fonts are served from this site.</li>
            <li>
              Like every web server, ours briefly keeps standard request logs (IP address, time, page, browser) to keep
              the site running and secure. They are not used for anything else and are deleted regularly.
            </li>
            <li>
              Release details shown here are fetched by our server from GitHub, so your browser doesn&apos;t contact
              GitHub until you click a download or GitHub link. Downloads are served by GitHub under the{" "}
              <a href="https://docs.github.com/site-policy/privacy-policies/github-general-privacy-statement">
                GitHub Privacy Statement
              </a>
              .
            </li>
          </ul>

          <h2>Your rights</h2>
          <p>
            Depending on where you live (for example under the GDPR), you can ask what personal data we hold about you,
            and have it corrected or deleted. Since we only hold short-lived server logs, there is usually nothing to
            return. You can also complain to your data protection authority.
          </p>

          <h2>Contact</h2>
          <p>
            Questions about privacy: open an issue on <a href={`${REPO_URL}/issues`}>GitHub</a>, or report something
            sensitive privately through <a href={`${REPO_URL}/security/advisories/new`}>GitHub&apos;s private reporting</a>.
          </p>

          <h2>Changes</h2>
          <p>If this changes, we&apos;ll update this page and its date. The history is public in the repository.</p>
        </article>
      </main>
      <Footer />
    </>
  );
}
