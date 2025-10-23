import SwiftUI
import AppKit

struct UsageMenuBarLabel: View {
    @EnvironmentObject var codexStatus: CodexUsageModel
    @EnvironmentObject var claudeStatus: ClaudeUsageModel
    @AppStorage("MenuBarScope") private var scopeRaw: String = MenuBarScope.both.rawValue
    @AppStorage("MenuBarStyle") private var styleRaw: String = MenuBarStyleKind.bars.rawValue
    @AppStorage("MenuBarSource") private var sourceRaw: String = MenuBarSource.codex.rawValue
    // Colorization is currently disabled (see TODO below)

    var body: some View {
        let scope = MenuBarScope(rawValue: scopeRaw) ?? .both
        let style = MenuBarStyleKind(rawValue: styleRaw) ?? .bars
        let source = MenuBarSource(rawValue: sourceRaw) ?? .codex
        let claudeEnabled = UserDefaults.standard.bool(forKey: "ShowClaudeUsageStrip")

        let codexMetrics = metrics(forFive: codexStatus.fiveHourPercent, week: codexStatus.weekPercent, scope: scope)
        let claudeMetrics = metrics(forFive: claudeStatus.sessionPercent, week: claudeStatus.weekAllModelsPercent, scope: scope)

        let showCodex = source == .codex || source == .both
        let showClaude = (source == .claude || source == .both) && claudeEnabled
        let showDivider = showCodex && showClaude

        return HStack(spacing: 8) {
            if showCodex {
                MenuBarSourceStack(prefix: "CX", metrics: codexMetrics, style: style, showPrefix: showDivider || source != .codex)
            }

            if showDivider {
                Divider()
                    .frame(height: 18)
                    .padding(.horizontal, -2)
            }

            if showClaude {
                MenuBarSourceStack(prefix: "CL", metrics: claudeMetrics, style: style, showPrefix: true)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .fixedSize(horizontal: true, vertical: true)
        .onAppear {
            codexStatus.setMenuVisible(true)
            claudeStatus.setMenuVisible(true)
        }
        .onDisappear {
            codexStatus.setMenuVisible(false)
            claudeStatus.setMenuVisible(false)
        }
    }

    private func metrics(forFive five: Int, week: Int, scope: MenuBarScope) -> [MenuBarMetric] {
        switch scope {
        case .fiveHour:
            return [MenuBarMetric(label: "5h", percent: clamp(five))]
        case .weekly:
            return [MenuBarMetric(label: "Wk", percent: clamp(week))]
        case .both:
            return [
                MenuBarMetric(label: "5h", percent: clamp(five)),
                MenuBarMetric(label: "Wk", percent: clamp(week))
            ]
        }
    }

    private func clamp(_ value: Int) -> Int {
        max(0, min(100, value))
    }

    // TODO(Colorize): MenuBarExtra renders labels as template content, dropping custom colors.
    // Proposal: implement a small NSStatusItem controller that sets a non-template attributedTitle
    // with per-metric colors (green 0–74%, yellow 75–89%, red 90–100%), while keeping the SwiftUI
    // menu content via NSHostingView embedded in an NSMenu. Then re-introduce a Preferences toggle.
}


private struct MenuBarMetric: Identifiable {
    let label: String
    let percent: Int

    var id: String { label }
}

private struct MenuBarSourceStack: View {
    let prefix: String
    let metrics: [MenuBarMetric]
    let style: MenuBarStyleKind
    let showPrefix: Bool

    var body: some View {
        HStack(alignment: .top, spacing: style == .bars ? 6 : 4) {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(metrics.enumerated()), id: \.offset) { index, metric in
                    line(for: metric, includePrefix: includePrefix(at: index))
                }
            }

            if style == .bars {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(metrics) { metric in
                        MenuBarMeterBar(percent: metric.percent)
                    }
                }
            }
        }
    }

    private func line(for metric: MenuBarMetric, includePrefix: Bool) -> some View {
        Text(formattedText(for: metric, includePrefix: includePrefix))
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .monospacedDigit()
    }

    private func formattedText(for metric: MenuBarMetric, includePrefix: Bool) -> String {
        let prefixPart = includePrefix ? "\(prefix.uppercased()) " : ""
        return "\(prefixPart)\(metric.label) \(metric.percent)%"
    }

    private func includePrefix(at index: Int) -> Bool {
        showPrefix && index == 0
    }
}

private struct MenuBarMeterBar: View {
    let percent: Int
    private let segments: Int = 8

    var body: some View {
        let filled = filledSegments()
        let baseColor = Color.primary

        HStack(spacing: 1) {
            ForEach(0..<segments, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(index < filled ? baseColor : baseColor.opacity(0.25))
                    .frame(width: 3, height: 11)
            }
        }
    }

