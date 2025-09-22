import XCTest
@testable import AgentSessions

final class SessionTitleTests: XCTestCase {
    private func event(id: String, kind: SessionEventKind, text: String? = nil, tool: String? = nil) -> SessionEvent {
        SessionEvent(
            id: id,
            timestamp: nil,
            kind: kind,
            role: nil,
            text: text,
            toolName: tool,
            toolInput: nil,
            toolOutput: nil,
            messageID: nil,
            parentID: nil,
            isDelta: false,
            rawJSON: "{}"
        )
    }

    func testTitlePrefersUserLine() {
        let s = Session(
            id: "s-title-1",
            startTime: Date(),
            endTime: Date(),
            model: nil,
            filePath: "/tmp/a.jsonl",
            eventCount: 2,
            events: [
                event(id: "e1", kind: .user, text: "   Find   files  \n  now  "),
                event(id: "e2", kind: .assistant, text: "okay")
            ]
        )
        XCTAssertEqual(s.title, "Find files now")
    }

    func testTitleFallsBackToAssistant() {
        let s = Session(
            id: "s-title-2",
            startTime: Date(),
            endTime: Date(),
            model: nil,
            filePath: "/tmp/b.jsonl",
            eventCount: 2,
            events: [
                event(id: "e1", kind: .user, text: "    \n  \t  "),
                event(id: "e2", kind: .assistant, text: "Hello there")
            ]
        )
        XCTAssertEqual(s.title, "Hello there")
    }

    func testTitleNoPromptWhenEmpty() {
        let s = Session(
            id: "s-title-3",
            startTime: Date(),
            endTime: Date(),
            model: nil,
            filePath: "/tmp/c.jsonl",
            eventCount: 1,
            events: [
                event(id: "e1", kind: .meta, text: nil)
            ]
        )
        XCTAssertEqual(s.title, "No prompt")
    }
}
