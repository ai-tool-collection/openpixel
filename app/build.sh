#!/bin/sh
# Builds OpenPixel.app next to this script (and build/OpenPixel, the bare program with its framework).
# Needs the Xcode command line tools (Swift 5.9 or newer).
set -e
cd "$(dirname "$0")"

VERSION="$(tr -d ' \n' < VERSION)"
BUILD_NUMBER="${BUILD_NUMBER:-$(echo "$VERSION" | awk -F. '{ printf "%d", $1 * 10000 + $2 * 100 + $3 }')}"

# UNIVERSAL=1 builds Apple silicon and Intel slices and joins them (release builds do this).
if [ "${UNIVERSAL:-0}" = "1" ]; then
  swift build -c release --arch arm64
  swift build -c release --arch x86_64
  BIN=".build/universal-release"
  rm -rf "$BIN" && mkdir -p "$BIN"
  lipo -create .build/arm64-apple-macosx/release/OpenPixel .build/x86_64-apple-macosx/release/OpenPixel -output "$BIN/OpenPixel"
  # Sparkle ships as one framework holding both architectures.
  ditto .build/arm64-apple-macosx/release/Sparkle.framework "$BIN/Sparkle.framework"
else
  swift build -c release
  BIN="$(swift build -c release --show-bin-path)"
fi

APP="OpenPixel.app"
STAGE="$APP.tmp"
rm -rf "$STAGE"
mkdir -p "$STAGE/Contents/MacOS" "$STAGE/Contents/Resources" "$STAGE/Contents/Frameworks"
cp "$BIN/OpenPixel" "$STAGE/Contents/MacOS/OpenPixel"
cp -R web "$STAGE/Contents/Resources/web"
cp Info.plist "$STAGE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" -c "Set :CFBundleVersion $BUILD_NUMBER" "$STAGE/Contents/Info.plist"

# Sparkle (automatic updates), keeping its symlinks.
ditto "$BIN/Sparkle.framework" "$STAGE/Contents/Frameworks/Sparkle.framework"

# App icon from assets/icon (the single-pixel OpenPixel icon).
ICONSET="$(mktemp -d)/AppIcon.iconset"
mkdir -p "$ICONSET"
for s in 16 32 128 256 512; do
  cp "assets/icon/icon_$s.png" "$ICONSET/icon_${s}x${s}.png"
  cp "assets/icon/icon_$((s * 2)).png" "$ICONSET/icon_${s}x${s}@2x.png"
done
iconutil -c icns "$ICONSET" -o "$STAGE/Contents/Resources/AppIcon.icns" || echo "warning: no app icon"

# Ad-hoc signature so macOS runs it locally (no developer account or secrets involved).
# Public releases are signed with a Developer ID and notarized by scripts/release.sh (see RELEASING.md).
SIGN_ID="${SIGN_ID:--}"
if [ "$SIGN_ID" = "-" ]; then
  # Ad-hoc: no hardened runtime, which would refuse to load the ad-hoc-signed Sparkle framework.
  codesign --force --deep --sign - "$STAGE"
else
  codesign --force --deep --options runtime --timestamp --sign "$SIGN_ID" "$STAGE"
fi

rm -rf "$APP"
mv "$STAGE" "$APP"

# The bare program (used by automated checks) is the only file in build/; it finds web/ one level up and
# the framework in Frameworks/ (its @executable_path/../Frameworks search path), like inside the app.
mkdir -p build Frameworks
rm -rf build/Sparkle.framework Frameworks/Sparkle.framework
cp "$BIN/OpenPixel" build/OpenPixel
ditto "$BIN/Sparkle.framework" Frameworks/Sparkle.framework
rm -f openpixel
echo "Built $(pwd)/$APP (version $VERSION, build $BUILD_NUMBER)"
