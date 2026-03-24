#!/usr/bin/env zsh
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <path-to-dmg>"
  exit 1
fi

DMG_PATH="$1"

if [[ ! -f "$DMG_PATH" ]]; then
  echo "Error: DMG not found at $DMG_PATH"
  exit 1
fi

: "${APPLE_ID:?Set APPLE_ID for notarization}"
: "${APPLE_TEAM_ID:?Set APPLE_TEAM_ID for notarization}"
: "${APPLE_APP_PASSWORD:?Set APPLE_APP_PASSWORD (app-specific password) for notarization}"

echo "Submitting DMG for notarization..."
xcrun notarytool submit "$DMG_PATH" \
  --apple-id "$APPLE_ID" \
  --team-id "$APPLE_TEAM_ID" \
  --password "$APPLE_APP_PASSWORD" \
  --wait

echo "Stapling notarization ticket..."
xcrun stapler staple "$DMG_PATH"

echo "Verifying Gatekeeper assessment..."
spctl -a -vv --type open "$DMG_PATH" || true

echo "Notarization complete: $DMG_PATH"
