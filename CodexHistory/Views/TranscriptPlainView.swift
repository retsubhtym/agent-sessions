import SwiftUI
import AppKit

struct TranscriptPlainView: View {
    @EnvironmentObject var indexer: SessionIndexer
    let sessionID: String?

    // Plain transcript buffer
    @State private var transcript: String = ""

    // Find
    @State private var findText: String = ""
    @State private var findMatches: [Range<String.Index>] = []
    @State private var currentMatchIndex: Int = 0
    @FocusState private var findFocused: Bool
    @State private var highlightRanges: [NSRange] = []
    @State private var commandRanges: [NSRange] = []
    @State private var userRanges: [NSRange] = []
    @AppStorage("ColorizeCommands") private var colorizeCommands: Bool = true

    // Toggles (view-scoped)
    @State private var showTimestamps: Bool = false
    @State private var showMeta: Bool = false
    @AppStorage("TranscriptFontSize") private var transcriptFontSize: Double = 13
    @AppStorage("TranscriptRenderMode") private var renderModeRaw: String = TranscriptRenderMode.normal.rawValue

    // Raw sheet
    @State private var showRawSheet: Bool = false
    // Selection for auto-scroll to find matches
    @State private var selectedNSRange: NSRange? = nil

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            PlainTextScrollView(text: transcript, selection: selectedNSRange, fontSize: CGFloat(transcriptFontSize), highlights: highlightRanges, currentIndex: currentMatchIndex, commandRanges: (renderModeRaw == TranscriptRenderMode.terminal.rawValue && colorizeCommands) ? commandRanges : [], userRanges: colorizeCommands ? userRanges : [])
        }
        .onAppear { syncPrefs(); rebuild() }
        .onChange(of: sessionID) { _, _ in rebuild() }
        .onChange(of: indexer.sessions) { _, _ in rebuild() }
        .onChange(of: indexer.query) { _, _ in rebuild() }
        .onChange(of: renderModeRaw) { _, _ in rebuild() }
        .onReceive(indexer.$requestCopyPlain) { _ in copyAll() }
        .onReceive(indexer.$requestTranscriptFindFocus) { _ in findFocused = true }
        .sheet(isPresented: $showRawSheet) { WholeSessionRawPrettySheet(session: currentSession) }
        .onChange(of: indexer.requestOpenRawSheet) { _, newVal in
            if newVal {
                showRawSheet = true
                indexer.requestOpenRawSheet = false
            }
        }
    }

    private var currentSession: Session? {
        guard let sid = sessionID else { return nil }
        if let s = indexer.sessions.first(where: { $0.id == sid }) { return s }
        return indexer.allSessions.first(where: { $0.id == sid })
    }

    private var toolbar: some View {
        HStack(spacing: 8) {
            // Find controls
            HStack(spacing: 6) {
                Button(action: { performFind(resetIndex: true) }) { Image(systemName: "magnifyingglass") }
                    .help("Find")
                TextField("Find", text: $findText)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 200)
                    .focused($findFocused)
                    .onSubmit { performFind(resetIndex: true) }
            }
            Button(action: { performFind(resetIndex: false, direction: -1) }) { Image(systemName: "chevron.up") }
                .help("Previous match")
                .disabled(findMatches.isEmpty)
            Button(action: { performFind(resetIndex: false, direction: 1) }) { Image(systemName: "chevron.down") }
                .help("Next match")
                .disabled(findMatches.isEmpty)
            if !findText.isEmpty {
                Text("\(findMatches.isEmpty ? 0 : currentMatchIndex + 1)/\(findMatches.count)")
                    .foregroundStyle(.secondary)
            }
            Divider().frame(height: 20)
            Toggle("Meta", isOn: $showMeta)
                .onChange(of: showMeta) { _, _ in rebuild() }
            Spacer()
            Picker("Mode", selection: $renderModeRaw) {
                Text("Normal").tag(TranscriptRenderMode.normal.rawValue)
                Text("Terminal").tag(TranscriptRenderMode.terminal.rawValue)
            }
            .pickerStyle(.segmented)
            .frame(width: 180)
            if renderModeRaw == TranscriptRenderMode.terminal.rawValue {
                Toggle("Colorize", isOn: $colorizeCommands).toggleStyle(.switch)
            }
            HStack(spacing: 6) {
                Button(action: { adjustFont(-1) }) {
                    Text("−").font(.system(size: 14, weight: .bold))
                }
                .accessibilityLabel("Make text smaller")
                .help("Smaller (Cmd-)")
                Button(action: { adjustFont(1) }) {
                    Text("+").font(.system(size: 14, weight: .bold))
                }
                .accessibilityLabel("Make text bigger")
                .help("Bigger (Cmd+=)")
            }
            Button("Copy") { copyAll() }
                .help("Copy entire transcript")
        }
        .padding(8)
    }

    private func syncPrefs() {
        // Defaults are off; nothing to sync
    }

    private func rebuild() {
        guard let s = currentSession else { transcript = ""; return }
        let filters: TranscriptFilters = .current(showTimestamps: showTimestamps, showMeta: showMeta)
        let mode = TranscriptRenderMode(rawValue: renderModeRaw) ?? .normal
        if mode == .terminal && colorizeCommands {
            let built = SessionTranscriptBuilder.buildTerminalPlainWithRanges(session: s, filters: filters)
            transcript = built.0
            commandRanges = built.1
            userRanges = built.2
        } else {
            transcript = SessionTranscriptBuilder.buildPlainTerminalTranscript(session: s, filters: filters, mode: mode)
            commandRanges = []
            // Build user ranges for normal mode if colorization enabled
            if colorizeCommands && mode == .normal {
                // Minimal pass to find user lines: they always start with optional timestamp then "> "
                userRanges = []
                let ns = transcript as NSString
                let lines = transcript.split(separator: "\n", omittingEmptySubsequences: false)
                var cursor = 0
                for line in lines {
                    let s = String(line)
                    // Very lightweight detection: check for "> " prefix after optional HH:MM:SS {space}
                    var lineStr = s
                    if lineStr.count >= 9, lineStr[lineStr.index(lineStr.startIndex, offsetBy: 2)] == ":" {
                        // naive skip timestamp like 12:34:56 
                        if let space = lineStr.firstIndex(of: " ") { lineStr = String(lineStr[lineStr.index(after: space)...]) }
                    }
                    if lineStr.hasPrefix("> ") {
                        let start = cursor + (ns.substring(with: NSRange(location: cursor, length: (s as NSString).length)) as NSString).range(of: "> ").location + 2
                        let len = (s as NSString).length - ((ns.substring(with: NSRange(location: cursor, length: (s as NSString).length)) as NSString).range(of: "> ").location + 2)
                        if len > 0 { userRanges.append(NSRange(location: start, length: len)) }
                    }
                    cursor += (s as NSString).length + 1
                }
            } else {
                userRanges = []
            }
        }
        // Reset find state
        performFind(resetIndex: true)
        selectedNSRange = nil
        updateSelectionToCurrentMatch()
    }

    private func performFind(resetIndex: Bool, direction: Int = 1) {
        let q = findText
        guard !q.isEmpty else {
            findMatches = []
            currentMatchIndex = 0
            highlightRanges = []
            return
        }
        let lowerText = transcript.lowercased()
        let lowerQ = q.lowercased()
        var matches: [Range<String.Index>] = []
        var searchStart = lowerText.startIndex
        while let r = lowerText.range(of: lowerQ, range: searchStart..<lowerText.endIndex) {
            let origStart = transcript.index(transcript.startIndex, offsetBy: lowerText.distance(from: lowerText.startIndex, to: r.lowerBound))
            let origEnd = transcript.index(origStart, offsetBy: lowerQ.count)
            matches.append(origStart..<origEnd)
            searchStart = r.upperBound
        }
        findMatches = matches
        // Build NSRanges for temporary highlight attributes
        var nsRanges: [NSRange] = []
        for r in matches {
            if let nsr = NSRange(r, in: transcript) as NSRange? { nsRanges.append(nsr) }
        }
        highlightRanges = nsRanges
        if resetIndex { currentMatchIndex = matches.isEmpty ? 0 : 0 }
        else if !matches.isEmpty {
            currentMatchIndex = (currentMatchIndex + direction + matches.count) % matches.count
        }
        // Note: We intentionally avoid styling/highlights per spec (plain text only)
        updateSelectionToCurrentMatch()
    }

    private func copyAll() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(transcript, forType: .string)
    }
}

