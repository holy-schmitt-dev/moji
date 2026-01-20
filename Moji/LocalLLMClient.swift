//
//  LocalLLMClient.swift
//  Moji
//

import Foundation
import FoundationModels

enum LLMError: Error {
    case notAvailable
    case apiError(String)
}

@available(macOS 26.0, *)
class LocalLLMClient {
    static let shared = LocalLLMClient()

    private let model: SystemLanguageModel

    private init() {
        model = SystemLanguageModel.default
    }

    var isAvailable: Bool {
        model.isAvailable
    }

    func fetchEmojis(for text: String) async throws -> String {
        guard isAvailable else {
            throw LLMError.apiError("Apple AI is not available on this device")
        }

        let maxEmojis = SettingsManager.maxEmojis.rawValue
        let prompt = buildPrompt(for: text, style: SettingsManager.emojiStyle, maxEmojis: maxEmojis)
        let session = LanguageModelSession()
        let response = try await session.respond(to: prompt)

        let result = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        return truncateEmojis(result, max: maxEmojis)
    }

    private func truncateEmojis(_ text: String, max: Int) -> String {
        var emojis: [Character] = []
        for char in text {
            if char.unicodeScalars.first?.properties.isEmoji == true {
                emojis.append(char)
                if emojis.count >= max {
                    break
                }
            }
        }
        return String(emojis)
    }

    private func buildPrompt(for text: String, style: EmojiStyle, maxEmojis: Int) -> String {
        let emojiCount = maxEmojis == 1 ? "EXACTLY 1 emoji only" : "NO MORE than \(maxEmojis) emojis"
        return """
        You are an emoji genius. Pick the perfect emoji(s) for this text.

        Style: \(style.promptDescription)

        CRITICAL: Return \(emojiCount). This is a hard limit.
        Output ONLY emoji characters, no text, no spaces.

        Text: \(text)

        Emoji:
        """
    }
}
