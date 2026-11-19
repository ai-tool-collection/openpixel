# Releasing OpenPixel

A release is one command. Merging pull requests never ships anything by itself: `main` collects merged work
until a maintainer tags it.

```sh
cd app && make release-tag VERSION=1.2.0
```

That checks you're on a clean, up-to-date `main` with green CI, shows what changed since the last release, and
pushes the tag `v1.2.0`. The [release workflow](.github/workflows/release.yml) then:

1. builds a universal app (Apple silicon and Intel) with build number = commit count,
2. signs it with the Developer ID and hardened runtime, packs `OpenPixel.dmg`, notarizes and staples it,
3. signs the update for Sparkle and writes `appcast.xml`,
4. creates the GitHub release with both files and notes listing every merged pull request and contributor.

Within a day every installed copy offers the update, and the website's Download button
(`/releases/latest/download/OpenPixel.dmg`) serves the new version straight away.

A tag with a dash, like `v1.3.0-beta.1`, becomes a pre-release: installed apps and the website ignore it, so you can
test a build before shipping it.

## Who can release

- Anyone can open a pull request from a fork. CI runs without access to any secret.
- Only repository admins can push `v*` tags (tag ruleset), so only they can release.
- The signing secrets live in the `release` environment, which only `v*` tags can use.
- `main` only changes through squash-merged pull requests with green CI and a code owner's review.

`sh .github/setup-repo.sh` applies all of these settings.

## One-time setup

### 1. Apple Developer ID

1. Join the [Apple Developer Program](https://developer.apple.com/programs/) (as an organisation for sophne,
   which needs a D-U-N-S number, or as an individual).
2. Certificates → **Developer ID Application** → create it, install it, then in Keychain Access export it with its
   private key as `developer-id.p12` with a strong password.
3. App Store Connect → Users and Access → Integrations → App Store Connect API → create a key with the
   **Developer** role. Download the `.p8` (only possible once) and note its Key ID and Issuer ID.

### 2. Sparkle update key

The private key is already in your login keychain (account `openpixel`); its public half is `SUPublicEDKey` in
`app/Info.plist`. Export it once for CI, and keep a copy in your password manager: if it's lost, installed apps can
never update again.

```sh
cd app && swift package resolve
.build/artifacts/sparkle/Sparkle/bin/generate_keys --account openpixel -x sparkle-private.txt
```

### 3. GitHub secrets (in the `release` environment)

```sh
sh .github/setup-repo.sh                      # creates the environment and protections first
E="--env release --repo sophne/openpixel"
base64 -i developer-id.p12 | gh secret set MACOS_CERT_P12 $E
gh secret set MACOS_CERT_PASSWORD $E          # prompts for the .p12 password
openssl rand -base64 24 | gh secret set KEYCHAIN_PASSWORD $E
base64 -i AuthKey_XXXXXXXXXX.p8 | gh secret set NOTARY_KEY_P8 $E
gh secret set NOTARY_KEY_ID $E                # prompts
gh secret set NOTARY_ISSUER_ID $E             # prompts
gh secret set SPARKLE_PRIVATE_KEY $E < sparkle-private.txt
rm developer-id.p12 sparkle-private.txt AuthKey_*.p8   # after saving them in your password manager
```

### 4. Website on Coolify

New resource → your GitHub app → `sophne/openpixel`, branch `main`:

- Build pack: **Dockerfile**, base directory `/web`, port `3000`
- Watch paths: `web/**` (app-only changes don't redeploy the site)
- Build variable `NEXT_PUBLIC_SITE_URL=https://your-domain`; optional runtime secret `GITHUB_TOKEN` (fine-grained,
  no permissions) for a higher GitHub API limit
- Domain with HTTPS; the container has a health check built in

## Going public (checklist)

- [ ] `gitleaks git` on the repository finds nothing
- [ ] Secrets set (above); `sh .github/setup-repo.sh` ran without errors
- [ ] Settings → General → Danger zone → **Change visibility → Public**
- [ ] Run `sh .github/setup-repo.sh` again (secret scanning and private reporting need a public repository)
- [ ] `make release-tag VERSION=1.0.0`, then check: the release has `OpenPixel.dmg` and `appcast.xml`; the DMG from
      the website opens without a Gatekeeper warning
- [ ] Deploy the website

The download links work only once the repository is public: GitHub serves release files of private repositories
to members only.

## Building a release by hand

`make release VERSION=1.2.0` runs the same script locally. With `SIGN_ID`, `NOTARY_KEY_PATH`, `NOTARY_KEY_ID` and
`NOTARY_ISSUER_ID` set it signs and notarizes; without them it makes an unsigned test build and says so.
