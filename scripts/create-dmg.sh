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

# Signing & Notarization (set via environment variables)
TEAM_ID="${MOJI_TEAM_ID:-}"
DEVELOPER_NAME="${MOJI_DEVELOPER_NAME:-}"
SIGNING_IDENTITY=""
if [ -n "$TEAM_ID" ] && [ -n "$DEVELOPER_NAME" ]; then
    SIGNING_IDENTITY="Developer ID Application: $DEVELOPER_NAME ($TEAM_ID)"
fi

# DMG window settings
WINDOW_WIDTH=540
WINDOW_HEIGHT=380
ICON_SIZE=128
APP_X=380
APP_Y=175
APPS_X=160
APPS_Y=175

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  Moji DMG Creator${NC}"
echo -e "${BLUE}======================================${NC}"

# Check if app path provided
if [ -z "$APP_PATH" ]; then
    echo -e "${RED}Error: Please provide the path to Moji.app${NC}"
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

# Clean up
rm -f "$TEMP_DMG_PATH"
rm -f "$DMG_PATH"

# Unmount if already mounted
if [ -d "$MOUNT_DIR" ]; then
    hdiutil detach "$MOUNT_DIR" -force 2>/dev/null || true
fi

# Check for signing certificate
SHOULD_SIGN=false
if [ -z "$SIGNING_IDENTITY" ]; then
    # Try to auto-detect signing identity
    SIGNING_IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | sed 's/.*"\(.*\)".*/\1/')
fi

if [ -n "$SIGNING_IDENTITY" ] && security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
    SHOULD_SIGN=true
    echo -e "${GREEN}✓${NC} Using signing identity: $SIGNING_IDENTITY"
else
    echo -e "${YELLOW}!${NC} No Developer ID certificate found - skipping signing"
fi

# Sign the app
if [ "$SHOULD_SIGN" = true ]; then
    echo -e "${BLUE}→${NC} Signing app..."
    codesign --force --deep --options runtime --sign "$SIGNING_IDENTITY" "$APP_PATH"
    echo -e "${GREEN}✓${NC} App signed"
fi

echo -e "${BLUE}→${NC} Creating DMG structure..."

# Create a temporary folder for DMG contents
TEMP_FOLDER=$(mktemp -d)
cp -R "$APP_PATH" "$TEMP_FOLDER/"
ln -s /Applications "$TEMP_FOLDER/Applications"

# Create initial DMG
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$TEMP_FOLDER" \
    -ov \
    -format UDRW \
    -size 100m \
    "$TEMP_DMG_PATH"

rm -rf "$TEMP_FOLDER"

echo -e "${BLUE}→${NC} Customizing DMG..."

# Mount
hdiutil attach "$TEMP_DMG_PATH" -mountpoint "$MOUNT_DIR" -nobrowse

# Add background
if [ -f "$BACKGROUND_FILE" ]; then
    mkdir -p "$MOUNT_DIR/.background"
    cp "$BACKGROUND_FILE" "$MOUNT_DIR/.background/background.png"
fi

# Remove any system files
rm -rf "$MOUNT_DIR/.fseventsd" 2>/dev/null || true
rm -rf "$MOUNT_DIR/.Trashes" 2>/dev/null || true

# Apply Finder settings via AppleScript
echo -e "${BLUE}→${NC} Applying Finder settings..."
sleep 1

osascript <<APPLESCRIPT
tell application "Finder"
    tell disk "$APP_NAME"
        open
        delay 1

        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {200, 200, $((200 + WINDOW_WIDTH)), $((200 + WINDOW_HEIGHT))}

        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to $ICON_SIZE
        set background picture of theViewOptions to file ".background:background.png"

        set position of item "Moji.app" of container window to {$APP_X, $APP_Y}
        set position of item "Applications" of container window to {$APPS_X, $APPS_Y}

        update without registering applications
        delay 1
        close
    end tell
end tell
APPLESCRIPT

# Hide background folder
chflags hidden "$MOUNT_DIR/.background" 2>/dev/null || true

# Sync and unmount
sync
sleep 1
hdiutil detach "$MOUNT_DIR"

echo -e "${BLUE}→${NC} Compressing DMG..."

# Convert to compressed
hdiutil convert "$TEMP_DMG_PATH" -format UDZO -o "$DMG_PATH"
rm -f "$TEMP_DMG_PATH"

# Sign DMG
if [ "$SHOULD_SIGN" = true ]; then
    echo -e "${BLUE}→${NC} Signing DMG..."
    codesign --force --sign "$SIGNING_IDENTITY" "$DMG_PATH"
    echo -e "${GREEN}✓${NC} DMG signed"
fi

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}  DMG created: $DMG_PATH${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

if [ "$SHOULD_SIGN" = true ]; then
    echo "To notarize:"
    echo "  xcrun notarytool submit \"$DMG_PATH\" --keychain-profile \"moji-notary\" --wait"
    echo "  xcrun stapler staple \"$DMG_PATH\""
    echo ""
fi
