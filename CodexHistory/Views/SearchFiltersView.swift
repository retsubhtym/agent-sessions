import SwiftUI

struct SearchFiltersView: View {
    @EnvironmentObject var indexer: SessionIndexer
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Button(action: {
                    // Focus the field and run an immediate recompute
                    isSearchFocused = true
                    indexer.recomputeNow()
                }) { Image(systemName: "magnifyingglass") }
                .buttonStyle(.borderless)
                TextField("Search", text: $indexer.query)
                    .textFieldStyle(.plain)
                    .frame(minWidth: 160)
                    .focused($isSearchFocused)
                    .onSubmit { indexer.recomputeNow() }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.25)))
            .onReceive(indexer.$requestFocusSearch) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isSearchFocused = true
                }
            }
            Spacer(minLength: 0)
        }
    }
}
