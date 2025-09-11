import Foundation
import Combine
import CryptoKit
import SwiftUI

final class SessionIndexer: ObservableObject {
    // Source of truth
    @Published private(set) var allSessions: [Session] = []
    // Exposed to UI after filters
    @Published private(set) var sessions: [Session] = []

    @Published var isIndexing: Bool = false
    @Published var progressText: String = ""
    @Published var filesProcessed: Int = 0
    @Published var totalFiles: Int = 0

    // Filters
    @Published var query: String = ""
    @Published var dateFrom: Date? = nil
    @Published var dateTo: Date? = nil
    @Published var selectedModel: String? = nil
    @Published var selectedKinds: Set<SessionEventKind> = Set(SessionEventKind.allCases)

    // UI focus coordination
    @Published var requestFocusSearch: Bool = false

    // Preferences
    @AppStorage("SessionsRootOverride") var sessionsRootOverride: String = ""

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Debounced computed sessions
        let inputs = Publishers.CombineLatest4(
            $query
                .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
                .removeDuplicates(),
            $dateFrom.removeDuplicates(by: Self.dateEq),
            $dateTo.removeDuplicates(by: Self.dateEq),
            $selectedModel.removeDuplicates()
        )
        Publishers.CombineLatest3(
            inputs,
            $selectedKinds.removeDuplicates(),
            $allSessions
        )
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .map { input, kinds, all -> [Session] in
                let (q, from, to, model) = input
                let filters = Filters(query: q, dateFrom: from, dateTo: to, model: model, kinds: kinds)
                return FilterEngine.filterSessions(all, filters: filters)
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$sessions)
    }

    var modelsSeen: [String] {
        Array(Set(allSessions.compactMap { $0.model })).sorted()
    }

    var canAccessRootDirectory: Bool {
        let root = sessionsRoot()
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: root.path, isDirectory: &isDir) && isDir.boolValue
    }

    func sessionsRoot() -> URL {
        if !sessionsRootOverride.isEmpty { return URL(fileURLWithPath: sessionsRootOverride) }
        if let env = ProcessInfo.processInfo.environment["CODEX_HOME"], !env.isEmpty {
            return URL(fileURLWithPath: env).appendingPathComponent("sessions")
        }
        return URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".codex/sessions")
    }

    func refresh() {
        let root = sessionsRoot()
        isIndexing = true
        progressText = "Scanning…"
        filesProcessed = 0
        totalFiles = 0

        let fm = FileManager.default
        DispatchQueue.global(qos: .userInitiated).async {
            var found: [URL] = []
            if let en = fm.enumerator(at: root, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) {
                for case let url as URL in en {
                    if url.lastPathComponent.hasPrefix("rollout-") && url.pathExtension.lowercased() == "jsonl" {
                        found.append(url)
                    }
                }
            }
            let sortedFiles = found.sorted { ($0.lastPathComponent) > ($1.lastPathComponent) }
            DispatchQueue.main.async {
                self.totalFiles = sortedFiles.count
            }

            var sessions: [Session] = []
            sessions.reserveCapacity(sortedFiles.count)

            for (i, url) in sortedFiles.enumerated() {
                if let session = self.parseFile(at: url) {
                    sessions.append(session)
                }
                DispatchQueue.main.async {
                    self.filesProcessed = i + 1
                    self.progressText = "Indexed \(i + 1)/\(sortedFiles.count)"
                    self.allSessions = sessions.sorted { ($0.startTime ?? .distantPast) > ($1.startTime ?? .distantPast) }
                }
            }

            DispatchQueue.main.async {
                self.isIndexing = false
            }
        }
    }

    // MARK: - Parsing

    func parseFile(at url: URL) -> Session? {
        let reader = JSONLReader(url: url)
        var events: [SessionEvent] = []
        var modelSeen: String? = nil
        var idx = 0
        do {
            try reader.forEachLine { line in
                idx += 1
                let (event, maybeModel) = Self.parseLine(line, eventID: self.eventID(for: url, index: idx))
                if let m = maybeModel, modelSeen == nil { modelSeen = m }
                events.append(event)
            }
        } catch {
            // If file can't be read, emit a single error meta event
            let event = SessionEvent(id: eventID(for: url, index: 0), timestamp: Date(), kind: .error, role: "system", text: "Failed to read: \(error.localizedDescription)", toolName: nil, toolInput: nil, toolOutput: nil, rawJSON: "{}")
            events.append(event)
        }

        let times = events.compactMap { $0.timestamp }
        let start = times.min()
        let end = times.max()
        let id = Self.hash(path: url.path)
        let session = Session(id: id, startTime: start, endTime: end, model: modelSeen, filePath: url.path, eventCount: events.count, events: events)
        return session
    }

    static func parseLine(_ line: String, eventID: String) -> (SessionEvent, String?) {
        var timestamp: Date? = nil
        var role: String? = nil
        var type: String? = nil
        var text: String? = nil
        var toolName: String? = nil
        var toolInput: String? = nil
        var toolOutput: String? = nil
        var model: String? = nil

        if let data = line.data(using: .utf8),
           let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {

            // timestamp could be number or string
            if let ts = obj["timestamp"] ?? obj["time"] ?? obj["ts"] {
                timestamp = Self.decodeDate(from: ts)
            }

            // role / type
            if let r = obj["role"] as? String { role = r }
            if let t = obj["type"] as? String { type = t }
            if type == nil, let e = obj["event"] as? String { type = e }

            // model
            if let m = obj["model"] as? String { model = m }

            // text content variants
            if let content = obj["content"] as? String { text = content }
            if text == nil, let txt = obj["text"] as? String { text = txt }
            if text == nil, let msg = obj["message"] as? String { text = msg }

            // tool fields
            if let t = obj["tool"] as? String { toolName = t }
            if toolName == nil, let name = obj["name"] as? String { toolName = name }
            if toolName == nil, let fn = (obj["function"] as? [String: Any])?["name"] as? String { toolName = fn }
            if let input = obj["input"] as? String { toolInput = input }
            if toolInput == nil, let args = obj["arguments"] as? String { toolInput = args }
            if let out = obj["output"] as? String { toolOutput = out }
            if toolOutput == nil, let res = obj["result"] as? String { toolOutput = res }
        }

        let kind = SessionEventKind.from(role: role, type: type)
        let event = SessionEvent(id: eventID, timestamp: timestamp, kind: kind, role: role, text: text, toolName: toolName, toolInput: toolInput, toolOutput: toolOutput, rawJSON: line)
        return (event, model)
    }

    private func eventID(for url: URL, index: Int) -> String {
        let base = Self.hash(path: url.path)
        return base + String(format: "-%04d", index)
    }

    private static func hash(path: String) -> String {
        let d = SHA256.hash(data: Data(path.utf8))
        return d.compactMap { String(format: "%02x", $0) }.joined()
    }

    private static func decodeDate(from any: Any) -> Date? {
        if let d = any as? Double { return Date(timeIntervalSince1970: d) }
        if let i = any as? Int { return Date(timeIntervalSince1970: TimeInterval(i)) }
        if let s = any as? String {
            // Try ISO8601 first
            let iso = ISO8601DateFormatter()
            if let d = iso.date(from: s) { return d }
            // Try RFC3339
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            if let d = f.date(from: s) { return d }
        }
        return nil
    }

    private static func dateEq(_ lhs: Date?, _ rhs: Date?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil): return true
        case let (l?, r?): return abs(l.timeIntervalSince1970 - r.timeIntervalSince1970) < 0.5
        default: return false
        }
    }
}
