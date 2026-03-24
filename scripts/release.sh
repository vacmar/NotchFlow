#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

VERSION="${1:-0.1.0}"
TAG="v$VERSION"
RELEASE_DIR="$ROOT_DIR/release/$TAG"
DIST_DIR="$ROOT_DIR/dist"
NOTARIZE="${NOTARIZE:-0}"

echo "Preparing release $TAG"
mkdir -p "$RELEASE_DIR"

VERSION="$VERSION" ./scripts/package_dmg.sh

APP_SOURCE="$DIST_DIR/NotchFlow.app"
DMG_SOURCE="$DIST_DIR/NotchFlow.dmg"

APP_TARGET="$RELEASE_DIR/NotchFlow-$TAG.app"
DMG_TARGET="$RELEASE_DIR/NotchFlow-$TAG.dmg"

rm -rf "$APP_TARGET"
cp -R "$APP_SOURCE" "$APP_TARGET"
cp "$DMG_SOURCE" "$DMG_TARGET"

if [[ "$NOTARIZE" == "1" ]]; then
	echo "Notarizing release DMG..."
	./scripts/notarize.sh "$DMG_TARGET"
fi

shasum -a 256 "$DMG_TARGET" > "$RELEASE_DIR/NotchFlow-$TAG.dmg.sha256"

cat > "$RELEASE_DIR/RELEASE_NOTES.md" <<EOF
# NotchFlow $TAG

## Highlights
- Dynamic Island style now-playing UI for macOS
- Spotify / Apple Music / browser media detection and controls
- Theme-aware island + settings (System, Dark, Light)
- Permissions setup + status panel
- Drag-and-drop DMG installer layout

## Installation
1. Download NotchFlow-$TAG.dmg
2. Open the DMG
3. Drag NotchFlow to Applications
4. Launch NotchFlow from Applications

## Integrity
- SHA-256: see NotchFlow-$TAG.dmg.sha256
EOF

echo "Release artifacts created in: $RELEASE_DIR"
ls -la "$RELEASE_DIR"
