#!/bin/bash
set -e

# Process Menu Bar Icon
echo "Processing Menu Bar Icon..."
swift Sources/IconProcessor.swift Sources/MouseWheelRepairix/menubar_original.png Sources/MouseWheelRepairix/mouse_icon.png

# Process App Icon
echo "Processing App Icon..."
ICONSET="MouseWheelRepairix.iconset"
mkdir -p "$ICONSET"
SOURCE_ICON="Sources/MouseWheelRepairix/AppIcon_1024.png"

# Generate various sizes
sips -z 16 16     "$SOURCE_ICON" --out "$ICONSET/icon_16x16.png"
sips -z 32 32     "$SOURCE_ICON" --out "$ICONSET/icon_16x16@2x.png"
sips -z 32 32     "$SOURCE_ICON" --out "$ICONSET/icon_32x32.png"
sips -z 64 64     "$SOURCE_ICON" --out "$ICONSET/icon_32x32@2x.png"
sips -z 128 128   "$SOURCE_ICON" --out "$ICONSET/icon_128x128.png"
sips -z 256 256   "$SOURCE_ICON" --out "$ICONSET/icon_128x128@2x.png"
sips -z 256 256   "$SOURCE_ICON" --out "$ICONSET/icon_256x256.png"
sips -z 512 512   "$SOURCE_ICON" --out "$ICONSET/icon_256x256@2x.png"
sips -z 512 512   "$SOURCE_ICON" --out "$ICONSET/icon_512x512.png"
sips -z 1024 1024 "$SOURCE_ICON" --out "$ICONSET/icon_512x512@2x.png"

iconutil -c icns "$ICONSET" -o Sources/MouseWheelRepairix/AppIcon.icns
rm -rf "$ICONSET"

# Call Install Script
./install.sh
