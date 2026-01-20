//
//  SettingsManager.swift
//  Moji
//

import Foundation

enum EmojiStyle: String, CaseIterable {
    case literal = "Literal"
    case abstract = "Abstract"
    case chaotic = "Chaotic"

    var promptDescription: String {
        switch self {
        case .literal: return "a perfect visual match - the most iconic, recognizable emoji for this exact thing"
        case .abstract: return "vibes-based and metaphorical - capture the emotional energy, not the literal meaning"
        case .chaotic: return "unhinged and hilarious - weird, surprising, delightfully cursed choices that make people laugh"
        }
    }
}

enum InsertionMode: String, CaseIterable {
    case append = "Append"
    case prepend = "Prepend"
    case replace = "Replace"
}

enum MaxEmojis: Int, CaseIterable {
    case one = 1
    case two = 2
    case three = 3
    case auto = 0

    var display: String {
        switch self {
        case .one: return "1"
        case .two: return "2"
        case .three: return "3"
        case .auto: return "Auto"
        }
    }

    var isAuto: Bool {
        self == .auto
    }
}

struct SettingsManager {
    static var emojiStyle: EmojiStyle {
        if let raw = UserDefaults.standard.string(forKey: "emojiStyle"),
           let style = EmojiStyle(rawValue: raw) {
            return style
        }
        return .literal
    }

    static var insertionMode: InsertionMode {
        if let raw = UserDefaults.standard.string(forKey: "insertionMode"),
           let mode = InsertionMode(rawValue: raw) {
            return mode
        }
        return .append
    }

    static var maxEmojis: MaxEmojis {
        let raw = UserDefaults.standard.integer(forKey: "maxEmojis")
        return MaxEmojis(rawValue: raw) ?? .one
    }
}
