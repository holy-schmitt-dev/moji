#!/bin/bash

# Create DMG for Moji
# Usage: ./scripts/create-dmg.sh /path/to/Moji.app

set -e

APP_PATH="$1"
APP_NAME="Moji"
DMG_NAME="Moji"
VERSION=$(defaults read "$APP_PATH/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo "1.0")
OUTPUT_DIR="$(pwd)/dist"
DMG_PATH="$OUTPUT_DIR/${DMG_NAME}-${VERSION}.dmg"
TEMP_DMG_PATH="$OUTPUT_DIR/${DMG_NAME}-temp.dmg"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  Moji DMG Creator${NC}"
echo -e "${BLUE}======================================${NC}"

# Check if app path provided
if [ -z "$APP_PATH" ]; then
    echo -e "${RED}Error: Please provide the path to Moji.app${NC}"
    echo ""
    echo "Usage: ./scripts/create-dmg.sh /path/to/Moji.app"
    echo ""
    echo "To get Moji.app:"
    echo "  1. In Xcode: Product → Archive"
    echo "  2. In Organizer: Distribute App → Copy App"
    echo "  3. Save the .app file"
    exit 1
fi

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}Error: App not found at $APP_PATH${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Found app: $APP_PATH"
echo -e "${GREEN}✓${NC} Version: $VERSION"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Clean up any previous temp files
rm -f "$TEMP_DMG_PATH"
rm -f "$DMG_PATH"

echo -e "${BLUE}→${NC} Creating DMG..."

# Create a temporary directory for DMG contents
TEMP_DIR=$(mktemp -d)
cp -R "$APP_PATH" "$TEMP_DIR/"

# Create symbolic link to Applications
ln -s /Applications "$TEMP_DIR/Applications"

# Create the DMG
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$TEMP_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

# Clean up
rm -rf "$TEMP_DIR"

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}  DMG created successfully!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo -e "Output: ${BLUE}$DMG_PATH${NC}"
echo ""
echo "Next steps:"
echo "  1. Go to https://github.com/holy-schmitt-dev/moji/releases/new"
echo "  2. Create tag: v$VERSION"
echo "  3. Upload: $DMG_PATH"
echo "  4. Publish release"
echo ""
