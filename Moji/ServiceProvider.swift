//
//  ServiceProvider.swift
//  Moji
//

import AppKit

private final class ResultBox: @unchecked Sendable {
    nonisolated(unsafe) var value: String
    nonisolated(unsafe) var finished: Bool = false

    init(_ value: String) {
        self.value = value
    }
}

class ServiceProvider: NSObject {
    private let maxTextLength = 500

    @objc func handleService(
        _ pboard: NSPasteboard,
        userData: String,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        guard let text = pboard.string(forType: .string) else {
            error.pointee = "Failed to read text from pasteboard" as NSString
            return
        }

        // Check for empty or whitespace-only text
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            error.pointee = "No text selected" as NSString
            return
        }

        // Truncate if too long (for LLM processing)
        let textToProcess = text.count > maxTextLength ? String(text.prefix(maxTextLength)) : text

        let insertionMode = SettingsManager.insertionMode
        let box = ResultBox(text)

        DispatchQueue.global(qos: .userInitiated).async {
            let group = DispatchGroup()
            group.enter()

            Task {
                do {
                    if #available(macOS 26.0, *) {
                        let emojis = try await LocalLLMClient.shared.fetchEmojis(for: textToProcess)

                        // Record to history (use truncated text for display)
                        let displayText = textToProcess.count > 50 ? String(textToProcess.prefix(50)) + "..." : textToProcess
                        await MainActor.run {
                            HistoryManager.shared.addItem(originalText: displayText, emojis: emojis)
                        }

                        switch insertionMode {
                        case .append:
                            box.value = "\(text) \(emojis)"
                        case .prepend:
                            box.value = "\(emojis) \(text)"
                        case .replace:
                            box.value = emojis
                        }
                    } else {
                        box.value = "\(text) ✨"
                    }
                } catch {
                    box.value = "\(text) ✨"
                }
                group.leave()
            }

            group.wait()
            box.finished = true
        }

        let deadline = Date().addingTimeInterval(10)
        while !box.finished && Date() < deadline {
            RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.1))
        }

        pboard.clearContents()
        pboard.setString(box.value, forType: .string)
    }
}
