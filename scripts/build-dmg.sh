#!/bin/bash
# build-dmg.sh - Create DMG with custom icon, README, and Source Link

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

# Read version from Version.swift
VERSION=$(grep -o 'version = "[^"]*"' Sources/MouseWheelRepairix/Version.swift | cut -d'"' -f2)

APP_NAME="MouseWheelRepairix"
DMG_NAME="${APP_NAME}-${VERSION}"
DMG_TEMP_DIR="dist/dmg_temp"
DMG_FINAL_PATH="dist/${DMG_NAME}.dmg"

echo "📦 Preparing DMG for ${APP_NAME} v${VERSION}..."

# 1. Build the app
"$SCRIPT_DIR/build-app.sh"

# 2. Cleanup & Prep
rm -rf "$DMG_TEMP_DIR"
mkdir -p "$DMG_TEMP_DIR"
mkdir -p dist

# 3. Generate ICNS for Volume Icon
if [ -d "MouseWheelRepairix.iconset" ]; then
    echo "🎨 Generating Volume Icon..."
    iconutil -c icns "MouseWheelRepairix.iconset" -o "dist/VolumeIcon.icns" || echo "⚠️ Icon generation failed, proceeding without volume icon."
fi

# 4. Populate DMG Content
echo "📄 Copying files..."
cp -R "${APP_NAME}.app" "$DMG_TEMP_DIR/"
cp "README.md" "$DMG_TEMP_DIR/README.txt" # .txt often opens easier for users without markdown viewer, but keep md content. Or keep .md. Let's keep .md but maybe COPY as README.txt is safer? nah, .md is fine on macOS.

# Create Source Code Web Link
echo '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>URL</key>
	<string>https://github.com/ermuraten/MouseWheelRepairix</string>
</dict>
</plist>' > "$DMG_TEMP_DIR/Source Code.webloc"

# Create Applications Symlink
ln -s /Applications "$DMG_TEMP_DIR/Applications"

# 5. Set Volume Icon (Requires copying to .VolumeIcon.icns and setting folder attribute)
if [ -f "dist/VolumeIcon.icns" ]; then
    cp "dist/VolumeIcon.icns" "$DMG_TEMP_DIR/.VolumeIcon.icns"
    # SetFile is required to activate the custom icon attribute on the folder
    if command -v SetFile &> /dev/null; then
        SetFile -c icnC "$DMG_TEMP_DIR/.VolumeIcon.icns"
        SetFile -a C "$DMG_TEMP_DIR"
        echo "✅ Volume Icon set"
    else
        echo "⚠️ SetFile not found (Install Xcode Command Line Tools for custom folder icons)"
    fi
fi

# 6. Create DMG
echo "🔧 Creating DMG..."
rm -f "$DMG_FINAL_PATH"
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_TEMP_DIR" \
    -ov -format UDZO \
    "$DMG_FINAL_PATH"

# 7. Cleanup
rm -rf "$DMG_TEMP_DIR"
rm -f "dist/VolumeIcon.icns"

echo ""
echo "✅ DMG created successfully: $DMG_FINAL_PATH"
echo "   Size: $(du -h "$DMG_FINAL_PATH" | cut -f1)"

# 8. Verify
echo ""
echo "🔍 Verifying DMG..."
hdiutil verify "$DMG_FINAL_PATH" && echo "✅ DMG verification passed!"