// MARK: - NSViewRepresentable plain text, selectable, scrollable

private struct PlainTextScrollView: NSViewRepresentable {
    let text: String
    let selection: NSRange?
    let fontSize: CGFloat
    let highlights: [NSRange]
    let currentIndex: Int
    let commandRanges: [NSRange]
    let userRanges: [NSRange]

    class Coordinator { var lastWidth: CGFloat = 0 }
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = false
        scroll.autohidesScrollers = true

        let textView = NSTextView(frame: NSRect(origin: .zero, size: scroll.contentSize))
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.textContainer?.widthTracksTextView = true
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.minSize = NSSize(width: 0, height: scroll.contentSize.height)
        textView.autoresizingMask = [.width]
        textView.textContainer?.lineFragmentPadding = 0
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.containerSize = NSSize(width: scroll.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.backgroundColor = .clear
        textView.string = text
        applyHighlights(textView)

        scroll.documentView = textView
        if let sel = selection { textView.setSelectedRange(sel); textView.scrollRangeToVisible(sel) }
        return scroll
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let tv = nsView.documentView as? NSTextView {
            if tv.string != text { tv.string = text }
            if let font = tv.font, abs(font.pointSize - fontSize) > 0.5 {
                tv.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
            }
            let width = max(1, nsView.contentSize.width)
            tv.textContainer?.containerSize = NSSize(width: width, height: CGFloat.greatestFiniteMagnitude)
            tv.setFrameSize(NSSize(width: width, height: tv.frame.size.height))
            if let container = tv.textContainer { tv.layoutManager?.ensureLayout(for: container) }
            if let sel = selection {
                tv.setSelectedRange(sel)
                tv.scrollRangeToVisible(sel)
            }
            applyHighlights(tv)
        }
    }