    private func filledSegments() -> Int {
        let clamped = max(0, min(100, percent))
        return min(segments, Int(round(Double(clamped) / 100.0 * Double(segments))))
    }
}


struct UsageMenuBarMenuContent: View {
    @EnvironmentObject var indexer: SessionIndexer
    @EnvironmentObject var codexStatus: CodexUsageModel
    @EnvironmentObject var claudeStatus: ClaudeUsageModel
    @Environment(\.openWindow) private var openWindow
    @AppStorage("ShowUsageStrip") private var showUsageStrip: Bool = false
    @AppStorage("MenuBarScope") private var menuBarScopeRaw: String = MenuBarScope.both.rawValue
    @AppStorage("MenuBarStyle") private var menuBarStyleRaw: String = MenuBarStyleKind.bars.rawValue
    @AppStorage("MenuBarSource") private var menuBarSourceRaw: String = MenuBarSource.codex.rawValue

    var body: some View {
        let source = MenuBarSource(rawValue: menuBarSourceRaw) ?? .codex

        VStack(alignment: .leading, spacing: 10) {
            // Reset times at the top as enabled buttons so they render as normal menu items.
            // Tapping opens the Usage-related preferences pane.
            if source == .codex || source == .both {
                VStack(alignment: .leading, spacing: 2) {
                    if source == .both {
                        Text("Codex").font(.headline).padding(.bottom, 2)
                    } else {
                        Text("Reset times").font(.body).fontWeight(.semibold).foregroundStyle(.primary).padding(.bottom, 2)
                    }

                    Button(action: { openPreferencesUsage() }) {
                        HStack(spacing: 6) {
                            Text(resetLine(label: "5h:", percent: codexStatus.fiveHourPercent, reset: displayReset(codexStatus.fiveHourResetText, kind: "5h", source: .codex, lastUpdate: codexStatus.lastUpdate, eventTimestamp: codexStatus.lastEventTimestamp)))
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)

                    Button(action: { openPreferencesUsage() }) {
                        HStack(spacing: 6) {
                            Text(resetLine(label: "Wk:", percent: codexStatus.weekPercent, reset: displayReset(codexStatus.weekResetText, kind: "Wk", source: .codex, lastUpdate: codexStatus.lastUpdate, eventTimestamp: codexStatus.lastEventTimestamp)))
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)

                    // Last updated time
                    if let lastUpdate = codexStatus.lastUpdate {
                        Text("Updated \(timeAgo(lastUpdate))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }
            }

            if source == .both {
                Divider()
            }

            if source == .claude || source == .both {
                VStack(alignment: .leading, spacing: 2) {
                    if source == .both {
                        Text("Claude").font(.headline).padding(.bottom, 2)
                    } else {
                        Text("Reset times").font(.body).fontWeight(.semibold).foregroundStyle(.primary).padding(.bottom, 2)
                    }

                    Button(action: { openPreferencesUsage() }) {
                        HStack(spacing: 6) {
                            Text(resetLine(label: "5h:", percent: claudeStatus.sessionPercent, reset: displayReset(claudeStatus.sessionResetText, kind: "5h", source: .claude, lastUpdate: claudeStatus.lastUpdate)))
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)

                    Button(action: { openPreferencesUsage() }) {
                        HStack(spacing: 6) {
                            Text(resetLine(label: "Wk:", percent: claudeStatus.weekAllModelsPercent, reset: displayReset(claudeStatus.weekAllModelsResetText, kind: "Wk", source: .claude, lastUpdate: claudeStatus.lastUpdate)))
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)

                    // Last updated time
                    if let lastUpdate = claudeStatus.lastUpdate {
                        Text("Updated \(timeAgo(lastUpdate))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }
            }

            Divider()

            // Quick switches as radio-style rows (menu-friendly)
            Text("Source").font(.body).fontWeight(.semibold).foregroundStyle(.primary)
            radioRow(title: MenuBarSource.codex.title, selected: (menuBarSourceRaw == MenuBarSource.codex.rawValue)) {
                menuBarSourceRaw = MenuBarSource.codex.rawValue
            }
            radioRow(title: MenuBarSource.claude.title, selected: (menuBarSourceRaw == MenuBarSource.claude.rawValue)) {
                menuBarSourceRaw = MenuBarSource.claude.rawValue
            }
            radioRow(title: MenuBarSource.both.title, selected: (menuBarSourceRaw == MenuBarSource.both.rawValue)) {
                menuBarSourceRaw = MenuBarSource.both.rawValue
            }

            Text("Style").font(.body).fontWeight(.semibold).foregroundStyle(.primary)
            radioRow(title: MenuBarStyleKind.bars.title, selected: (menuBarStyleRaw == MenuBarStyleKind.bars.rawValue)) {
                menuBarStyleRaw = MenuBarStyleKind.bars.rawValue
            }
            radioRow(title: MenuBarStyleKind.numbers.title, selected: (menuBarStyleRaw == MenuBarStyleKind.numbers.rawValue)) {
                menuBarStyleRaw = MenuBarStyleKind.numbers.rawValue
            }
            Text("Scope").font(.body).fontWeight(.semibold).foregroundStyle(.primary)
            radioRow(title: MenuBarScope.fiveHour.title, selected: (menuBarScopeRaw == MenuBarScope.fiveHour.rawValue)) {
                menuBarScopeRaw = MenuBarScope.fiveHour.rawValue
            }
            radioRow(title: MenuBarScope.weekly.title, selected: (menuBarScopeRaw == MenuBarScope.weekly.rawValue)) {
                menuBarScopeRaw = MenuBarScope.weekly.rawValue
            }
            radioRow(title: MenuBarScope.both.title, selected: (menuBarScopeRaw == MenuBarScope.both.rawValue)) {
                menuBarScopeRaw = MenuBarScope.both.rawValue
            }
            Divider()
            Button("Open Agent Sessions") {
                // Bring main window to front
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "Agent Sessions")
            }
            Button("Refresh Limits") {
                switch source {
                case .codex:
                    codexStatus.refreshNow()
                case .claude:
                    claudeStatus.refreshNow()
                case .both:
                    codexStatus.refreshNow()
                    claudeStatus.refreshNow()
                }
            }
            Toggle("Show in-app usage strip", isOn: $showUsageStrip)
            Divider()
            Button("Open Preferences…") {
                if let updater = UpdaterController.shared {
                    PreferencesWindowController.shared.show(indexer: indexer, updaterController: updater, initialTab: .general)
                }
            }
        }
        .padding(8)
        .frame(minWidth: 360)
    }

    private func openPreferencesUsage() {
        if let updater = UpdaterController.shared {
            PreferencesWindowController.shared.show(indexer: indexer, updaterController: updater, initialTab: .general)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

private struct RadioRow: View {
    let title: String
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                let col: Color = selected ? .accentColor : .secondary
                Image(systemName: selected ? "checkmark" : "circle")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(col)
                    .frame(width: 16)
                Text(title)
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

private func radioRow(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
    RadioRow(title: title, selected: selected, action: action)
}

// MARK: - Coloring helpers (menu content supports colors)
private func colorFor(percent: Int) -> Color {
    if percent >= 90 { return .red }
    if percent >= 76 { return .yellow }
    return .green
}

private func displayReset(_ text: String, kind: String, source: UsageTrackingSource, lastUpdate: Date?, eventTimestamp: Date? = nil) -> String {
    guard !text.isEmpty else { return "—" }

    // Check if data is stale
    if isResetInfoStale(kind: kind, source: source, lastUpdate: lastUpdate, eventTimestamp: eventTimestamp) {
        return UsageStaleThresholds.outdatedCopy
    }

    var result = text
    if result.hasPrefix("resets ") {
        result = String(result.dropFirst("resets ".count))
    }
    // Strip timezone like "(America/Los_Angeles)"
    if let parenIndex = result.firstIndex(of: "(") {
        result = String(result[..<parenIndex]).trimmingCharacters(in: .whitespaces)
    }
    return result
}

private func inlineBar(_ percent: Int, segments: Int = 5) -> String {
    let p = max(0, min(100, percent))
    let filled = min(segments, Int(round(Double(p) / 100.0 * Double(segments))))
    let empty = max(0, segments - filled)
    return String(repeating: "▰", count: filled) + String(repeating: "▱", count: empty)
}

private func resetLine(label: String, percent: Int, reset: String) -> AttributedString {
    var line = AttributedString("")
    var labelAttr = AttributedString(label + " ")
    labelAttr.font = .system(size: 13, weight: .semibold)
    line.append(labelAttr)

    var barAttr = AttributedString(inlineBar(percent) + " ")
    barAttr.font = .system(size: 13, weight: .regular, design: .monospaced)
    line.append(barAttr)

    var percentAttr = AttributedString("\(percent)%  ")
    percentAttr.font = .system(size: 13, weight: .regular, design: .monospaced)
    line.append(percentAttr)

    var resetAttr = AttributedString(reset)
    resetAttr.font = .system(size: 13)
    line.append(resetAttr)

    return line
}
