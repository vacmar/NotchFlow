#!/usr/bin/env zsh
set -euo pipefail

APP_NAME="NotchFlow"
BUNDLE_ID="com.notchflow.app"
VERSION="${VERSION:-0.1.0}"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/.build/release"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
DMG_PATH="$DIST_DIR/$APP_NAME.dmg"
BIN_PATH="$BUILD_DIR/$APP_NAME"
RW_DMG_PATH="$DIST_DIR/$APP_NAME-rw.dmg"
ICON_PATH="$ROOT_DIR/Assets/AppIcon.icns"
DMG_BACKGROUND_SOURCE_PATH="$ROOT_DIR/Assets/InstallerBackground.png"
DMG_BACKGROUND_NAME="InstallerBackground.png"
DMG_WINDOW_WIDTH=1120
DMG_WINDOW_HEIGHT=720
SIGN_IDENTITY="${SIGN_IDENTITY:--}"
ENTITLEMENTS_PATH="${ENTITLEMENTS_PATH:-$ROOT_DIR/scripts/NotchFlow.entitlements}"

echo "Building release binary..."
cd "$ROOT_DIR"
swift build -c release

if [[ ! -f "$BIN_PATH" ]]; then
  echo "Error: release binary not found at $BIN_PATH"
  exit 1
fi

echo "Preparing app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$BIN_PATH" "$APP_DIR/Contents/MacOS/$APP_NAME"
chmod +x "$APP_DIR/Contents/MacOS/$APP_NAME"

if [[ -f "$ICON_PATH" ]]; then
  cp "$ICON_PATH" "$APP_DIR/Contents/Resources/AppIcon.icns"
fi

cat > "$APP_DIR/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleVersion</key>
  <string>$VERSION</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSAppleEventsUsageDescription</key>
  <string>NotchFlow needs Apple Events access to read and control media playback.</string>
</dict>
</plist>
EOF

if [[ "$SIGN_IDENTITY" == "-" ]]; then
  echo "Ad-hoc signing app bundle..."
  codesign --force --deep --sign - "$APP_DIR"
else
  echo "Signing app bundle with identity: $SIGN_IDENTITY"
  SIGN_ARGS=(--force --deep --timestamp --options runtime --sign "$SIGN_IDENTITY")
  if [[ -f "$ENTITLEMENTS_PATH" ]]; then
    SIGN_ARGS+=(--entitlements "$ENTITLEMENTS_PATH")
  fi
  codesign "${SIGN_ARGS[@]}" "$APP_DIR"
fi

echo "Creating DMG..."
mkdir -p "$DIST_DIR"
rm -f "$DMG_PATH"
rm -f "$RW_DMG_PATH"

# Cleanup any previously mounted installer volumes for this app name.
for existing in /Volumes/$APP_NAME(N) /Volumes/$APP_NAME\ *(N); do
  hdiutil detach "$existing" -quiet 2>/dev/null || true
done

hdiutil create -size 300m -fs HFS+ -volname "$APP_NAME" -ov "$RW_DMG_PATH"

ATTACH_OUTPUT=$(hdiutil attach "$RW_DMG_PATH" -readwrite -noverify -noautoopen)
DEVICE=$(echo "$ATTACH_OUTPUT" | awk '/Apple_HFS/ {print $1}' | tail -n1)
MOUNT_POINT=$(echo "$ATTACH_OUTPUT" | awk '/Apple_HFS/ {$1=""; $2=""; sub(/^  */, ""); print}' | tail -n1)

if [[ -z "${DEVICE:-}" || -z "${MOUNT_POINT:-}" ]]; then
  echo "Error: failed to attach staging DMG"
  exit 1
fi

rm -rf "$MOUNT_POINT/$APP_NAME.app"
cp -R "$APP_DIR" "$MOUNT_POINT/$APP_NAME.app"
rm -f "$MOUNT_POINT/Applications"
ln -s /Applications "$MOUNT_POINT/Applications"

if [[ -f "$DMG_BACKGROUND_SOURCE_PATH" ]]; then
  mkdir -p "$MOUNT_POINT/.background"
  sips -z "$DMG_WINDOW_HEIGHT" "$DMG_WINDOW_WIDTH" "$DMG_BACKGROUND_SOURCE_PATH" --out "$MOUNT_POINT/.background/$DMG_BACKGROUND_NAME" >/dev/null
fi

echo "Configuring DMG drag-install layout..."
if ! osascript <<EOF
tell application "Finder"
  tell disk "$APP_NAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set bounds of container window to {120, 120, 1240, 840}

    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 190
    set text size of viewOptions to 14
    set label position of viewOptions to bottom
    if exists file ".background:$DMG_BACKGROUND_NAME" of container window then
      set background picture of viewOptions to file ".background:$DMG_BACKGROUND_NAME"
    else
      set background color of viewOptions to {61000, 61000, 61000}
    end if

    set position of item "$APP_NAME.app" of container window to {300, 360}
    set position of item "Applications" of container window to {790, 360}

    close
    open
    update without registering applications
    delay 1
  end tell
end tell
EOF
then
  echo "Warning: Finder layout customization failed; DMG will still work for drag-and-drop install."
fi

hdiutil detach "$DEVICE" -quiet
hdiutil convert "$RW_DMG_PATH" -format UDZO -o "$DMG_PATH" -quiet
rm -f "$RW_DMG_PATH"

echo "Done."
echo "App: $APP_DIR"
echo "DMG: $DMG_PATH"
