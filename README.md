CodexHistory (macOS)
====================

What it is
----------
- A fast, native macOS viewer/indexer for Codex CLI session logs.
- Reads existing JSON Lines logs and provides a three‑pane browser with full‑text search and filters.
- It does NOT resume or continue sessions; it is a read‑only viewer (by design for MVP).

Requirements
------------
- Xcode 15+ / Swift 5.9+
- macOS 14 Sonoma or newer

Directory rules
---------------
- Codex CLI writes per‑session logs under `$CODEX_HOME/sessions/YYYY/MM/DD/rollout-*.jsonl`.
- If `CODEX_HOME` is not set, the default is `~/.codex/sessions`.
- CodexHistory resolves the root using:

  ```swift
  let root = ProcessInfo.processInfo.environment["CODEX_HOME"].map { URL(fileURLWithPath: $0).appendingPathComponent("sessions") } ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".codex/sessions")
  ```

Build & run
-----------
- Open `CodexHistory.xcodeproj` in Xcode and run the `CodexHistory` scheme.
- First run: if the default folder is unreadable/missing, you'll be prompted to pick a custom path (also editable in Preferences).

Testing
-------
- From Terminal:

  ```bash
  xcodebuild -project CodexHistory.xcodeproj -scheme CodexHistory -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO test
  ```

MVP features (implemented)
--------------------------
- Parser + indexer
  - Recursively scans date‑sharded dirs for `rollout-*.jsonl`.
  - Streams JSONL line‑by‑line with tolerant decoding (keeps raw JSON when shape varies).
  - Builds `Session` models with metadata and `SessionEvent`s.
  - Refresh with in‑progress status and incremental updates.
- Two‑pane SwiftUI UI
  - Sidebar grouped by Today/Yesterday/yyyy‑MM‑dd/Older with enriched rows (ID, modified, msgs, branch, summary, model).
  - Transcript detail uses Codex‑like style with prefixes, role colors, optional timestamps, and ANSI export.
- Whole‑session Raw/Pretty is currently hidden from menus.
- Search + filters
  - Debounced full‑text search across all event text.
  - Filters: date range, model dropdown, message‑type toggles.
- Preferences for path override (persisted in `UserDefaults`).
 - Appearance: theme (Codex Dark / Monochrome), toggle timestamps.

Privacy
-------
- Reads local log files only. No network access is required for indexing or viewing.

Known limitations / V2 (out of scope)
-------------------------------------
- Export to Markdown/JSONL.
- Sensitive content masking toggle.
- Resume/continue Codex session.

Project structure
-----------------
- `CodexHistory/` – app sources
  - `Model/` – `Session`, `SessionEvent`
  - `Services/` – `SessionIndexer`
  - `Views/` – three‑pane UI and preferences
  - `Utilities/` – `JSONLReader`, `PrettyJSON`
- `Resources/Fixtures/` – test fixtures
- `CodexHistoryTests/` – unit tests
- `.github/workflows/ci.yml` – CI builds and tests on `macos-latest`

Documentation
-------------
- Codebase review (v0.1): `docs/codebase-0.1-review.md`
- Changelog: `docs/CHANGELOG.md`
