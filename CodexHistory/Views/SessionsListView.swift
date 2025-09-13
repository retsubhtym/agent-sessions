import SwiftUI

struct SessionsListView: View {
    @EnvironmentObject var indexer: SessionIndexer
    @Binding var selection: String?
    // Table selection uses Set; keep a single-selection bridge
    @State private var tableSelection: Set<String> = []
    // Table sort order uses comparators
    @State private var sortOrder: [KeyPathComparator<Session>] = [ .init(\Session.modifiedAt, order: .reverse) ]

    private var rows: [Session] {
        indexer.sessions.sorted(using: sortOrder)
    }

    var body: some View {
        Table(rows, selection: $tableSelection, sortOrder: $sortOrder) {
            TableColumn("ID", value: \.shortID) { s in
                Text(s.shortID)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .width(min: 64, ideal: 64, max: 64)

            TableColumn("Modified", value: \.modifiedAt) { s in
                let display = indexer.modifiedDisplay
                let primary = (display == .relative) ? s.modifiedRelative : absoluteTime(s.modifiedAt)
                let helpText = (display == .relative) ? absoluteTime(s.modifiedAt) : s.modifiedRelative
                Text(primary)
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .help(helpText)
            }
            .width(min: 120, ideal: 120, max: 140)

            TableColumn("Msgs", value: \.nonMetaCount) { s in
                Text(String(format: "%3d", s.nonMetaCount))
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
            }
            .width(min: 64, ideal: 64, max: 80)

            TableColumn("Title", value: \.title) { s in
                Text(s.title)
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .width(min: 160, ideal: 320)
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
        .environment(\.defaultMinListRowHeight, 22)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .navigationTitle("Sessions")
        .onChange(of: sortOrder) { _, newValue in
            if let first = newValue.first {
                // Map to view model descriptor
                let key: SessionIndexer.SessionSortDescriptor.Key
                if first.keyPath == \Session.modifiedAt { key = .modified }
                else if first.keyPath == \Session.nonMetaCount { key = .msgs }
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
