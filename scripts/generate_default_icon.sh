#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ASSETS_DIR="$ROOT_DIR/Assets"
ICONSET_DIR="$ASSETS_DIR/AppIcon.iconset"
PNG_1024="$ASSETS_DIR/AppIcon-1024.png"
ICNS_PATH="$ASSETS_DIR/AppIcon.icns"
CUSTOM_SOURCE=""

for candidate in "$ASSETS_DIR/CustomAppIcon.png" "$ASSETS_DIR/CustomAppIcon.jpg" "$ASSETS_DIR/CustomAppIcon.jpeg" "$ASSETS_DIR/CustomAppIcon.webp" "$ASSETS_DIR/NotchFlow.png" "$ASSETS_DIR/NotchFlow.jpg" "$ASSETS_DIR/NotchFlow.jpeg" "$ASSETS_DIR/NotchFlow.webp"; do
    if [[ -f "$candidate" ]]; then
        CUSTOM_SOURCE="$candidate"
        break
    fi
done

mkdir -p "$ASSETS_DIR"
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

if [[ -n "$CUSTOM_SOURCE" ]]; then
    echo "Using custom icon source: $CUSTOM_SOURCE"
    sips -z 1024 1024 "$CUSTOM_SOURCE" --out "$PNG_1024" >/dev/null
else
    echo "Generating default NotchFlow 1024x1024 icon..."
    cat > "$ASSETS_DIR/_make_icon.swift" <<'SWIFT'
import AppKit

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()

let rect = NSRect(origin: .zero, size: size)
let bg = NSBezierPath(roundedRect: rect, xRadius: 220, yRadius: 220)

let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.09, green: 0.10, blue: 0.15, alpha: 1.0),
    NSColor(calibratedRed: 0.20, green: 0.10, blue: 0.30, alpha: 1.0)
])!
gradient.draw(in: bg, angle: 315)

let pillRect = NSRect(x: 180, y: 650, width: 664, height: 170)
let pill = NSBezierPath(roundedRect: pillRect, xRadius: 85, yRadius: 85)
NSColor(calibratedWhite: 0.08, alpha: 0.9).setFill()
pill.fill()

let dotRect = NSRect(x: 500, y: 415, width: 24, height: 24)
NSColor(calibratedWhite: 1.0, alpha: 0.35).setFill()
NSBezierPath(ovalIn: dotRect).fill()

let text = "NF"
let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 340, weight: .heavy),
    .foregroundColor: NSColor.white.withAlphaComponent(0.94)
]
let attributed = NSAttributedString(string: text, attributes: attrs)
let textSize = attributed.size()
let textRect = NSRect(
    x: (size.width - textSize.width) / 2,
    y: 250,
    width: textSize.width,
    height: textSize.height
)
attributed.draw(in: textRect)

image.unlockFocus()

guard let tiffData = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiffData),
            let pngData = rep.representation(using: NSBitmapImageRep.FileType.png, properties: [:]) else {
    fatalError("Failed to render PNG")
}

let outputPath = CommandLine.arguments[1]
try pngData.write(to: URL(fileURLWithPath: outputPath))
SWIFT

    swift "$ASSETS_DIR/_make_icon.swift" "$PNG_1024"
    rm -f "$ASSETS_DIR/_make_icon.swift"
fi

cp "$PNG_1024" "$ICONSET_DIR/icon_512x512@2x.png"
sips -z 16 16   "$PNG_1024" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
sips -z 32 32   "$PNG_1024" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
sips -z 32 32   "$PNG_1024" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
sips -z 64 64   "$PNG_1024" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$PNG_1024" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
sips -z 256 256 "$PNG_1024" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$PNG_1024" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
sips -z 512 512 "$PNG_1024" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$PNG_1024" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null

iconutil -c icns "$ICONSET_DIR" -o "$ICNS_PATH"

rm -f "$PNG_1024"
rm -rf "$ICONSET_DIR"

echo "Generated: $ICNS_PATH"
