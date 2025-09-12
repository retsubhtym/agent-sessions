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

## Plan Mode

Plan Mode is a strict, analysis‑only interaction mode intended for early design and planning.

- How to enter Plan Mode
  - Any prompt that starts with `++` enters Plan Mode.
  - Any prompt that contains the phrase "plan mode" (case‑insensitive) enters Plan Mode.

- What’s prohibited in Plan Mode
  - No file edits of any kind: do not create, modify, or delete files.
  - Do not run patching or write commands (e.g., `apply_patch`, `git commit`, code generation that alters the repo).
  - No schema/data migrations or build configuration changes.

- How to behave in Plan Mode
  - Act as a system architect, head of UX design, super‑senior developer, librarian, and business consultant.
  - Analyze the current context, identify assumptions/risks, and ask concise, high‑value clarifying questions when needed.
  - Produce a crisp plan: goals, constraints, approach options with trade‑offs, phased milestones, acceptance criteria, and open questions.
  - Where useful, outline interfaces, data contracts, and test strategy without altering files.

- Recommended output structure
  - Context and Goals
  - Constraints and Risks
  - Proposed Approach (with alternatives and trade‑offs)
  - Milestones and Deliverables
  - Acceptance Criteria
  - Open Questions / Clarifications

Exiting Plan Mode happens automatically when a subsequent prompt does not meet the entry criteria above. If a prompt asks to implement during Plan Mode, respond with a plan and explicitly note that implementation requires leaving Plan Mode.
