import SwiftUI

struct SessionsListView: View {
    @EnvironmentObject var indexer: SessionIndexer
    @Binding var selection: String?
    @State private var sortAscending: Bool = false
    enum SortKey { case modified, msgs, title }
    @State private var sortKey: SortKey = .modified

    private var sortedSessions: [Session] {
        indexer.sessions.sorted { a, b in
            switch sortKey {
            case .modified:
                let la = a.endTime ?? a.startTime ?? .distantPast
                let lb = b.endTime ?? b.startTime ?? .distantPast
                return sortAscending ? (la < lb) : (la > lb)
            case .msgs:
                let ca = a.nonMetaCount
                let cb = b.nonMetaCount
                return sortAscending ? (ca < cb) : (ca > cb)
            case .title:
                let ta = a.title.lowercased()
                let tb = b.title.lowercased()
                return sortAscending ? (ta < tb) : (ta > tb)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()
            List(selection: $selection) {
                ForEach(sortedSessions, id: \.id) { session in
                    SessionRow(session: session)
                        .tag(session.id as String?)
                        .contextMenu {
                            Button("Reveal in Finder") { reveal(session) }
                            Button("Copy Session ID") { copy(session.id) }
                        }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Sessions")
    }

    private var headerBar: some View {
        HStack(spacing: 10) {
            Text("ID")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)

            Button(action: {
                if sortKey == .modified { sortAscending.toggle() } else { sortKey = .modified; sortAscending = false }
            }) {
                HStack(spacing: 4) {
                    Text("Modified")
                    if sortKey == .modified {
                        Image(systemName: sortAscending ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                            .font(.caption2)
                    }
                }
            }
            .buttonStyle(.plain)
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(.secondary)
            .frame(width: 90, alignment: .leading)
            .help("Sort by Modified (toggle ascending/descending)")

            Button(action: {
                if sortKey == .msgs { sortAscending.toggle() } else { sortKey = .msgs; sortAscending = false }
            }) {
                HStack(spacing: 4) {
                    Text("Msgs")
                    if sortKey == .msgs {
                        Image(systemName: sortAscending ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                            .font(.caption2)
                    }
                }
            }
            .buttonStyle(.plain)
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(.secondary)
            .frame(width: 40, alignment: .trailing)
            .help("Sort by Msgs (toggle ascending/descending)")

            Button(action: {
                if sortKey == .title { sortAscending.toggle() } else { sortKey = .title; sortAscending = false }
            }) {
                HStack(spacing: 4) {
                    Text("Title")
                    if sortKey == .title {
                        Image(systemName: sortAscending ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill").font(.caption2)
                    }
                }
            }
            .buttonStyle(.plain)
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(.secondary)
            .frame(width: 220, alignment: .leading)
            .help("Sort by Title (toggle ascending/descending)")

            Text("—")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)

            Text("Summary")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
            Text("Model")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private func reveal(_ session: Session) {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: session.filePath)])
    }
    private func copy(_ str: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(str, forType: .string)
    }
}

private struct SessionRow: View {
    let session: Session

    var body: some View {
        HStack(spacing: 10) {
            Text(session.shortID)
                .font(.system(.body, design: .monospaced)).bold()
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)

            Text(session.modifiedRelative)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 90, alignment: .leading)
                .help(absoluteTime(session.endTime ?? session.startTime))

            Text(String(format: "%3d", session.nonMetaCount))
                .font(.system(.body, design: .monospaced))
                .frame(width: 40, alignment: .trailing)

            Text(session.title)
                .lineLimit(1)
                .truncationMode(.tail)
                .font(.system(.body, design: .default))
                .frame(width: 220, alignment: .leading)

            Text("—")
                .foregroundStyle(.secondary)

            Text(session.firstUserPreview ?? "")
                .lineLimit(1)
                .foregroundStyle(.primary)

            Spacer()
            if let model = session.model {
                Text(model)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func absoluteTime(_ date: Date?) -> String {
        guard let date else { return "" }
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .medium
        return f.string(from: date)
    }
}
