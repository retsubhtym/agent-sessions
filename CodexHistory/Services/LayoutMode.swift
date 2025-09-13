import Foundation

enum LayoutMode: String, CaseIterable, Identifiable {
    case vertical   // sidebar + detail (current)
    case horizontal // top/bottom split
    var id: String { rawValue }
}