    private func applyHighlights(_ tv: NSTextView) {
        guard let lm = tv.layoutManager else { return }
        let full = NSRange(location: 0, length: (tv.string as NSString).length)
        lm.removeTemporaryAttribute(.backgroundColor, forCharacterRange: full)
        lm.removeTemporaryAttribute(.foregroundColor, forCharacterRange: full)
        // Command colorization (foreground)
        if !commandRanges.isEmpty {
            let green = NSColor.systemGreen
            for r in commandRanges {
                if NSMaxRange(r) <= full.length {
                    lm.addTemporaryAttribute(.foregroundColor, value: green, forCharacterRange: r)
                }
            }
        }
        // User input colorization (blue)
        if !userRanges.isEmpty {
            let blue = NSColor.systemBlue
            for r in userRanges {
                if NSMaxRange(r) <= full.length {
                    lm.addTemporaryAttribute(.foregroundColor, value: blue, forCharacterRange: r)
                }
            }
        }
        // Find match background highlights
        guard !highlights.isEmpty else { return }
        // Colors that read well in both light and dark appearances
        let matchBG = NSColor.systemYellow.withAlphaComponent(0.35)
        let currentBG = NSColor.systemOrange.withAlphaComponent(0.55)
        for (i, r) in highlights.enumerated() {
            if NSMaxRange(r) <= full.length {
                let color = (i == currentIndex) ? currentBG : matchBG
                lm.addTemporaryAttribute(.backgroundColor, value: color, forCharacterRange: r)
            }
        }
    }
}

// MARK: - Find selection helper

private extension TranscriptPlainView {
    func updateSelectionToCurrentMatch() {
        guard !findMatches.isEmpty else { selectedNSRange = nil; return }
        let range = findMatches[min(currentMatchIndex, findMatches.count - 1)]
        if let nsRange = NSRange(range, in: transcript) as NSRange? { selectedNSRange = nsRange }
    }
    func adjustFont(_ delta: Double) {
        transcriptFontSize = max(9, min(30, transcriptFontSize + delta))
    }
}

private struct WholeSessionRawPrettySheet: View {
    let session: Session?
    @Environment(\.dismiss) private var dismiss
    @State private var tab: Int = 0
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Picker("", selection: $tab) {
                Text("Pretty").tag(0)
                Text("Raw JSON").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(8)
            Divider()
            ScrollView {
                if let s = session {
                    let raw = s.events.map { $0.rawJSON }.joined(separator: "\n")
                    let pretty = PrettyJSON.prettyPrinted("[" + s.events.map { $0.rawJSON }.joined(separator: ",") + "]")
                    if tab == 0 {
                        Text(pretty).font(.system(.body, design: .monospaced)).textSelection(.enabled).padding(12)
                    } else {
                        Text(raw).font(.system(.body, design: .monospaced)).textSelection(.enabled).padding(12)
                    }
                } else {
                    ContentUnavailableView("No session", systemImage: "doc")
                }
            }
            HStack { Spacer(); Button("Close") { dismiss() } }.padding(8)
        }
        .frame(width: 720, height: 520)
    }
}
