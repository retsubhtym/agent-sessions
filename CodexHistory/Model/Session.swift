import Foundation

public struct Session: Identifiable, Equatable, Codable {
    public let id: String
    public let startTime: Date?
    public let endTime: Date?
    public let model: String?
    public let filePath: String
    public let eventCount: Int
    public let events: [SessionEvent]

    public var shortID: String { String(id.prefix(6)) }
    public var firstUserPreview: String? {
        events.first(where: { $0.kind == .user })?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum SessionDateSection: Hashable, Identifiable {
    var id: Self { self }
    case today
    case yesterday
    case day(String)
    case older

    var title: String {
        switch self {
        case .today: return "Today"
        case .yesterday: return "Yesterday"
        case .day(let s): return s
        case .older: return "Older"
        }
    }
}

struct Filters: Equatable {
    var query: String = ""
    var dateFrom: Date?
    var dateTo: Date?
    var model: String?
    var kinds: Set<SessionEventKind> = Set(SessionEventKind.allCases)
}

enum FilterEngine {
    static func sessionMatches(_ session: Session, filters: Filters) -> Bool {
        // Date range: compare session startTime (if present)
        if let from = filters.dateFrom, let start = session.startTime, start < from { return false }
        if let to = filters.dateTo, let start = session.startTime, start > to { return false }

        if let m = filters.model, !m.isEmpty, session.model != m { return false }

        // Kinds: session must have any event in selected kinds
        if !session.events.contains(where: { filters.kinds.contains($0.kind) }) { return false }

        let q = filters.query.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return true }
        let lower = q.lowercased()
        // Full-text across event text/tool fields
        for e in session.events {
            if let t = e.text?.lowercased(), t.contains(lower) { return true }
            if let ti = e.toolInput?.lowercased(), ti.contains(lower) { return true }
            if let to = e.toolOutput?.lowercased(), to.contains(lower) { return true }
            if e.rawJSON.lowercased().contains(lower) { return true }
        }
        return false
    }

    static func filterSessions(_ sessions: [Session], filters: Filters) -> [Session] {
        sessions.filter { sessionMatches($0, filters: filters) }
            .sorted { ($0.startTime ?? .distantPast) > ($1.startTime ?? .distantPast) }
    }
}

extension Array where Element == Session {
    func groupedBySection(now: Date = Date(), calendar: Calendar = .current) -> [(SessionDateSection, [Session])] {
        let cal = calendar
        let today = cal.startOfDay(for: now)
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        var buckets: [SessionDateSection: [Session]] = [:]
        for s in self {
            guard let start = s.startTime else {
                buckets[.older, default: []].append(s)
                continue
            }
            if cal.isDate(start, inSameDayAs: today) {
                buckets[.today, default: []].append(s)
            } else if cal.isDate(start, inSameDayAs: yesterday) {
                buckets[.yesterday, default: []].append(s)
            } else {
                let dayStr = ISO8601DateFormatter.cachedDayString(from: start)
                buckets[.day(dayStr), default: []].append(s)
            }
        }
        // Section order
        var result: [(SessionDateSection, [Session])] = []
        if let v = buckets[.today] { result.append((.today, v)) }
        if let v = buckets[.yesterday] { result.append((.yesterday, v)) }
        // Sort day sections descending
        let daySections = buckets.keys.compactMap { sec -> (String, [Session])? in
            if case let .day(d) = sec { return (d, buckets[sec] ?? []) }
            return nil
        }.sorted { $0.0 > $1.0 }
        for (d, list) in daySections { result.append((.day(d), list)) }
        if let v = buckets[.older] { result.append((.older, v)) }
        return result
    }
}

extension ISO8601DateFormatter {
    static let day: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withYear, .withMonth, .withDay]
        return f
    }()
    static func cachedDayString(from date: Date) -> String {
        return day.string(from: date)
    }
}
