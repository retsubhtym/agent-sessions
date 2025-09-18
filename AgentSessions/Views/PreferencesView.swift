import SwiftUI
import AppKit

struct PreferencesView: View {
    @EnvironmentObject var indexer: SessionIndexer
    @State private var selectedTab: PreferencesTab = .general
    
    // General tab state
    @State private var appearance: AppAppearance = .system
    @State private var modifiedDisplay: SessionIndexer.ModifiedDisplay = .relative
    
    // Codex CLI tab state
    @State private var codexPath: String = ""
    @State private var codexPathValid: Bool = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            Picker("Preferences Tab", selection: $selectedTab) {
                ForEach(PreferencesTab.allCases) { tab in
                    Label(tab.title, systemImage: tab.icon).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            Divider()
            
            // Tab content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedTab {
                    case .general:
                        generalTab
                    case .codexCLI:
                        codexCLITab
                    case .claudeCode:
                        claudeCodeTab
                    }
                }
                .padding(20)
            }
            
            Divider()
            
            // Bottom buttons
            HStack {
                Spacer()
                Button("Reset to Default") { resetToDefaults() }
                Button("Apply") { applySettings() }
            }
            .padding(20)
        }
        .frame(width: 520, height: 420)
        .onAppear {
            loadCurrentSettings()
        }
    }
    
    private var generalTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox(label: Text("Appearance").bold()) {
                PrefRow(label: "Mode") {
                    Picker("Appearance", selection: $appearance) {
                        ForEach(AppAppearance.allCases) { a in
                            Text(a.title).tag(a)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 300)
                }
                PrefRow(label: "Modified") {
                    Picker("Modified Display", selection: $modifiedDisplay) {
                        ForEach(SessionIndexer.ModifiedDisplay.allCases) { m in
                            Text(m.title).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 300)
                }
            }
        }
    }
    
    private var codexCLITab: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox(label: Text("Sessions Root").bold()) {
                PrefRow(label: "Path") {
                    HStack(spacing: 8) {
                        TextField("Path", text: $codexPath)
                            .onChange(of: codexPath) { _, _ in validateCodexPath() }
                        Button("Choose…") { pickCodexFolder() }
                    }
                }
                if !codexPathValid { 
                    Text("Invalid path. Using default.").foregroundStyle(.red) 
                }
                Text("Default: $CODEX_HOME/sessions or ~/.codex/sessions")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .padding(.leading, 120)
            }
            
            GroupBox(label: Text("Display Options").bold()) {
                VStack(alignment: .leading, spacing: 8) {
                    PrefRowSpacer {
                        Toggle("Show Date", isOn: $indexer.showModifiedColumn)
                        Toggle("Show Msgs", isOn: $indexer.showMsgsColumn)
                        Toggle("Show Project", isOn: $indexer.showProjectColumn)
                        Toggle("Show Session", isOn: $indexer.showTitleColumn)
                    }
                }
            }
        }
    }
    
    private var claudeCodeTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox(label: Text("Claude Code Integration").bold()) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Claude Code support coming soon")
                        .foregroundStyle(.secondary)
                    Text("This tab will contain settings for Claude Code session integration.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
    }

    private func loadCurrentSettings() {
        codexPath = indexer.sessionsRootOverride
        validateCodexPath()
        appearance = indexer.appAppearance
        modifiedDisplay = indexer.modifiedDisplay
    }
    
    private func validateCodexPath() {
        guard !codexPath.isEmpty else { codexPathValid = true; return }
        var isDir: ObjCBool = false
        codexPathValid = FileManager.default.fileExists(atPath: codexPath, isDirectory: &isDir) && isDir.boolValue
    }
    
    private func pickCodexFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.begin { resp in
            if resp == .OK, let url = panel.url { 
                codexPath = url.path
                validateCodexPath()
            }
        }
    }
    
    private func resetToDefaults() {
        codexPath = ""
        indexer.sessionsRootOverride = ""
        validateCodexPath()
        indexer.refresh()
        appearance = .system
        indexer.setAppearance(.system)
        modifiedDisplay = .relative
        indexer.setModifiedDisplay(.relative)
    }
    
    private func applySettings() {
        indexer.sessionsRootOverride = codexPath
        indexer.setAppearance(appearance)
        indexer.setModifiedDisplay(modifiedDisplay)
        indexer.refresh()
    }
}

// MARK: - Preferences Tab Enum

private enum PreferencesTab: String, CaseIterable, Identifiable {
    case general = "general"
    case codexCLI = "codexCLI"
    case claudeCode = "claudeCode"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .general: return "General"
        case .codexCLI: return "Codex CLI"
        case .claudeCode: return "Claude Code"
        }
    }
    
    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .codexCLI: return "terminal"
        case .claudeCode: return "brain.head.profile"
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

// Filtering labels removed with section
