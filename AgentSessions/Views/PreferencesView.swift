import SwiftUI
import AppKit

private let labelColumnWidth: CGFloat = 170

struct PreferencesView: View {
    @EnvironmentObject var indexer: SessionIndexer
    @State private var selectedTab: PreferencesTab? = .general

    // General tab state
    @State private var appearance: AppAppearance = .system
    @State private var modifiedDisplay: SessionIndexer.ModifiedDisplay = .relative

    // Codex CLI tab state
    @State private var codexPath: String = ""
    @State private var codexPathValid: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                sidebar
                Divider()
                tabBody
            }
            Divider()
            footer
        }
        .frame(width: 740, height: 520)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear(perform: loadCurrentSettings)
    }

    // MARK: Layout chrome

    private var sidebar: some View {
        List(visibleTabs, selection: $selectedTab) { tab in
            Label(tab.title, systemImage: tab.iconName)
                .tag(tab)
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200, maxWidth: 220)
    }

    private var tabBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                switch selectedTab ?? .general {
                case .general:
                    generalTab
                case .codexCLI:
                    codexCLITab
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Spacer()
            Button("Reset to Defaults", action: resetToDefaults)
                .buttonStyle(.bordered)
            Button("Apply", action: applySettings)
                .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: Tabs

    private var generalTab: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text("General")
                .font(.title2)
                .fontWeight(.semibold)

            sectionHeader("Appearance")
            VStack(alignment: .leading, spacing: 12) {
                labeledRow("Theme") {
                    Picker("Theme", selection: $appearance) {
                        ForEach(AppAppearance.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Divider()

                labeledRow("Modified Date") {
                    Picker("Modified Display", selection: $modifiedDisplay) {
                        ForEach(SessionIndexer.ModifiedDisplay.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }

            sectionHeader("Sessions Sidebar")
            VStack(alignment: .leading, spacing: 12) {
                toggleRow("Session titles", isOn: $indexer.showTitleColumn)
                Divider()
                toggleRow("Project names", isOn: $indexer.showProjectColumn)
                Divider()
                toggleRow("Message counts", isOn: $indexer.showMsgsColumn)
                Divider()
                toggleRow("Modified timestamps", isOn: $indexer.showModifiedColumn)
            }
        }
    }

    private var codexCLITab: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text("Codex CLI")
                .font(.title2)
                .fontWeight(.semibold)

            sectionHeader("Sessions Directory")
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    TextField("Custom path (optional)", text: $codexPath)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 360)
                        .onChange(of: codexPath) { _, _ in validateCodexPath() }

                    Button(action: pickCodexFolder) {
                        Label("Choose…", systemImage: "folder")
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(.bordered)
                }

                if !codexPathValid {
                    Label("Path must point to an existing folder", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Text("Default: $CODEX_HOME/sessions or ~/.codex/sessions")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Actions

    private func loadCurrentSettings() {
        codexPath = indexer.sessionsRootOverride
        validateCodexPath()
        appearance = indexer.appAppearance
        modifiedDisplay = indexer.modifiedDisplay
    }

    private func validateCodexPath() {
        guard !codexPath.isEmpty else {
            codexPathValid = true
            return
        }
        var isDir: ObjCBool = false
        codexPathValid = FileManager.default.fileExists(atPath: codexPath, isDirectory: &isDir) && isDir.boolValue
    }

    private func pickCodexFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.begin { response in
            if response == .OK, let url = panel.url {
                codexPath = url.path
                validateCodexPath()
            }
        }
    }

    private func resetToDefaults() {
        codexPath = ""
        indexer.sessionsRootOverride = ""
        validateCodexPath()

        appearance = .system
        indexer.setAppearance(.system)

        modifiedDisplay = .relative
        indexer.setModifiedDisplay(.relative)

        indexer.showTitleColumn = true
        indexer.showProjectColumn = true
        indexer.showMsgsColumn = true
        indexer.showModifiedColumn = true
    }

    private func applySettings() {
        indexer.sessionsRootOverride = codexPath
        indexer.setAppearance(appearance)
        indexer.setModifiedDisplay(modifiedDisplay)
        indexer.refresh()
    }

    // MARK: Helpers

    private func toggleRow(_ label: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 16) {
            Text(label)
                .frame(width: labelColumnWidth, alignment: .leading)
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .accessibilityLabel(Text(label))
        }
    }

    private func labeledRow<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(label)
                .frame(width: labelColumnWidth, alignment: .leading)
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            Divider()
        }
    }
}

// MARK: - Tabs

private enum PreferencesTab: String, CaseIterable, Identifiable {
    case general
    case codexCLI

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return "General"
        case .codexCLI: return "Codex CLI"
        }
    }

    var iconName: String {
        switch self {
        case .general: return "gearshape"
        case .codexCLI: return "terminal"
        }
    }
}

private extension PreferencesView {
    var visibleTabs: [PreferencesTab] { [.general, .codexCLI] }
}

// MARK: - Supporting Views

// Old PreferenceCard removed in favor of flat, sectioned layout.
