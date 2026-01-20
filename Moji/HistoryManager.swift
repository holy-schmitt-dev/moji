//
//  HistoryManager.swift
//  Moji
//

import Foundation
import Combine

struct HistoryItem: Codable, Identifiable, Equatable {
    let id: UUID
    let originalText: String
    let emojis: String
    let timestamp: Date

    init(originalText: String, emojis: String) {
        self.id = UUID()
        self.originalText = originalText
        self.emojis = emojis
        self.timestamp = Date()
    }
}

class HistoryManager: ObservableObject {
    static let shared = HistoryManager()

    @Published private(set) var items: [HistoryItem] = []

    private let maxItems = 20
    private let userDefaultsKey = "emojiHistory"

    private init() {
        loadHistory()
    }

    func addItem(originalText: String, emojis: String) {
        let item = HistoryItem(originalText: originalText, emojis: emojis)

        DispatchQueue.main.async {
            // Remove duplicates
            self.items.removeAll { $0.emojis == emojis && $0.originalText == originalText }

            // Add to front
            self.items.insert(item, at: 0)

            // Trim to max
            if self.items.count > self.maxItems {
                self.items = Array(self.items.prefix(self.maxItems))
            }

            self.saveHistory()
        }
    }

    func removeItem(_ item: HistoryItem) {
        items.removeAll { $0.id == item.id }
        saveHistory()
    }

    func clearHistory() {
        items.removeAll()
        saveHistory()
    }

    var recents: [HistoryItem] {
        Array(items.prefix(10))
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([HistoryItem].self, from: data) {
            items = decoded
        }
    }
}
