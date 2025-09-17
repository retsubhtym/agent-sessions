import SwiftUI

struct EventInspectorView: View {
    @EnvironmentObject var indexer: SessionIndexer
    let sessionID: String?
    let eventID: String?
    @State private var tab: Tab = .pretty

    enum Tab: String, CaseIterable { case pretty = "Pretty", raw = "Raw JSON" }

    var body: some View {
        VStack(spacing: 0) {
            Picker("View", selection: $tab) {
                ForEach(Tab.allCases, id: \.self) { t in
                    Text(t.rawValue).tag(t)
                }
            }
            .pickerStyle(.segmented)
            .padding(8)

            Divider()

            ScrollView {
                if let e = currentEvent {
                    switch tab {
                    case .pretty:
                        PrettyView(event: e)
                    case .raw:
                        RawView(json: e.rawJSON)
                    }
                } else {
                    ContentUnavailableView("Select an event", systemImage: "doc")
                }
            }
            .background(Color(NSColor.textBackgroundColor))

            HStack {
                Button("Copy") { copyPretty() }
                Button("Copy Raw") { copyRaw() }
                Spacer()
            }
            .padding(8)
        }
        .navigationTitle("Inspector")
    }

    private var currentEvent: SessionEvent? {
        guard let sid = sessionID, let eid = eventID else { return nil }
        return indexer.sessions.first(where: { $0.id == sid })?.events.first(where: { $0.id == eid })
    }

    private func copyPretty() {
        guard let e = currentEvent else { return }
        let content = e.text ?? e.toolOutput ?? e.toolInput ?? ""
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
    }
    private func copyRaw() {
        guard let e = currentEvent else { return }
        let pretty = PrettyJSON.prettyPrinted(e.rawJSON)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(pretty, forType: .string)
    }
}
private struct PrettyView: View {
    let event: SessionEvent
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let text = event.text, !text.isEmpty {
                Text(text).font(.system(.body, design: .monospaced))
            }
            if let input = event.toolInput, !input.isEmpty {
                Text("Input:")
                    .font(.caption).foregroundStyle(.secondary)
                Text(input).font(.system(.body, design: .monospaced))
            }
            if let output = event.toolOutput, !output.isEmpty {
                Text("Output:")
                    .font(.caption).foregroundStyle(.secondary)
                Text(output).font(.system(.body, design: .monospaced))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

private struct RawView: View {
    let json: String
    var body: some View {
        Text(PrettyJSON.prettyPrinted(json))
            .font(.system(.body, design: .monospaced))
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(12)
    }
}
