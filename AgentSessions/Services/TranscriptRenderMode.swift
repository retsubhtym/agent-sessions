import Foundation

public enum TranscriptRenderMode: String, CaseIterable, Identifiable, Codable {
    case normal
    case terminal
    public var id: String { rawValue }
}
