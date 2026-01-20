//
//  TextProcessor.swift
//  Moji
//

import AppKit

class TextProcessor {
    static let shared = TextProcessor()

    private let maxTextLength = 500
    private var isProcessing = false

    // Callback to update menu bar icon during processing
    var onProcessingStateChanged: ((Bool) -> Void)?

    private init() {}

    @MainActor
    func processSelectedText() async {
        // Prevent multiple simultaneous invocations
        guard !isProcessing else {
            NSSound.beep()
            return
        }
        isProcessing = true
        onProcessingStateChanged?(true)

        defer {
            isProcessing = false
            onProcessingStateChanged?(false)
        }

        // Save current clipboard
        let pasteboard = NSPasteboard.general
        let savedContents = pasteboard.string(forType: .string)

        // Clear clipboard first to detect if copy worked
        pasteboard.clearContents()

        // Copy selected text (Cmd+C)
        simulateKeystroke(keyCode: 8, modifiers: .maskCommand) // 8 = 'C'

        // Small delay for clipboard to update
        try? await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds

        // Check if we got any text
        guard let selectedText = pasteboard.string(forType: .string),
              !selectedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            // Nothing selected or only whitespace - restore clipboard and play error sound
            if let saved = savedContents {
                pasteboard.clearContents()
                pasteboard.setString(saved, forType: .string)
            }
            NSSound.beep()
            return
        }

        // Truncate if too long (for LLM processing, but keep original for output)
        let textToProcess: String
        if selectedText.count > maxTextLength {
            textToProcess = String(selectedText.prefix(maxTextLength))
        } else {
            textToProcess = selectedText
        }

        // Get emojis
        let result = await fetchEmojisAndFormat(text: textToProcess, originalText: selectedText)

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

    private func fetchEmojisAndFormat(text: String, originalText: String) async -> String {
        do {
            if #available(macOS 26.0, *) {
                let emojis = try await LocalLLMClient.shared.fetchEmojis(for: text)

                // Record to history (use truncated text for display)
                let displayText = text.count > 50 ? String(text.prefix(50)) + "..." : text
                await MainActor.run {
                    HistoryManager.shared.addItem(originalText: displayText, emojis: emojis)
                }

                switch SettingsManager.insertionMode {
                case .append:
                    return "\(originalText) \(emojis)"
                case .prepend:
                    return "\(emojis) \(originalText)"
                case .replace:
                    return emojis
                }
            } else {
                return "\(originalText) ✨"
            }
        } catch {
            NSSound.beep()
            return "\(originalText) ✨"
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
