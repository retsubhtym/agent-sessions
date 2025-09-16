import SwiftUI
import AppKit

struct PreferencesView: View {
    @EnvironmentObject var indexer: SessionIndexer
    @State private var path: String = ""
    @State private var valid: Bool = true
    // Appearance
    @State private var appearance: AppAppearance = .system
    @State private var modifiedDisplay: SessionIndexer.ModifiedDisplay = .relative
    @State private var localKinds: Set<SessionEventKind> = Set(SessionEventKind.allCases)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox(label: Text("Sessions Root").bold()) {
                PrefRow(label: "Path") {
                    HStack(spacing: 8) {
                        TextField("Path", text: $path)
                            .onChange(of: path) { _, _ in validate() }
                        Button("Choose…") { pickFolder() }
                    }
                }
                if !valid { Text("Invalid path. Using default.").foregroundStyle(.red) }
                Text("Default: $CODEX_HOME/sessions or ~/.codex/sessions")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .padding(.leading, 160)
            }

            GroupBox(label: Text("Appearance").bold()) {
                PrefRow(label: "Mode") {
                    Picker("Appearance", selection: $appearance) {
                        ForEach(AppAppearance.allCases) { a in
                            Text(a.title).tag(a)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 360)
                }
                PrefRow(label: "Modified") {
                    Picker("Modified Display", selection: $modifiedDisplay) {
                        ForEach(SessionIndexer.ModifiedDisplay.allCases) { m in
                            Text(m.title).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 360)
                }
            }

            GroupBox(label: Text("Filtering").bold()) {
                VStack(alignment: .leading, spacing: 8) {
                    PrefRowSpacer {
                        Toggle("Hide sessions with zero messages", isOn: $indexer.hideZeroMessageSessionsPref)
                    }
                    PrefRow(label: "Kinds") {
                        // Single line row; chips wrap when space permits
                        Flow(spacing: 8) {
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
                    }
                    PrefRowSpacer {
                        HStack(spacing: 8) {
                            Button("Select All") { localKinds = Set(SessionEventKind.allCases) }
                            Button("Select None") { localKinds = [] }
                        }
                    }
                }
            }

            GroupBox(label: Text("Columns").bold()) {
                VStack(alignment: .leading, spacing: 8) {
                    PrefRowSpacer {
                        Toggle("Show ID", isOn: $indexer.showIDColumn)
                        Toggle("Show Modified", isOn: $indexer.showModifiedColumn)
                        Toggle("Show Msgs", isOn: $indexer.showMsgsColumn)
                        Toggle("Show Project", isOn: $indexer.showProjectColumn)
                        Toggle("Show Title", isOn: $indexer.showTitleColumn)
                    }
                    PrefRowSpacer {
                        Toggle("Project before Title", isOn: $indexer.projectBeforeTitle)
                    }
                }
            }

            HStack {
                Spacer()
                Button("Reset to Default") { path = ""; indexer.sessionsRootOverride = ""; validate(); indexer.refresh(); appearance = .system; indexer.setAppearance(.system); modifiedDisplay = .relative; indexer.setModifiedDisplay(.relative) }
                Button("Apply") {
                    indexer.sessionsRootOverride = path
                    indexer.setAppearance(appearance)
                    indexer.setModifiedDisplay(modifiedDisplay)
                    indexer.selectedKinds = localKinds
                    indexer.refresh()
                }
            }
        }
        .padding(20)
        .onAppear {
            path = indexer.sessionsRootOverride
            validate()
            appearance = indexer.appAppearance
            modifiedDisplay = indexer.modifiedDisplay
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

// MARK: - Preferences layout helpers

private struct PrefRow<Content: View>: View {
    let label: String
    @ViewBuilder var content: () -> Content
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .frame(width: 150, alignment: .trailing)
            content()
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

private struct PrefRowSpacer<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Color.clear.frame(width: 150)
            content()
            Spacer()
        }
        .padding(.vertical, 4)
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
