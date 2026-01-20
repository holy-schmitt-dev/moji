# Implementation Plan: Moji (macOS Menu Bar App)

## 1. Project Overview
**App Name:** Moji
**Type:** macOS Menu Bar App (Agent) + System Service
**Goal:** A background utility that analyzes highlighted text via a fast LLM and inserts context-aware emojis.
**Core Stack:** Swift, SwiftUI (Settings UI), AppKit (Menu Bar), NSServices (Text Processing).
**LLM Strategy:** Low-latency API calls (OpenAI `gpt-4o-mini` or Groq) to ensure the UI feels snappy.

## 2. Architecture & Data Flow
1.  **User Action:** User highlights text in any app -> Right Click -> Services -> "Moji This".
2.  **System Event:** macOS sends the selected text to `Moji.app` via `NSPasteboard`.
3.  **Processing:**
    * App reads text.
    * App checks User Settings (API Key, Position Preference).
    * App sends text to LLM: "Pick 1-3 emojis that match this vibe."
4.  **Output:** App modifies the text on `NSPasteboard` based on settings (Append, Prepend, or Replace) and signals macOS to paste.

## 3. Configuration & Settings (UserDefaults)
We need a lightweight `SettingsManager` to persist:
* `apiKey`: String (Secure Storage/Keychain preferred, simple String for MVP).
* `emojiStyle`: Enum [Literal, Abstract, Chaotic].
* `insertionMode`: Enum [Append (End), Prepend (Start), Replace (Swap)].

## 4. Phase-by-Phase Implementation

### Phase 1: Project Skeleton & Service Registration
*Goal: Get the app running in the menu bar and registered as a Service.*

* **Action Items:**
    1.  **Xcode Setup:** Create new macOS App (App Lifecycle).
    2.  **Info.plist Configuration:**
        * Add `LSUIElement` = `YES` (Hides app from Dock).
        * Add `NSServices` entry:
            * **Menu Item:** "Moji This"
            * **Message:** `handleService`
            * **Port Name:** `MojiApp`
            * **Send Type:** `NSStringPboardType`
            * **Return Type:** `NSStringPboardType`
    3.  **AppDelegate:** Create `ServiceProvider` class to listen for the system call.

### Phase 2: The Service Logic (The "Plumbing")
*Goal: Successfully receive text from another app and print it to the console.*

* **File:** `ServiceProvider.swift`
* **Logic:**
    * Implement `@objc func handleService(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString?>)`
    * Extract string from `pboard`.
    * *Temporary:* Append a hardcoded "✅" and write back to `pboard` to verify the connection works.

### Phase 3: The Brains (LLM Client)
*Goal: Send text to an API and get an emoji back.*

* **File:** `LLMClient.swift`
* **Logic:**
    * Simple `URLSession` request.
    * **System Prompt:** "You are an API that returns ONLY emojis. Do not output text. Analyze the following phrase and return 1-3 emojis that match the tone. Input: '{text}'"
    * **Model:** Hardcode `gpt-4o-mini` (or user defined) for sub-500ms response times.

### Phase 4: The Menu Bar UI
*Goal: Allow user to input API Key and change behavior.*

* **File:** `MenuBarView.swift`
* **UI Components:**
    * `TextField`: "OpenAI API Key"
    * `Picker`: "Insertion Mode" (Append/Prepend/Replace)
    * `Button`: "Quit Moji"
* **Wiring:** Connect `MenuBarView` to `SettingsManager`.

### Phase 5: Integration & Polish
*Goal: Connect the Service Logic to the LLM Client.*

* **Refining `ServiceProvider.swift`:**
    * Replace hardcoded "✅" with `await LLMClient.fetchEmojis(for: text)`.
    * Apply `SettingsManager.insertionMode` logic.
    * Write result back to Pasteboard.

## 5. Technical Constraints & Notes
* **Sandbox:** `NSServices` can be finicky with App Sandbox enabled during development. If the service doesn't appear, try disabling "App Sandbox" in Xcode Signing & Capabilities for the debug build.
* **Latency:** The LLM call must be non-blocking, but `NSServices` expects a synchronous return or a swift callback. We may need to use a `DispatchSemaphore` or handle the paste manually if the API takes too long.
* **Privacy:** Since we are sending clipboard data to an API, add a small disclaimer in the Settings UI.

## 6. Prompting Guide for Claude Code
* **Step 1:** "Scaffold the `ServiceProvider.swift` class compatible with `NSServices`."
* **Step 2:** "Create a `NetworkManager` for OpenAI chat completions, optimized for minimal token usage."
* **Step 3:** "Build a SwiftUI MenuBarExtra view that saves an API key to UserDefaults."