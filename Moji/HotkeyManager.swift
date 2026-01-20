//
//  HotkeyManager.swift
//  Moji
//

import AppKit
import Carbon

class HotkeyManager {
    static let shared = HotkeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    private init() {}

    func register() {
        let hotKeyID = EventHotKeyID(signature: OSType(0x4D4F4A49), id: 1) // "MOJI"

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let handler: EventHandlerUPP = { _, event, _ -> OSStatus in
            HotkeyManager.shared.hotkeyPressed()
            return noErr
        }

        InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, nil, &eventHandler)

        // Register Option+M (keycode 46 = M, optionKey modifier)
        let modifiers: UInt32 = UInt32(optionKey)
        let keyCode: UInt32 = 46 // 'M' key

        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    func unregister() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    private func hotkeyPressed() {
        Task {
            await TextProcessor.shared.processSelectedText()
        }
    }
}
