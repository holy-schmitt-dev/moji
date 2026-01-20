//
//  MojiApp.swift
//  Moji
//
//  Created by Michael Schmitt on 1/19/26.
//

import SwiftUI
import AppKit
import ServiceManagement

@main
struct MojiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("Moji", systemImage: "face.smiling") {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var serviceProvider: ServiceProvider?

    func applicationDidFinishLaunching(_ notification: Notification) {
        serviceProvider = ServiceProvider()
        NSApp.servicesProvider = serviceProvider
        NSUpdateDynamicServices()

        HotkeyManager.shared.register()
        requestAccessibilityPermission()
        enableLaunchAtLogin()
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotkeyManager.shared.unregister()
    }

    private func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    private func enableLaunchAtLogin() {
        do {
            // Only enable if not already enabled
            if SMAppService.mainApp.status != .enabled {
                try SMAppService.mainApp.register()
            }
        } catch {
            print("Failed to enable launch at login: \(error)")
        }
    }
}
