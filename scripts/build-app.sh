#!/bin/bash
# build-app.sh - Build MouseWheelRepairix.app with correct version

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

# Read version from Version.swift
VERSION=$(grep -o 'version = "[^"]*"' Sources/MouseWheelRepairix/Version.swift | cut -d'"' -f2)
BUILD=$(grep -o 'buildNumber = "[^"]*"' Sources/MouseWheelRepairix/Version.swift | cut -d'"' -f2)

echo "🔨 Building MouseWheelRepairix v${VERSION} (Build ${BUILD})..."

# Build release binary
swift build -c release

# Create app bundle structure
APP_DIR="MouseWheelRepairix.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copy binary
cp .build/release/MouseWheelRepairix "$APP_DIR/Contents/MacOS/"

# Create Info.plist from template with version substitution
cat > "$APP_DIR/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>MouseWheelRepairix</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.ermuraten.MouseWheelRepairix</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>MouseWheelRepairix</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${BUILD}</string>
    <key>LSMinimumSystemVersion</key>
    <string>11.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# Copy icon - check multiple locations
if [ -f "Sources/MouseWheelRepairix/AppIcon.icns" ]; then
    cp "Sources/MouseWheelRepairix/AppIcon.icns" "$APP_DIR/Contents/Resources/"
    echo "   Icon: Sources/MouseWheelRepairix/AppIcon.icns"
elif [ -d "MouseWheelRepairix.iconset" ]; then
    iconutil -c icns MouseWheelRepairix.iconset -o "$APP_DIR/Contents/Resources/AppIcon.icns" 2>/dev/null || true
    echo "   Icon: Generated from iconset"
elif [ -f "AppIcon.icns" ]; then
    cp AppIcon.icns "$APP_DIR/Contents/Resources/"
    echo "   Icon: AppIcon.icns"
else
    echo "   ⚠️  Warning: No icon found!"
fi

echo "✅ Built: $APP_DIR"
echo "   Version: ${VERSION}"
echo "   Build: ${BUILD}"
