#!/bin/bash
# build-dmg.sh - Create DMG with drag-to-Applications experience

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

# Read version from Version.swift
VERSION=$(grep -o 'version = "[^"]*"' Sources/MouseWheelRepairix/Version.swift | cut -d'"' -f2)

APP_NAME="MouseWheelRepairix"
DMG_NAME="${APP_NAME}-${VERSION}"
DMG_DIR="dist/dmg_temp"
DMG_PATH="dist/${DMG_NAME}.dmg"

echo "📦 Creating DMG for ${APP_NAME} v${VERSION}..."

# Build the app first
"$SCRIPT_DIR/build-app.sh"

# Clean up previous DMG temp
rm -rf "$DMG_DIR"
mkdir -p "$DMG_DIR"
mkdir -p dist

# Copy app to DMG staging
cp -R "${APP_NAME}.app" "$DMG_DIR/"

# Create Applications symlink for drag-and-drop
ln -s /Applications "$DMG_DIR/Applications"

# Create DMG
echo "🔧 Creating DMG..."
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov -format UDZO \
    "$DMG_PATH"

# Clean up
rm -rf "$DMG_DIR"

echo ""
echo "✅ DMG created: $DMG_PATH"
echo "   Size: $(du -h "$DMG_PATH" | cut -f1)"

# Verify DMG
echo ""
echo "🔍 Verifying DMG..."
hdiutil verify "$DMG_PATH" && echo "✅ DMG verification passed!"
