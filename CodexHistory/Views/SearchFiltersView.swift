import SwiftUI

struct SearchFiltersView: View {
    @EnvironmentObject var indexer: SessionIndexer
    @FocusState private var isSearchFocused: Bool

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
            Spacer(minLength: 0)
        }
    }
}
