import SwiftUI
import AppKit

/// Attaches to the view hierarchy and configures the hosting NSWindow
/// with an autosave name so frame/position persist across relaunches.
struct WindowAutosave: NSViewRepresentable {
    let name: String

    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        DispatchQueue.main.async {
            guard let win = v.window else { return }
            // Configure once
            if win.frameAutosaveName != name {
                win.setFrameAutosaveName(name)
                win.isRestorable = true
            }
            if name == "MainWindow" {
                win.identifier = NSUserInterfaceItemIdentifier("AgentSessionsMainWindow")
                win.isReleasedWhenClosed = false
                MainWindowTracker.shared.register(window: win)
            }
        }
        return v
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // No-op
    }
}

@MainActor
final class MainWindowTracker {
    static let shared = MainWindowTracker()

    private init() {}

    private weak var window: NSWindow?

    func register(window: NSWindow) {
        self.window = window
    }

    func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        guard let window else { return }
        if window.isMiniaturized {
            window.deminiaturize(nil)
        }
        window.makeKeyAndOrderFront(nil)
    }
}

