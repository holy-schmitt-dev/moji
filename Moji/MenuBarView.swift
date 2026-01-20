//
//  MenuBarView.swift
//  Moji
//

import SwiftUI

// MARK: - Custom Font Extension

extension Font {
    static func rounded(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .rounded, weight: weight)
    }

    static func rounded(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// MARK: - Theme Colors

struct MojiTheme {
    static let accent = Color.purple
    static let accentGradient = LinearGradient(
        colors: [Color(red: 0.5, green: 0.3, blue: 0.9), Color(red: 0.6, green: 0.4, blue: 1.0)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let subtleGradient = LinearGradient(
        colors: [Color.purple.opacity(0.12), Color(red: 0.5, green: 0.4, blue: 0.9).opacity(0.08)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let cardBackground = Color.primary.opacity(0.05)
}

// MARK: - Pill Toggle Button

struct PillToggle<T: Hashable>: View {
    let options: [(value: T, label: String)]
    @Binding var selection: T

    var body: some View {
        HStack(spacing: 6) {
            ForEach(options.indices, id: \.self) { index in
                let option = options[index]
                let isSelected = selection == option.value

                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selection = option.value
                    }
                }) {
                    Text(option.label)
                        .font(.rounded(size: 13, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? .white : .primary.opacity(0.7))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            Group {
                                if isSelected {
                                    Capsule()
                                        .fill(MojiTheme.accentGradient)
                                        .shadow(color: .purple.opacity(0.3), radius: 4, y: 2)
                                } else {
                                    Capsule()
                                        .fill(Color.primary.opacity(0.08))
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let icon: String
    var color: Color = .primary

    var body: some View {
        Label {
            Text(title)
                .font(.rounded(.headline, weight: .bold))
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(MojiTheme.accentGradient)
        }
        .foregroundColor(color)
    }
}

// MARK: - Main View

struct MenuBarView: View {
    @AppStorage("emojiStyle") private var emojiStyle = EmojiStyle.literal.rawValue
    @AppStorage("insertionMode") private var insertionMode = InsertionMode.append.rawValue
    @AppStorage("maxEmojis") private var maxEmojis = MaxEmojis.one.rawValue
    @StateObject private var history = HistoryManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            ScrollView {
                VStack(spacing: 20) {
                    // Recent History
                    if !history.recents.isEmpty {
                        historySection
                    }

                    // Settings
                    settingsSection

                    // Help
                    helpSection
                }
                .padding()
            }

            // Footer
            footerView
        }
        .frame(width: 340, height: 580)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            HStack(spacing: 10) {
                Text("✨")
                    .font(.system(size: 28))
                Text("Moji")
                    .font(.rounded(size: 24, weight: .bold))
                    .foregroundStyle(MojiTheme.accentGradient)
            }

            Spacer()

            Text("⌥M")
                .font(.rounded(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(MojiTheme.accentGradient)
                )
        }
        .padding()
        .background(MojiTheme.subtleGradient)
    }

    // MARK: - History Section

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Recent", icon: "clock.fill")
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        history.clearHistory()
                    }
                }) {
                    Text("Clear")
                        .font(.rounded(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 4) {
                ForEach(history.recents.prefix(5)) { item in
                    historyRow(item: item)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(MojiTheme.cardBackground)
        )
    }

    private func historyRow(item: HistoryItem) -> some View {
        HStack(spacing: 12) {
            Text(item.emojis)
                .font(.system(size: 22))

            Text(item.originalText)
                .font(.rounded(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.03))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            copyToClipboard(item.emojis)
        }
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Settings", icon: "slider.horizontal.3")

            // Max Emojis
            VStack(alignment: .leading, spacing: 10) {
                Label {
                    Text("Max Emojis")
                        .font(.rounded(size: 13, weight: .medium))
                } icon: {
                    Text("#")
                        .font(.rounded(size: 13, weight: .bold))
                        .foregroundStyle(MojiTheme.accentGradient)
                }
                .foregroundColor(.secondary)

                PillToggle(
                    options: MaxEmojis.allCases.map { ($0.rawValue, $0.display) },
                    selection: $maxEmojis
                )
            }

            // Emoji Style
            VStack(alignment: .leading, spacing: 10) {
                Label {
                    Text("Style")
                        .font(.rounded(size: 13, weight: .medium))
                } icon: {
                    Image(systemName: "paintbrush.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(MojiTheme.accentGradient)
                }
                .foregroundColor(.secondary)

                PillToggle(
                    options: EmojiStyle.allCases.map { ($0.rawValue, $0.rawValue) },
                    selection: $emojiStyle
                )
            }

            // Insertion Mode
            VStack(alignment: .leading, spacing: 10) {
                Label {
                    Text("Insert Mode")
                        .font(.rounded(size: 13, weight: .medium))
                } icon: {
                    Image(systemName: "text.insert")
                        .font(.system(size: 12))
                        .foregroundStyle(MojiTheme.accentGradient)
                }
                .foregroundColor(.secondary)

                PillToggle(
                    options: InsertionMode.allCases.map { ($0.rawValue, $0.rawValue) },
                    selection: $insertionMode
                )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(MojiTheme.cardBackground)
        )
    }

    // MARK: - Help Section

    private var helpSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "How to Use", icon: "sparkles")

            // Quick Start
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 8) {
                    helpStep(number: "1", text: "Select any text in any app")
                    helpStep(number: "2", text: "Press ⌥M (Option + M)")
                    helpStep(number: "3", text: "Emojis are added automatically!")
                }
            }

            Divider()
                .background(Color.purple.opacity(0.3))

            // Alternative Method
            VStack(alignment: .leading, spacing: 6) {
                Label {
                    Text("Alternative")
                        .font(.rounded(size: 12, weight: .semibold))
                } icon: {
                    Image(systemName: "cursorarrow.click.2")
                        .font(.system(size: 11))
                }
                .foregroundStyle(MojiTheme.accentGradient)

                Text("Right-click → Services → Moji This")
                    .font(.rounded(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Divider()
                .background(Color.purple.opacity(0.3))

            // Permissions
            VStack(alignment: .leading, spacing: 10) {
                Label {
                    Text("Permissions")
                        .font(.rounded(size: 12, weight: .semibold))
                } icon: {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 11))
                }
                .foregroundStyle(MojiTheme.accentGradient)

                Text("Enable Accessibility for ⌥M hotkey:")
                    .font(.rounded(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                Button(action: openAccessibilitySettings) {
                    HStack(spacing: 6) {
                        Image(systemName: "gear")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Open System Settings")
                            .font(.rounded(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(MojiTheme.accentGradient)
                    )
                }
                .buttonStyle(.plain)
            }

            Divider()
                .background(Color.purple.opacity(0.3))

            // Styles Explained
            VStack(alignment: .leading, spacing: 8) {
                Label {
                    Text("Emoji Styles")
                        .font(.rounded(size: 12, weight: .semibold))
                } icon: {
                    Image(systemName: "theatermasks.fill")
                        .font(.system(size: 11))
                }
                .foregroundStyle(MojiTheme.accentGradient)

                VStack(alignment: .leading, spacing: 4) {
                    styleExplanation(style: "Literal", emoji: "🎯", desc: "dog → 🐕")
                    styleExplanation(style: "Abstract", emoji: "💫", desc: "love → 💫")
                    styleExplanation(style: "Chaotic", emoji: "🤪", desc: "meeting → 🦷")
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(MojiTheme.cardBackground)
        )
    }

    private func helpStep(number: String, text: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(number)
                .font(.rounded(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(
                    Circle()
                        .fill(MojiTheme.accentGradient)
                )

            Text(text)
                .font(.rounded(size: 13, weight: .medium))
                .foregroundColor(.primary)
        }
    }

    private func styleExplanation(style: String, emoji: String, desc: String) -> some View {
        HStack(spacing: 8) {
            Text(emoji)
                .font(.system(size: 14))

            Text(style)
                .font(.rounded(size: 12, weight: .semibold))
                .foregroundColor(.primary)
                .frame(width: 55, alignment: .leading)

            Text(desc)
                .font(.rounded(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
    }

    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack {
            Button(action: { NSApplication.shared.terminate(nil) }) {
                HStack(spacing: 6) {
                    Image(systemName: "power")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Quit")
                        .font(.rounded(size: 12, weight: .medium))
                }
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("v1.0")
                .font(.rounded(size: 11, weight: .medium))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(MojiTheme.subtleGradient.opacity(0.5))
    }

    // MARK: - Helpers

    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

#Preview {
    MenuBarView()
}
