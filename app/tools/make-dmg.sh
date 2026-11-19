#!/bin/sh
# Packs OpenPixel.app into a disk image with an Applications shortcut (drag to install).
#   tools/make-dmg.sh [output.dmg]     default: dist/OpenPixel-<version>.dmg
set -e
cd "$(dirname "$0")/.."
VERSION="$(tr -d ' \n' < VERSION)"
DMG="${1:-dist/OpenPixel-$VERSION.dmg}"
mkdir -p "$(dirname "$DMG")"
WORK="$(mktemp -d)"
STAGE="$WORK/OpenPixel"
mkdir -p "$STAGE"
ditto OpenPixel.app "$STAGE/OpenPixel.app"
ln -s /Applications "$STAGE/Applications"
rm -f "$DMG"
hdiutil create -quiet -volname "OpenPixel $VERSION" -srcfolder "$STAGE" -ov -format UDZO "$DMG"
rm -rf "$WORK"
echo "Built $(pwd)/$DMG"
