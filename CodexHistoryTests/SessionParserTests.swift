import XCTest
@testable import CodexHistory

final class SessionParserTests: XCTestCase {
    func fixtureURL(_ name: String) -> URL {
        let bundle = Bundle(for: type(of: self))
        return bundle.url(forResource: name, withExtension: "jsonl")!
    }

    func testJSONLStreamingAndDecoding() throws {
        let url = fixtureURL("session_simple")
        let reader = JSONLReader(url: url)
        let lines = try reader.readLines()
        XCTAssertEqual(lines.count, 2)
        let e1 = SessionIndexer.parseLine(lines[0], eventID: "e-1").0
        XCTAssertEqual(e1.kind, .user)
        XCTAssertEqual(e1.role, "user")
        XCTAssertEqual(e1.text, "What's the weather like in SF today?")
        XCTAssertNotNil(e1.timestamp)
        XCTAssertFalse(e1.rawJSON.isEmpty)
    }

    func testBuildsSessionMetadata() throws {
        let url = fixtureURL("session_toolcall")
        let indexer = SessionIndexer()
        let session = indexer.parseFile(at: url)
        XCTAssertNotNil(session)
        guard let s = session else { return }
        XCTAssertEqual(s.eventCount, 4)
        XCTAssertEqual(s.model, "gpt-4o-mini")
        XCTAssertNotNil(s.startTime)
        XCTAssertNotNil(s.endTime)
        XCTAssertLessThan((s.startTime ?? .distantPast), (s.endTime ?? .distantFuture))
    }

    func testSearchAndFilters() throws {
        // Build two sample sessions from fixtures
        let idx = SessionIndexer()
        let s1 = idx.parseFile(at: fixtureURL("session_simple"))!
        let s2 = idx.parseFile(at: fixtureURL("session_toolcall"))!
        let all = [s1, s2]
        // Query should match assistant text in s1
        var filters = Filters(query: "sunny", dateFrom: nil, dateTo: nil, model: nil, kinds: Set(SessionEventKind.allCases))
        var filtered = FilterEngine.filterSessions(all, filters: filters)
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.id, s1.id)

        // Filter by model
        filters = Filters(query: "", dateFrom: nil, dateTo: nil, model: "gpt-4o-mini", kinds: Set(SessionEventKind.allCases))
        filtered = FilterEngine.filterSessions(all, filters: filters)
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.id, s2.id)

        // Filter kinds (only tool_result)
        filters = Filters(query: "hola", dateFrom: nil, dateTo: nil, model: nil, kinds: [.tool_result])
        filtered = FilterEngine.filterSessions(all, filters: filters)
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.id, s2.id)
    }
}

