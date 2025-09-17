import SwiftUI

struct SessionsListView: View {
    @EnvironmentObject var indexer: SessionIndexer
    @Binding var selection: String?
    // Table selection uses Set; keep a single-selection bridge
    @State private var tableSelection: Set<String> = []
    // Table sort order uses comparators
    @State private var sortOrder: [KeyPathComparator<Session>] = []

    private var rows: [Session] { indexer.sessions.sorted(using: sortOrder) }

    var body: some View {
        Table(rows, selection: $tableSelection, sortOrder: $sortOrder) {
            // Session (first column)
            TableColumn("Session", value: \Session.title) { s in
                Text(s.codexDisplayTitle)
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .width(min: indexer.showTitleColumn ? 160 : 0, ideal: indexer.showTitleColumn ? 320 : 0, max: indexer.showTitleColumn ? 2000 : 0)

            // Date (renamed from Modified)
            TableColumn("Date", value: \Session.modifiedAt) { s in
                let display = indexer.modifiedDisplay
                let primary = (display == .relative) ? s.modifiedRelative : absoluteTime(s.modifiedAt)
                let helpText = (display == .relative) ? absoluteTime(s.modifiedAt) : s.modifiedRelative
                Text(primary)
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .help(helpText)
            }
            .width(min: indexer.showModifiedColumn ? 120 : 0, ideal: indexer.showModifiedColumn ? 120 : 0, max: indexer.showModifiedColumn ? 140 : 0)

            // Project
            TableColumn("Project", value: \Session.repoDisplay) { s in
                Text(s.repoDisplay)
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .help(projectTooltip(for: s))
                    .onTapGesture { if let name = s.repoName { indexer.projectFilter = name; indexer.recomputeNow() } }
            }
            .width(min: indexer.showProjectColumn ? 120 : 0, ideal: indexer.showProjectColumn ? 160 : 0, max: indexer.showProjectColumn ? 240 : 0)

            // Msgs
            TableColumn("Msgs", value: \Session.nonMetaCount) { s in
                Text(String(format: "%3d", s.nonMetaCount))
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
            }
            .width(min: indexer.showMsgsColumn ? 64 : 0, ideal: indexer.showMsgsColumn ? 64 : 0, max: indexer.showMsgsColumn ? 80 : 0)

            // ID (last column; hide via zero width)
            TableColumn("ID", value: \Session.shortID) { s in
                Text(s.shortID)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .width(min: indexer.showIDColumn ? 64 : 0, ideal: indexer.showIDColumn ? 64 : 0, max: indexer.showIDColumn ? 64 : 0)
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
        .environment(\.defaultMinListRowHeight, 22)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .navigationTitle("Sessions")
        // No Codex matching mode for now; always show Codex-style titles, full list
        .onChange(of: sortOrder) { _, newValue in
            if let first = newValue.first {
                // Map to view model descriptor
                let key: SessionIndexer.SessionSortDescriptor.Key
                if first.keyPath == \Session.modifiedAt { key = .modified }
                else if first.keyPath == \Session.nonMetaCount { key = .msgs }
                else if first.keyPath == \Session.repoDisplay { key = .repo }
                else { key = .title }
                indexer.sortDescriptor = .init(key: key, ascending: first.order == .forward)
            }
        }
        .onChange(of: tableSelection) { _, newSel in
            // Bridge to single selection binding
            selection = newSel.first
        }
        .onAppear {
            // Seed initial selection
            if let sel = selection { tableSelection = [sel] }
            if sortOrder.isEmpty {
                sortOrder = [ KeyPathComparator(\Session.modifiedAt, order: .reverse) ]
            }
        }
    }

    private func reveal(_ session: Session) {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: session.filePath)])
    }
    private func copy(_ str: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(str, forType: .string)
    }
}

// (Column builder helpers removed to maintain compatibility with older macOS toolchains.)

// Helper for tooltip formatting
private func absoluteTime(_ date: Date?) -> String {
    guard let date else { return "" }
    let f = DateFormatter()
    // Follow system locale and 12/24‑hour setting; avoid words like "at"
    f.locale = .current
    f.dateStyle = .short
    f.timeStyle = .short
    f.doesRelativeDateFormatting = false
    return f.string(from: date)
}

private func projectTooltip(for s: Session) -> String {
    var parts: [String] = []
    if let path = s.cwd { parts.append(path) }
    var badges: [String] = []
    if s.isWorktree { badges.append("worktree") }
    if s.isSubmodule { badges.append("submodule") }
    if !badges.isEmpty { parts.append("[" + badges.joined(separator: ", ") + "]") }
    return parts.joined(separator: " ")
}
