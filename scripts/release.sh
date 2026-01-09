#!/bin/bash
# release.sh - Create a new release with version bump, changelog, and git tag

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Current version
CURRENT_VERSION=$(grep -o 'version = "[^"]*"' Sources/MouseWheelRepairix/Version.swift | cut -d'"' -f2)

echo -e "${GREEN}🚀 MouseWheelRepairix Release Script${NC}"
echo ""
echo "Current version: $CURRENT_VERSION"
echo ""

# Check for uncommitted changes
if [[ -n $(git status -s) ]]; then
    echo -e "${YELLOW}⚠️  Warning: You have uncommitted changes${NC}"
    git status -s
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Ask for new version
echo "Enter new version (or press Enter to use current: $CURRENT_VERSION):"
read NEW_VERSION
NEW_VERSION=${NEW_VERSION:-$CURRENT_VERSION}

# Ask for new build number
CURRENT_BUILD=$(grep -o 'buildNumber = "[^"]*"' Sources/MouseWheelRepairix/Version.swift | cut -d'"' -f2)
NEW_BUILD=$((CURRENT_BUILD + 1))
echo "Enter build number (or press Enter for: $NEW_BUILD):"
read INPUT_BUILD
NEW_BUILD=${INPUT_BUILD:-$NEW_BUILD}

echo ""
echo -e "${YELLOW}Release Summary:${NC}"
echo "  Version: $NEW_VERSION"
echo "  Build:   $NEW_BUILD"
echo "  Tag:     v$NEW_VERSION"
echo ""
read -p "Proceed? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# Update Version.swift
echo "📝 Updating Version.swift..."
sed -i '' "s/version = \"[^\"]*\"/version = \"$NEW_VERSION\"/" Sources/MouseWheelRepairix/Version.swift
sed -i '' "s/buildNumber = \"[^\"]*\"/buildNumber = \"$NEW_BUILD\"/" Sources/MouseWheelRepairix/Version.swift

# Update CHANGELOG.md link
echo "📝 Updating CHANGELOG.md..."
TODAY=$(date +%Y-%m-%d)
if ! grep -q "\[$NEW_VERSION\]:" CHANGELOG.md; then
    echo "" >> CHANGELOG.md
    echo "[$NEW_VERSION]: https://github.com/ermuraten/MouseWheelRepairix/releases/tag/v$NEW_VERSION" >> CHANGELOG.md
fi

# Build app and DMG
echo ""
echo "🔨 Building release..."
"$SCRIPT_DIR/build-dmg.sh"

# Git operations
echo ""
echo "📦 Creating git commit and tag..."
git add -A
git commit -m "chore(release): v$NEW_VERSION" || echo "Nothing to commit"
git tag -a "v$NEW_VERSION" -m "Release v$NEW_VERSION"

echo ""
echo -e "${GREEN}✅ Release v$NEW_VERSION created!${NC}"
echo ""
echo "Next steps:"
echo "  1. Push to GitHub:  git push origin main --tags"
echo "  2. Create GitHub Release and upload: dist/MouseWheelRepairix-${NEW_VERSION}.dmg"
echo ""
echo "Or run: gh release create v$NEW_VERSION dist/MouseWheelRepairix-${NEW_VERSION}.dmg --title 'v$NEW_VERSION' --notes 'See CHANGELOG.md for details'"
