import SwiftUI

struct SessionsListView: View {
    @EnvironmentObject var indexer: SessionIndexer
    @Binding var selection: String?

    var body: some View {
        List(selection: $selection) {
            ForEach(indexer.sessions.groupedBySection(), id: \.0) { section, sessions in
                Section(section.title) {
                    ForEach(sessions, id: \.id) { session in
                        SessionRow(session: session)
                            .tag(session.id as String?)
                            .contextMenu {
                                Button("Reveal in Finder") { reveal(session) }
                                Button("Copy Session ID") { copy(session.id) }
                            }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Sessions")
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
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(session.shortID)
                .font(.system(.body, design: .monospaced)).bold()
                .foregroundStyle(.secondary)
                .frame(width: 54, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(timeString(session.startTime))
                        .foregroundStyle(.secondary)
                    if let model = session.model {
                        Text(model)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.15), in: Capsule())
                    }
                    Spacer()
                    Text("\(session.eventCount)")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(Color.accentColor.opacity(0.15), in: Capsule())
                        .foregroundStyle(.tint)
                }
                Text(session.firstUserPreview ?? "")
                    .lineLimit(1)
                    .foregroundStyle(.primary)
            }
        }
        .padding(.vertical, 4)
    }

    private func timeString(_ date: Date?) -> String {
        guard let date else { return "—" }
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f.string(from: date)
    }
}
