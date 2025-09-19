import SwiftUI
import AppKit

final class PreferencesWindowController: NSObject, NSWindowDelegate {
    static let shared = PreferencesWindowController()

    private var window: NSWindow?

    func show(indexer: SessionIndexer) {
        if let win = window {
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hosting = NSHostingController(rootView: PreferencesView().environmentObject(indexer))
        let win = NSWindow(contentViewController: hosting)
        win.title = "Preferences"
        win.styleMask = [.titled, .closable, .miniaturizable]
        win.isReleasedWhenClosed = false
        win.center()
        win.setFrameAutosaveName("PreferencesWindow")
        win.setContentSize(NSSize(width: 740, height: 520))
        win.delegate = self
        self.window = win
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        // Keep controller but drop the window so it can be rebuilt later
        if let win = notification.object as? NSWindow, win == window {
            window = nil
        }
    }
}
