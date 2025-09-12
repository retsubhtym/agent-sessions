import SwiftUI
import AppKit

struct PreferencesView: View {
    @EnvironmentObject var indexer: SessionIndexer
    @State private var path: String = ""
    @State private var valid: Bool = true
    @State private var theme: TranscriptTheme = .codexDark

    var body: some View {
        Form {
            Section("Sessions Root") {
                HStack {
                    TextField("Path", text: $path)
                        .onChange(of: path) { _, _ in validate() }
                    Button("Choose…") { pickFolder() }
                }
                if !valid {
                    Text("Invalid path. Using default.")
                        .foregroundStyle(.red)
                }
                Text("Default: $CODEX_HOME/sessions or ~/.codex/sessions")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
            Section("Appearance") {
                Picker("Theme", selection: $theme) {
                    Text("Codex Dark").tag(TranscriptTheme.codexDark)
                    Text("Monochrome").tag(TranscriptTheme.monochrome)
                }
            }
            HStack {
                Spacer()
                Button("Reset to Default") { path = ""; indexer.sessionsRootOverride = ""; validate(); indexer.refresh() }
                Button("Apply") {
                    indexer.sessionsRootOverride = path
                    indexer.setTheme(theme)
                    indexer.refresh()
                }
            }
        }
        .padding(16)
        .onAppear {
            path = indexer.sessionsRootOverride
            validate()
            theme = indexer.prefTheme
        }
    }

    private func validate() {
        guard !path.isEmpty else { valid = true; return }
        var isDir: ObjCBool = false
        valid = FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
    }

    private func pickFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.begin { resp in
            if resp == .OK, let url = panel.url { path = url.path; validate() }
        }
    }
}
