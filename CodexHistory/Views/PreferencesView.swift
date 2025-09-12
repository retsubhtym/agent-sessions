import SwiftUI
import AppKit

struct PreferencesView: View {
    @EnvironmentObject var indexer: SessionIndexer
    @State private var path: String = ""
    @State private var valid: Bool = true
    @State private var theme: TranscriptTheme = .codexDark
    @State private var localKinds: Set<SessionEventKind> = Set(SessionEventKind.allCases)

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
            Section("Filtering") {
                Toggle("Hide sessions with zero messages", isOn: $indexer.hideZeroMessageSessionsPref)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Session kinds shown in list:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        ForEach(SessionEventKind.allCases, id: \.self) { kind in
                            Toggle(kindLabel(kind), isOn: Binding(
                                get: { localKinds.contains(kind) },
                                set: { newVal in
                                    if newVal { localKinds.insert(kind) } else { localKinds.remove(kind) }
                                }
                            ))
                            .toggleStyle(.button)
                        }
                    }
                    HStack(spacing: 8) {
                        Button("Select All") { localKinds = Set(SessionEventKind.allCases) }
                        Button("Select None") { localKinds = [] }
                    }
                }
            }
            HStack {
                Spacer()
                Button("Reset to Default") { path = ""; indexer.sessionsRootOverride = ""; validate(); indexer.refresh() }
                Button("Apply") {
                    indexer.sessionsRootOverride = path
                    indexer.setTheme(theme)
                    indexer.selectedKinds = localKinds
                    indexer.refresh()
                }
            }
        }
        .padding(16)
        .onAppear {
            path = indexer.sessionsRootOverride
            validate()
            theme = indexer.prefTheme
            localKinds = indexer.selectedKinds
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

private func kindLabel(_ k: SessionEventKind) -> String {
    switch k {
    case .user: return "User"
    case .assistant: return "Assistant"
    case .tool_call: return "Tool Call"
    case .tool_result: return "Tool Result"
    case .error: return "Error"
    case .meta: return "Meta"
    }
}
