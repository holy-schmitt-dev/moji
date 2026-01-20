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
    var isFavorite: Bool

    init(originalText: String, emojis: String, isFavorite: Bool = false) {
        self.id = UUID()
        self.originalText = originalText
        self.emojis = emojis
        self.timestamp = Date()
        self.isFavorite = isFavorite
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

            // Trim to max (but keep favorites)
            let favorites = self.items.filter { $0.isFavorite }
            var nonFavorites = self.items.filter { !$0.isFavorite }

            if nonFavorites.count > self.maxItems {
                nonFavorites = Array(nonFavorites.prefix(self.maxItems))
            }

            self.items = favorites + nonFavorites
            self.items.sort { $0.timestamp > $1.timestamp }

            self.saveHistory()
        }
    }

    func toggleFavorite(_ item: HistoryItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isFavorite.toggle()
            saveHistory()
        }
    }

    func removeItem(_ item: HistoryItem) {
        items.removeAll { $0.id == item.id }
        saveHistory()
    }

    func clearHistory() {
        items.removeAll { !$0.isFavorite }
        saveHistory()
    }

    var favorites: [HistoryItem] {
        items.filter { $0.isFavorite }
    }

    var recents: [HistoryItem] {
        items.filter { !$0.isFavorite }.prefix(10).map { $0 }
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
