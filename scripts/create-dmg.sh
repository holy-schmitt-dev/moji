#!/bin/bash

# Create signed and notarized DMG for Moji
# Usage: ./scripts/create-dmg.sh /path/to/Moji.app

set -e

APP_PATH="$1"
APP_NAME="Moji"
DMG_NAME="Moji"
VERSION=$(defaults read "$APP_PATH/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo "1.0")
OUTPUT_DIR="$(pwd)/dist"
DMG_PATH="$OUTPUT_DIR/${DMG_NAME}-${VERSION}.dmg"
TEMP_DMG_PATH="$OUTPUT_DIR/${DMG_NAME}-temp.dmg"
MOUNT_DIR="/Volumes/$APP_NAME"
BACKGROUND_DIR="$(pwd)/scripts/dmg-resources"
BACKGROUND_FILE="$BACKGROUND_DIR/background.png"

# Signing & Notarization
TEAM_ID="RVCV97M649"
APPLE_ID="${APPLE_ID:-}"  # Set via environment or prompt
SIGNING_IDENTITY="Developer ID Application: Michael Schmitt ($TEAM_ID)"

# DMG window settings
WINDOW_WIDTH=600
WINDOW_HEIGHT=400
ICON_SIZE=128
APP_X=420
APP_Y=170
APPS_X=180
APPS_Y=170

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
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
    echo "  2. In Organizer: Distribute App → Developer ID → Export"
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

# Unmount if already mounted
if [ -d "$MOUNT_DIR" ]; then
    hdiutil detach "$MOUNT_DIR" -force 2>/dev/null || true
fi

# Check if we should sign
SHOULD_SIGN=false
if security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
    SHOULD_SIGN=true
    echo -e "${GREEN}✓${NC} Found Developer ID certificate"
else
    echo -e "${YELLOW}!${NC} No Developer ID certificate found - skipping signing"
fi

# Sign the app if certificate exists
if [ "$SHOULD_SIGN" = true ]; then
    echo -e "${BLUE}→${NC} Signing app..."
    codesign --force --deep --options runtime --sign "$SIGNING_IDENTITY" "$APP_PATH"
    echo -e "${GREEN}✓${NC} App signed"
fi

echo -e "${BLUE}→${NC} Creating temporary DMG..."

# Create a temporary DMG (read-write)
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$APP_PATH" \
    -ov \
    -format UDRW \
    -size 200m \
    "$TEMP_DMG_PATH"

echo -e "${BLUE}→${NC} Mounting DMG..."

# Mount the temporary DMG
hdiutil attach "$TEMP_DMG_PATH" -mountpoint "$MOUNT_DIR"

# Add Applications symlink
ln -sf /Applications "$MOUNT_DIR/Applications"

echo -e "${BLUE}→${NC} Customizing DMG window..."

# Check if background exists
if [ -f "$BACKGROUND_FILE" ]; then
    mkdir -p "$MOUNT_DIR/.background"
    cp "$BACKGROUND_FILE" "$MOUNT_DIR/.background/background.png"
    HAS_BACKGROUND=true
else
    HAS_BACKGROUND=false
    echo -e "${BLUE}  (No background image found at $BACKGROUND_FILE)${NC}"
fi

# Use AppleScript to customize the DMG window
if [ "$HAS_BACKGROUND" = true ]; then
osascript <<EOF
tell application "Finder"
    tell disk "$APP_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {100, 100, $((100 + WINDOW_WIDTH)), $((100 + WINDOW_HEIGHT))}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to $ICON_SIZE
        set background picture of viewOptions to file ".background:background.png"
        set position of item "Moji.app" of container window to {$APP_X, $APP_Y}
        set position of item "Applications" of container window to {$APPS_X, $APPS_Y}
        close
        open
        update without registering applications
        delay 2
        close
    end tell
end tell
EOF
else
osascript <<EOF
tell application "Finder"
    tell disk "$APP_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {100, 100, $((100 + WINDOW_WIDTH)), $((100 + WINDOW_HEIGHT))}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to $ICON_SIZE
        set position of item "Moji.app" of container window to {$APP_X, $APP_Y}
        set position of item "Applications" of container window to {$APPS_X, $APPS_Y}
        close
        open
        update without registering applications
        delay 2
        close
    end tell
end tell
EOF
fi

# Hide background folder
if [ "$HAS_BACKGROUND" = true ]; then
    SetFile -a V "$MOUNT_DIR/.background" 2>/dev/null || true
fi

# Sync and unmount
sync
hdiutil detach "$MOUNT_DIR"

echo -e "${BLUE}→${NC} Compressing DMG..."

# Convert to compressed read-only DMG
hdiutil convert "$TEMP_DMG_PATH" -format UDZO -o "$DMG_PATH"

# Clean up temp DMG
rm -f "$TEMP_DMG_PATH"

# Sign the DMG if certificate exists
if [ "$SHOULD_SIGN" = true ]; then
    echo -e "${BLUE}→${NC} Signing DMG..."
    codesign --force --sign "$SIGNING_IDENTITY" "$DMG_PATH"
    echo -e "${GREEN}✓${NC} DMG signed"
fi

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}  DMG created successfully!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo -e "Output: ${BLUE}$DMG_PATH${NC}"
echo ""

# Notarization
if [ "$SHOULD_SIGN" = true ]; then
    echo -e "${YELLOW}To notarize (removes all Gatekeeper warnings):${NC}"
    echo ""
    echo "  1. Store your app-specific password in keychain (one-time):"
    echo "     xcrun notarytool store-credentials \"moji-notary\" \\"
    echo "       --apple-id YOUR_APPLE_ID \\"
    echo "       --team-id $TEAM_ID \\"
    echo "       --password YOUR_APP_SPECIFIC_PASSWORD"
    echo ""
    echo "  2. Notarize the DMG:"
    echo "     xcrun notarytool submit \"$DMG_PATH\" --keychain-profile \"moji-notary\" --wait"
    echo ""
    echo "  3. Staple the ticket:"
    echo "     xcrun stapler staple \"$DMG_PATH\""
    echo ""
fi

echo "Upload to GitHub:"
echo "  https://github.com/holy-schmitt-dev/moji/releases/new"
echo ""
