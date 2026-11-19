#!/bin/sh
# Renders scripts/og/card.html to the social preview images every page links to (lib/seo.ts):
#   public/og/opengraph.png  1200×630 (Open Graph: Facebook, LinkedIn, Slack, iMessage…)
#   public/og/twitter.png     1200×600 (X summary_large_image)
# Needs Google Chrome. Run from web/: sh scripts/og/make-og.sh
set -eu
cd "$(dirname "$0")/../.."
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
CARD="file://$PWD/scripts/og/card.html"

shot() { # height, output
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
    --allow-file-access-from-files --virtual-time-budget=8000 \
    --window-size="1200,$1" --screenshot="$2" "$CARD?h=$1" >/dev/null 2>&1
  echo "wrote $2"
}

shot 630 public/og/opengraph.png
shot 600 public/og/twitter.png
