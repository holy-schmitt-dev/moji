//
//  TextProcessor.swift
//  Moji
//

import AppKit

class TextProcessor {
    static let shared = TextProcessor()

    private init() {}

    @MainActor
    func processSelectedText() async {
        // Save current clipboard
        let pasteboard = NSPasteboard.general
        let savedContents = pasteboard.string(forType: .string)

        // Copy selected text (Cmd+C)
        simulateKeystroke(keyCode: 8, modifiers: .maskCommand) // 8 = 'C'

        // Small delay for clipboard to update
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        guard let selectedText = pasteboard.string(forType: .string),
              !selectedText.isEmpty,
              selectedText != savedContents else {
            // Restore clipboard if nothing was selected
            if let saved = savedContents {
                pasteboard.clearContents()
                pasteboard.setString(saved, forType: .string)
            }
            return
        }

        // Get emojis
        let result = await fetchEmojisAndFormat(text: selectedText)

        // Write result to clipboard
        pasteboard.clearContents()
        pasteboard.setString(result, forType: .string)

        // Paste (Cmd+V)
        simulateKeystroke(keyCode: 9, modifiers: .maskCommand) // 9 = 'V'

        // Small delay then restore original clipboard
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        if let saved = savedContents {
            pasteboard.clearContents()
            pasteboard.setString(saved, forType: .string)
        }
    }

    private func fetchEmojisAndFormat(text: String) async -> String {
        do {
            if #available(macOS 26.0, *) {
                let emojis = try await LocalLLMClient.shared.fetchEmojis(for: text)

                // Record to history
                HistoryManager.shared.addItem(originalText: text, emojis: emojis)

                switch SettingsManager.insertionMode {
                case .append:
                    return "\(text) \(emojis)"
                case .prepend:
                    return "\(emojis) \(text)"
                case .replace:
                    return emojis
                }
            } else {
                return "\(text) ✨"
            }
        } catch {
            return "\(text) ✨"
        }
    }

    private func simulateKeystroke(keyCode: CGKeyCode, modifiers: CGEventFlags) {
        let source = CGEventSource(stateID: .hidSystemState)

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        keyDown?.flags = modifiers
        keyDown?.post(tap: .cghidEventTap)

        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        keyUp?.flags = modifiers
        keyUp?.post(tap: .cghidEventTap)
    }
}
