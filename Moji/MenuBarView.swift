//
//  MenuBarView.swift
//  Moji
//

import SwiftUI

struct MenuBarView: View {
    @AppStorage("emojiStyle") private var emojiStyle = EmojiStyle.literal.rawValue
    @AppStorage("insertionMode") private var insertionMode = InsertionMode.append.rawValue
    @AppStorage("maxEmojis") private var maxEmojis = MaxEmojis.one.rawValue
    @StateObject private var history = HistoryManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    // Quick Favorites
                    if !history.favorites.isEmpty {
                        favoritesSection
                        Divider()
                    }

                    // Recent History
                    if !history.recents.isEmpty {
                        historySection
                        Divider()
                    }

                    // Settings
                    settingsSection

                    Divider()

                    // Help
                    helpSection
                }
                .padding()
            }

            Divider()

            // Footer
            footerView
        }
        .frame(width: 340, height: 580)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            HStack(spacing: 8) {
                Text("✨")
                    .font(.title)
                Text("Moji")
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            Spacer()

            Text("⌥M")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.secondary.opacity(0.2))
                .cornerRadius(8)
        }
        .padding()
    }

    // MARK: - Favorites Section

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Favorites", systemImage: "star.fill")
                    .font(.headline)
                    .foregroundColor(.orange)
                Spacer()
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 56))], spacing: 10) {
                ForEach(history.favorites.prefix(8)) { item in
                    emojiButton(item: item)
                }
            }
        }
    }

    // MARK: - History Section

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Recent", systemImage: "clock")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                Button("Clear") {
                    withAnimation {
                        history.clearHistory()
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                .buttonStyle(.plain)
            }

            ForEach(history.recents.prefix(5)) { item in
                historyRow(item: item)
            }
        }
    }

    private func emojiButton(item: HistoryItem) -> some View {
        Button(action: {
            copyToClipboard(item.emojis)
        }) {
            Text(item.emojis)
                .font(.title)
                .frame(width: 52, height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.background)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(.secondary.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .help(item.originalText)
        .contextMenu {
            Button(action: { history.toggleFavorite(item) }) {
                Label(item.isFavorite ? "Unfavorite" : "Favorite", systemImage: item.isFavorite ? "star.slash" : "star")
            }
            Button(action: { copyToClipboard(item.emojis) }) {
                Label("Copy", systemImage: "doc.on.doc")
            }
            Divider()
            Button(role: .destructive, action: { history.removeItem(item) }) {
                Label("Remove", systemImage: "trash")
            }
        }
    }

    private func historyRow(item: HistoryItem) -> some View {
        HStack {
            Text(item.emojis)
                .font(.title2)

            Text(item.originalText)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()

            Button(action: { history.toggleFavorite(item) }) {
                Image(systemName: item.isFavorite ? "star.fill" : "star")
                    .font(.subheadline)
                    .foregroundColor(item.isFavorite ? .orange : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture {
            copyToClipboard(item.emojis)
        }
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Settings", systemImage: "gearshape")
                .font(.headline)

            // Max Emojis
            VStack(alignment: .leading, spacing: 8) {
                Label("Max Emojis", systemImage: "number")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Picker("", selection: $maxEmojis) {
                    ForEach(MaxEmojis.allCases, id: \.self) { count in
                        Text(count.display).tag(count.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            // Emoji Style
            VStack(alignment: .leading, spacing: 8) {
                Label("Style", systemImage: "paintbrush")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Picker("", selection: $emojiStyle) {
                    ForEach(EmojiStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            // Insertion Mode
            VStack(alignment: .leading, spacing: 8) {
                Label("Insert", systemImage: "text.insert")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Picker("", selection: $insertionMode) {
                    ForEach(InsertionMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
        }
    }

    // MARK: - Help Section

    private var helpSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("How to Use", systemImage: "questionmark.circle")
                .font(.headline)

            // Quick Start
            VStack(alignment: .leading, spacing: 8) {
                Label("Quick Start", systemImage: "sparkles")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.purple)

                VStack(alignment: .leading, spacing: 6) {
                    helpStep(number: "1", text: "Select any text in any app")
                    helpStep(number: "2", text: "Press ⌥M (Option + M)")
                    helpStep(number: "3", text: "Emojis are added automatically!")
                }
            }

            Divider()

            // Alternative Method
            VStack(alignment: .leading, spacing: 8) {
                Label("Alternative: Services Menu", systemImage: "contextualmenu.and.cursorarrow")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)

                Text("Select text → Right-click → Services → Moji This")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Permissions
            VStack(alignment: .leading, spacing: 8) {
                Label("Permissions", systemImage: "lock.shield")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)

                Text("For ⌥M to work, Moji needs Accessibility access:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("System Settings → Privacy & Security → Accessibility → Enable Moji")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.secondary.opacity(0.1))
                    )

                Button(action: openAccessibilitySettings) {
                    Label("Open Settings", systemImage: "arrow.up.forward.app")
                        .font(.subheadline)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            Divider()

            // Styles Explained
            VStack(alignment: .leading, spacing: 8) {
                Label("Emoji Styles", systemImage: "paintbrush")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)

                VStack(alignment: .leading, spacing: 6) {
                    styleExplanation(style: "Literal", desc: "Direct match (dog → 🐕)")
                    styleExplanation(style: "Abstract", desc: "Vibes & mood (love → 💫)")
                    styleExplanation(style: "Chaotic", desc: "Weird & fun (meeting → 🦷)")
                }
            }
        }
    }

    private func helpStep(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(.purple))

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }

    private func styleExplanation(style: String, desc: String) -> some View {
        HStack(spacing: 8) {
            Text(style)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 65, alignment: .leading)

            Text(desc)
                .font(.subheadline)
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
                Label("Quit", systemImage: "power")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("v1.0")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
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
