import SwiftUI

enum TranscriptTheme: String, CaseIterable, Identifiable {
    case codexDark
    case monochrome
    case ansiExport
    var id: String { rawValue }
}

struct TranscriptColors {
    let user: Color
    let assistant: Color
    let tool: Color
    let output: Color
    let error: Color
    let dim: Color
}

extension TranscriptTheme {
    var colors: TranscriptColors {
        switch self {
        case .codexDark:
            return TranscriptColors(user: .cyan, assistant: .green, tool: .purple, output: .primary, error: .red, dim: .secondary)
        case .monochrome:
            return TranscriptColors(user: .primary, assistant: .primary, tool: .primary, output: .primary, error: .primary, dim: .secondary)
        case .ansiExport:
            // Not used for UI; see builder for ANSI codes
            return TranscriptColors(user: .cyan, assistant: .green, tool: .purple, output: .primary, error: .red, dim: .secondary)
        }
    }
}

enum TranscriptFilters: Equatable {
    case current(showTimestamps: Bool, showMeta: Bool)
}
