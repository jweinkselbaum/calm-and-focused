import AppKit
import SwiftUI
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private(set) var preferencesManager = PreferencesManager()
    private(set) var soundEngine = SoundEngine()

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var preferencesWindow: NSWindow?
    private var cancellables: Set<AnyCancellable> = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Apply saved dock preference
        NSApp.setActivationPolicy(preferencesManager.showInDock ? .regular : .accessory)

        // Restore active sounds with saved volumes
        for id in preferencesManager.enabledSoundIDs {
            soundEngine.setVolume(preferencesManager.volume(for: id), for: id)
            if preferencesManager.isActive(id) {
                soundEngine.setActive(true, for: id)
            }
        }

        // Build status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(named: "AppIcon")
                ?? NSImage(systemSymbolName: "speaker.wave.2.fill", accessibilityDescription: "Calm and Focused")
            button.image?.size = NSSize(width: 18, height: 18)
            button.imageScaling = .scaleProportionallyDown
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Build popover
        let contentView = ContentView(
            onOpenPreferences: { [weak self] in self?.openPreferences() },
            onQuit: { NSApp.terminate(nil) }
        )
        .environmentObject(preferencesManager)
        .environmentObject(soundEngine)

        popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(rootView: contentView)

        updatePopoverSize()

        // Resize popover when enabled sounds change
        preferencesManager.$enabledSoundIDs
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updatePopoverSize() }
            .store(in: &cancellables)
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func updatePopoverSize() {
        let count = max(1, preferencesManager.enabledSoundIDs.count)
        let trackH = CGFloat(52 * min(count, 5))
        let height = 42 + trackH + 1 + 40   // header + tracks + divider + footer
        popover.contentSize = NSSize(width: 280, height: height)
    }

    func openPreferences() {
        if popover.isShown { popover.performClose(nil) }

        if let win = preferencesWindow, win.isVisible {
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let prefView = PreferencesView()
            .environmentObject(preferencesManager)
            .environmentObject(soundEngine)

        let controller = NSHostingController(rootView: prefView)
        let window = NSWindow(contentViewController: controller)
        window.title = "Calm and Focused — Preferences"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        preferencesWindow = window
    }
}
