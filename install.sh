#!/bin/bash
set -e

# Output Name
APP_NAME="MouseWheelRepairix"
APP_BUNDLE="${APP_NAME}.app"

echo "Building Release Configuration..."
swift build -c release

echo "Creating App Bundle Structure..."
# Clean old bundle
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
echo "Copying binary..."
cp .build/release/MouseWheelRepairix "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy Icon (Menu Bar)
if [ -f Sources/MouseWheelRepairix/mouse_icon.png ]; then
    echo "Copying menu bar icon..."
    cp Sources/MouseWheelRepairix/mouse_icon.png "$APP_BUNDLE/Contents/Resources/mouse_icon.png"
fi

# Copy App Icon (ICNS)
if [ -f Sources/MouseWheelRepairix/AppIcon.icns ]; then
    echo "Copying App Icon..."
    cp Sources/MouseWheelRepairix/AppIcon.icns "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

# Create Info.plist
echo "Creating Info.plist..."
cat <<EOF > "$APP_BUNDLE/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.murat.$APP_NAME</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSUIElement</key>
    <true/> <!-- Hides from Dock, lives in Menu Bar -->
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "Done! ${APP_BUNDLE} created."
echo "Opening finder..."
open .
