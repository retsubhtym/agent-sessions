# Triada Agents Playbook

## Required workflow (for humans and agents)
1) Use Conventional Commits for every commit.
2) Add trailers to the commit:
   - Tool: Cursor|Codex|Xcode|Manual|Claude|Figma
   - Model: <model-id, e.g., gpt-5-thinking, o3-mini>
   - Why: <1 line if behavior/structure changed>
3) If you change architecture/data schema/build:
   - Add an ADR in /docs/adr/ using ADR-TEMPLATE.md.
   - Add a bullet under [Unreleased] in /docs/CHANGELOG.md.
4) If you change user-visible behavior:
   - Add a 1–2 bullet note in /docs/summaries/YYYY-MM.md.

## Commit message examples
- feat(ui): add week header tap target
  Tool: Cursor
  Model: gpt-5-thinking

- refactor(data): migrate to SwiftData for events
  Tool: Codex
  Model: gpt-5 high
  Why: Enables queries and relationships; removes manual Codable layer
