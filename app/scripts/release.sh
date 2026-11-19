#!/bin/sh
# Builds a release of OpenPixel: universal app → Developer ID signature → dist/OpenPixel.dmg → notarized and
# stapled → dist/appcast.xml for Sparkle. Run by .github/workflows/release.yml when a v* tag is pushed; also
# runs on a Mac (without the signing variables it makes an unsigned test build and says so).
#
#   scripts/release.sh 1.2.0
#
# Environment (all optional for a local test build; CI sets them from the `release` environment secrets):
#   SIGN_ID            "Developer ID Application: Name (TEAMID)" — a certificate in the keychain
#   NOTARY_KEY_PATH    App Store Connect API key (.p8) for notarytool
#   NOTARY_KEY_ID      its key ID
#   NOTARY_ISSUER_ID   its issuer ID
#   SPARKLE_KEY_FILE   Sparkle EdDSA private key file; without it, the key in the login keychain is used
#   REPO               GitHub owner/name (default sophne/openpixel)
#   RELEASE_NOTES      plain-text notes shown in the update window (default: link to the release page)
#
# Nothing secret is written to disk by this script, and no secret is ever printed.
set -eu
cd "$(dirname "$0")/.."

VERSION="${1:?usage: scripts/release.sh <version, e.g. 1.2.0>}"
VERSION="${VERSION#v}"
case "$VERSION" in
  [0-9]*.[0-9]*.[0-9]*) ;;
  *) echo "error: version must look like 1.2.3 (got $VERSION)" >&2; exit 1 ;;
esac
REPO="${REPO:-sophne/openpixel}"
SIGN_ID="${SIGN_ID:-}"
APP="OpenPixel.app"
DMG="dist/OpenPixel.dmg"

# Build numbers must only ever go up, or Sparkle won't offer the update: use the commit count.
BUILD_NUMBER="$(git rev-list --count HEAD)"
echo "$VERSION" > VERSION
export BUILD_NUMBER
UNIVERSAL=1 SIGN_ID=- sh build.sh

# --- Signature: inside out, hardened runtime, secure timestamp (what notarization requires) ---
if [ -n "$SIGN_ID" ]; then
  sign() { codesign --force --options runtime --timestamp --sign "$SIGN_ID" "$@"; }
  FW="$APP/Contents/Frameworks/Sparkle.framework/Versions/B"
  sign "$FW/XPCServices/Installer.xpc"
  sign --preserve-metadata=entitlements "$FW/XPCServices/Downloader.xpc"
  sign "$FW/Autoupdate"
  sign "$FW/Updater.app"
  sign "$APP/Contents/Frameworks/Sparkle.framework"
  sign "$APP"
  codesign --verify --strict --deep --verbose=2 "$APP"
else
  echo "warning: SIGN_ID not set — this build is ad-hoc signed and will be blocked by Gatekeeper on other Macs."
fi

# --- Disk image (drag to Applications) ---
rm -f "$DMG"
sh tools/make-dmg.sh "$DMG"
if [ -n "$SIGN_ID" ]; then
  codesign --force --timestamp --sign "$SIGN_ID" "$DMG"
fi

# --- Notarization ---
if [ -n "$SIGN_ID" ] && [ -n "${NOTARY_KEY_PATH:-}" ]; then
  xcrun notarytool submit "$DMG" --key "$NOTARY_KEY_PATH" --key-id "${NOTARY_KEY_ID:?}" --issuer "${NOTARY_ISSUER_ID:?}" --wait
  xcrun stapler staple "$DMG"
  xcrun stapler validate "$DMG"
  spctl --assess --type open --context context:primary-signature --verbose=2 "$DMG"
else
  echo "warning: not notarized (needs SIGN_ID and NOTARY_KEY_PATH)."
fi

# --- Sparkle appcast (one entry: the version being released) ---
TOOLS=".build/artifacts/sparkle/Sparkle/bin"
[ -x "$TOOLS/sign_update" ] || swift package resolve
if [ -n "${SPARKLE_KEY_FILE:-}" ]; then
  SIG="$("$TOOLS/sign_update" --ed-key-file "$SPARKLE_KEY_FILE" "$DMG")"
else
  SIG="$("$TOOLS/sign_update" --account openpixel "$DMG")"
fi
# sign_update prints: sparkle:edSignature="…" length="…"
case "$SIG" in *sparkle:edSignature=*length=*) ;; *) echo "error: sign_update gave no signature" >&2; exit 1 ;; esac

PAGE="https://github.com/$REPO/releases/tag/v$VERSION"
NOTES="${RELEASE_NOTES:-OpenPixel $VERSION. Release notes: $PAGE}"
# Keep the notes from breaking out of their CDATA block.
NOTES="$(printf '%s' "$NOTES" | sed 's/]]>/]] >/g')"
PUBDATE="$(LC_ALL=C date -u '+%a, %d %b %Y %H:%M:%S +0000')"

cat > dist/appcast.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>OpenPixel</title>
    <link>https://github.com/$REPO</link>
    <item>
      <title>OpenPixel $VERSION</title>
      <pubDate>$PUBDATE</pubDate>
      <sparkle:version>$BUILD_NUMBER</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
      <sparkle:fullReleaseNotesLink>$PAGE</sparkle:fullReleaseNotesLink>
      <description sparkle:format="plain-text"><![CDATA[$NOTES]]></description>
      <enclosure url="https://github.com/$REPO/releases/download/v$VERSION/OpenPixel.dmg" $SIG type="application/octet-stream"/>
    </item>
  </channel>
</rss>
EOF
xmllint --noout dist/appcast.xml
echo "Release $VERSION (build $BUILD_NUMBER): $(pwd)/$DMG and $(pwd)/dist/appcast.xml"
