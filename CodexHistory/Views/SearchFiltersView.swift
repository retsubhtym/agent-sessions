import SwiftUI

struct SearchFiltersView: View {
    @EnvironmentObject var indexer: SessionIndexer
    @FocusState private var isSearchFocused: Bool
    @State private var enableFrom: Bool = false
    @State private var enableTo: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search", text: $indexer.query)
                    .textFieldStyle(.plain)
                    .frame(minWidth: 160)
                    .focused($isSearchFocused)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.25)))
            .onReceive(indexer.$requestFocusSearch) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isSearchFocused = true
                }
            }

            Divider().frame(height: 20)

            // Model picker
            Picker("Model", selection: Binding(
                get: { indexer.selectedModel ?? "" },
                set: { indexer.selectedModel = $0.isEmpty ? nil : $0 }
            )) {
                Text("All Models").tag("")
                ForEach(indexer.modelsSeen, id: \.self) { m in
                    Text(m).tag(m)
                }
            }
            .pickerStyle(.menu)

            // Date range
            Toggle(isOn: $enableFrom) { Text("From") }
                .toggleStyle(.switch)
                .onChange(of: enableFrom) { _, isOn in
                    if !isOn {
                        indexer.dateFrom = nil
                    } else if indexer.dateFrom == nil {
                        indexer.dateFrom = Calendar.current.date(byAdding: .day, value: -7, to: Date())
                    }
                }
            DatePicker(
                "",
                selection: Binding(
                    get: { indexer.dateFrom ?? Date() },
                    set: { indexer.dateFrom = $0 }
                ),
                displayedComponents: [.date, .hourAndMinute]
            )
                .disabled(!enableFrom)
                .labelsHidden()

            Toggle(isOn: $enableTo) { Text("To") }
                .toggleStyle(.switch)
                .onChange(of: enableTo) { _, isOn in
                    if !isOn {
                        indexer.dateTo = nil
                    } else if indexer.dateTo == nil {
                        indexer.dateTo = Date()
                    }
                }
            DatePicker(
                "",
                selection: Binding(
                    get: { indexer.dateTo ?? Date() },
                    set: { indexer.dateTo = $0 }
                ),
                displayedComponents: [.date, .hourAndMinute]
            )
                .disabled(!enableTo)
                .labelsHidden()

            // Kind toggles
            HStack(spacing: 6) {
                ForEach(SessionEventKind.allCases, id: \.self) { kind in
                    Toggle(kindLabel(kind), isOn: Binding(
                        get: { indexer.selectedKinds.contains(kind) },
                        set: { newVal in
                            if newVal { indexer.selectedKinds.insert(kind) } else { indexer.selectedKinds.remove(kind) }
                        }
                    ))
                    .toggleStyle(.button)
                }
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
}
