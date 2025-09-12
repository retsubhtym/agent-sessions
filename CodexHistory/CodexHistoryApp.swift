import SwiftUI
import AppKit

@main
struct CodexHistoryApp: App {
    @StateObject private var indexer = SessionIndexer()
    @State private var selectedSessionID: String?
    @State private var selectedEventID: String?
    @State private var focusSearchToggle: Bool = false
    @State private var showingFirstRunPrompt: Bool = false

    var body: some Scene {
        WindowGroup("CodexHistory") {
            ContentView()
                .environmentObject(indexer)
                .onAppear {
                    // First run check: if directory is unreadable prompt user
                    if !indexer.canAccessRootDirectory {
                        showingFirstRunPrompt = true
                    }
                    indexer.refresh()
                }
                .sheet(isPresented: $showingFirstRunPrompt) {
                    FirstRunPrompt(showing: $showingFirstRunPrompt)
                        .environmentObject(indexer)
                }
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Refresh") { indexer.refresh() }
                    .keyboardShortcut("r", modifiers: .command)
                Button("Copy Transcript") { indexer.requestCopyPlain.toggle() }
                    .keyboardShortcut("c", modifiers: [.command, .shift])
                Button("Find in Transcript") { indexer.requestTranscriptFindFocus.toggle() }
                    .keyboardShortcut("f", modifiers: .command)
            }
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") { PreferencesWindowController.shared.show(indexer: indexer) }
                    .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}

private struct ContentView: View {
    @EnvironmentObject var indexer: SessionIndexer
    @State private var selection: String?
    @State private var selectedEvent: String?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SessionsListView(selection: $selection)
        } detail: {
            TranscriptPlainView(sessionID: selection)
        }
        .preferredColorScheme(indexer.appAppearance.colorScheme)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                SearchFiltersView()
            }
            ToolbarItem(placement: .automatic) {
                Button(action: { indexer.refresh() }) {
                    if indexer.isIndexing {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .help("Refresh index")
            }
            ToolbarItem(placement: .automatic) {
                Button(action: { PreferencesWindowController.shared.show(indexer: indexer) }) {
                    Image(systemName: "gear")
                }
                .help("Preferences")
            }
        }
    }

    // Rely on system-provided sidebar toggle in the titlebar.
}

private struct FirstRunPrompt: View {
    @EnvironmentObject var indexer: SessionIndexer
    @Binding var showing: Bool
    @State private var presentingPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose Codex sessions directory")
                .font(.title2).bold()
            Text("CodexHistory could not read the default sessions folder. Pick a custom path or set the CODEX_HOME environment variable.")
                .foregroundStyle(.secondary)
            HStack {
                Button("Pick Folder…") { pickFolder() }
                Button("Use Default") {
                    indexer.sessionsRootOverride = ""
                    indexer.refresh()
                    showing = false
                }
                Spacer()
                Button("Close") { showing = false }
            }
        }
        .padding(20)
        .frame(width: 520)
    }

    private func pickFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.begin { response in
            if response == .OK, let url = panel.url {
                indexer.sessionsRootOverride = url.path
                indexer.refresh()
                showing = false
            }
        }
    }
}
