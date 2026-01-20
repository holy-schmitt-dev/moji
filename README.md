# ✨ Moji

A macOS menu bar app that uses Apple's on-device AI to add perfect emojis to your text.

Select any text, press `⌥M`, and watch as contextually relevant emojis appear instantly—all processed locally on your Mac.

<p align="center">
  <img src=".github/screenshot.png" width="50%" alt="Moji Screenshot">
</p>

<p align="center">
  <a href="https://github.com/holy-schmitt-dev/moji/releases/latest/download/Moji-1.0.dmg">
    <img src="https://img.shields.io/badge/Download-Moji%20for%20Mac-7C3AED?style=for-the-badge&logo=apple&logoColor=white" alt="Download Moji">
  </a>
</p>

## Features

- **On-Device AI** — Uses Apple's Foundation Models for fast, private emoji suggestions
- **Global Hotkey** — Press `⌥M` (Option + M) from any app to mojify selected text
- **Services Menu** — Right-click → Services → "Moji This" as an alternative
- **Three Styles**
  - **Literal** — Direct visual matches (dog → 🐕)
  - **Abstract** — Vibes and mood (love → 💫)
  - **Chaotic** — Weird and fun (meeting → 🦷)
- **Configurable** — Choose 1-3 emojis, append/prepend/replace modes
- **History** — Quick access to recent emoji conversions
- **Privacy First** — Everything runs locally, no data leaves your Mac

## Requirements

- macOS 26.0 (Tahoe) or later
- Apple Silicon Mac (M1/M2/M3/M4)

## Installation

### Download

1. Download the latest `.dmg` from [Releases](https://github.com/holy-schmitt-dev/moji/releases)
2. Open the `.dmg` and drag Moji to your Applications folder
3. Launch Moji from Applications
4. Grant Accessibility permissions when prompted (required for the `⌥M` hotkey)

### Homebrew (coming soon)

```bash
brew install --cask moji
```

## Usage

1. **Select any text** in any application
2. **Press `⌥M`** (Option + M)
3. **Done!** Emojis are automatically inserted

### Alternative: Services Menu

1. Select text
2. Right-click → Services → **Moji This**

### Settings

Click the ✨ menu bar icon to access settings:

- **Max Emojis** — Limit output to 1, 2, or 3 emojis
- **Style** — Choose Literal, Abstract, or Chaotic
- **Insert Mode** — Append, Prepend, or Replace your text

## Permissions

Moji requires **Accessibility** access to use the global hotkey:

1. Open **System Settings**
2. Go to **Privacy & Security → Accessibility**
3. Enable **Moji**

The app will prompt you on first launch, or you can click "Open System Settings" in the app.

## Building from Source

```bash
# Clone the repository
git clone https://github.com/holy-schmitt-dev/moji.git
cd moji

# Open in Xcode
open Moji.xcodeproj

# Build and run (⌘R)
```

Requires Xcode 16+ with macOS 26 SDK.

## Privacy

Moji is designed with privacy in mind:

- All AI processing happens **on-device** using Apple's Foundation Models
- **No data is sent** to external servers
- **No analytics or tracking**
- Your text never leaves your Mac

## License

MIT License — see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Credits

Built with ❤️ using SwiftUI and Apple Foundation Models.

---

**[Download Moji](https://github.com/holy-schmitt-dev/moji/releases)** and start adding emojis to everything ✨
