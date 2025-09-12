# ADR 0001: Minimal JSON Schema for Normalized SessionEvent

- Status: Accepted
- Date: 2025-09-12

## Context
Codex CLI session logs are JSON Lines with variable shapes depending on client/version. CodexHistory parses each line into a normalized `SessionEvent` used by indexing, search, and rendering. Without a documented contract, downstream code and contributions rely on implicit knowledge in parser tests and source comments.

## Decision
Adopt a minimal, permissive JSON Schema that documents our normalized `SessionEvent` structure. The schema is intentionally small, requires only core identifiers, and allows additional properties to accommodate evolution.

- Schema location: `docs/schemas/session_event.schema.json`
- Required fields: `id` (string), `kind` (enum), `rawJSON` (string)
- Optional fields: `timestamp` (string date-time or number epoch), `role`, `text`, `toolName`, `toolInput`, `toolOutput`, `messageID`, `parentID`, `isDelta`, `model`, `encrypted_content`
- `additionalProperties: true` throughout to remain forward-compatible.

This schema documents our output model, not Codex’s raw input lines. The parser remains tolerant to input drift.

## Consequences
- Pros
  - Clear contract between parsing and UI/indexing.
  - Early detection of breaking changes in normalized output via schema-based validation in tests (optional future work).
  - Easier onboarding for contributors.
- Cons
  - Maintenance overhead to update schema when we add/remove normalized fields.
  - Potential false confidence if tests validate only the schema and not nuanced behavior (chunk coalescing, formatting).

## Alternatives Considered
1. Rely solely on parser tests and code comments. Rejected: less discoverable; harder for external contributors.
2. Define a strict schema for raw input lines. Rejected: Codex input shape varies; strictness would harm compatibility.

## Compliance
- No user-visible behavior change.
- Data/architecture change documented via this ADR and CHANGELOG.

## References
- Session storage format: `docs/session-storage-format.md`
- Schema file: `docs/schemas/session_event.schema.json`

