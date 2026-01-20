# Moji - macOS Menu Bar Emoji App

## Overview
**App Name:** Moji
**Type:** macOS Menu Bar App + System Service
**Purpose:** Analyzes selected text using on-device AI and inserts context-aware emojis.
**Requirements:** macOS 26.0+ (Tahoe), Apple Silicon (M1/M2/M3/M4)

## Architecture

### Core Stack
- **Swift** - Primary language
- **SwiftUI** - Menu bar UI with custom styling
- **AppKit** - Menu bar integration, clipboard handling
- **Foundation Models** - Apple's on-device AI for emoji generation
- **ServiceManagement** - Launch at login
- **Carbon** - Global hotkey registration

### Data Flow
1. **User Action:** Select text → Press `⌥M` (or right-click → Services → "Moji This")
2. **Text Capture:** App copies selected text via simulated Cmd+C
3. **AI Processing:** Text sent to Apple's on-device Foundation Models
4. **Output:** Emojis inserted based on user's insertion mode preference

## Features

### Input Methods
- **Global Hotkey:** `⌥M` (Option + M) - works in any app
- **Services Menu:** Right-click → Services → "Moji This"

### Settings
- **Max Emojis:** 1, 2, 3, or Auto (AI decides based on context)
- **Emoji Style:**
  - Literal - Direct visual matches (dog → 🐕)
  - Abstract - Vibes and mood (love → 💫)
  - Chaotic - Weird and fun (meeting → 🦷)
- **Insertion Mode:** Append, Prepend, or Replace

### Other Features
- **History:** Recent emoji conversions with one-click copy
- **Auto-start:** Launches on login via SMAppService
- **Privacy:** All AI processing happens on-device, no data sent externally

## File Structure

```
Moji/
├── MojiApp.swift          # App entry, MenuBarExtra, AppDelegate
├── MenuBarView.swift      # Main UI with custom styling
├── SettingsManager.swift  # UserDefaults persistence, enums
├── LocalLLMClient.swift   # Apple Foundation Models integration
├── TextProcessor.swift    # Hotkey text processing, clipboard handling
├── ServiceProvider.swift  # NSServices handler for right-click menu
├── HotkeyManager.swift    # Global ⌥M hotkey via Carbon API
├── HistoryManager.swift   # Recent conversions storage
└── Info.plist             # LSUIElement, NSServices config
```

## Key Implementation Details

### Apple Foundation Models (LocalLLMClient.swift)
```swift
@available(macOS 26.0, *)
class LocalLLMClient {
    private let model = SystemLanguageModel.default

    func fetchEmojis(for text: String) async throws -> String {
        let session = LanguageModelSession()
        let response = try await session.respond(to: prompt)
        return truncateEmojis(response.content, max: maxEmojis)
    }
}
```

### Global Hotkey (HotkeyManager.swift)
- Uses Carbon `RegisterEventHotKey` API
- Registers `⌥M` (Option + M) on app launch
- Triggers `TextProcessor.processSelectedText()`

### Text Processing Flow (TextProcessor.swift)
1. Save current clipboard contents
2. Simulate Cmd+C to copy selected text
3. Send text to LLM (truncated to 500 chars max)
4. Format result based on insertion mode
5. Simulate Cmd+V to paste
6. Restore original clipboard

### Edge Cases Handled
- No text selected → System beep
- Empty/whitespace text → System beep
- Very long text → Truncated to 500 chars for LLM
- Rapid invocations → Blocked while processing
- LLM errors → Falls back to ✨ emoji

### UI Styling (MenuBarView.swift)
- SF Rounded font throughout
- Custom PillToggle component (replaces segmented pickers)
- Purple gradient theme (#7C3AED to violet)
- Card-based sections with subtle backgrounds

## Permissions Required

### Accessibility
Required for global hotkey to simulate copy/paste keystrokes.
- System Settings → Privacy & Security → Accessibility → Enable Moji

### Login Items
Auto-enabled on first launch via SMAppService.
- Can be disabled in System Settings → General → Login Items

## Distribution

### Building
1. Xcode: Product → Archive
2. Organizer: Distribute App → Copy App
3. Run: `./scripts/create-dmg.sh /path/to/Moji.app`

### DMG Features
- Custom dark gradient background
- "Drag to Install" text with arrow
- Applications folder shortcut

### Gatekeeper
App is not notarized (requires $99/year Apple Developer account).
Users must: Right-click → Open → Open to bypass warning.

## Repository
- **GitHub:** https://github.com/holy-schmitt-dev/moji
- **License:** MIT
