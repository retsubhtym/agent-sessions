# Codex CLI Session Storage Format

This document describes how Codex CLI persists per‑session logs on disk and what fields commonly appear in each JSON Lines (JSONL) entry, including how images and encrypted reasoning content are represented.

## Location and Naming
- Root: `$CODEX_HOME/sessions` if `CODEX_HOME` is set; otherwise `~/.codex/sessions`.
- Sharding: `YYYY/MM/DD/` subfolders.
- File pattern: `rollout-*.jsonl` (one file per session).

References:
- Codex repo/issues discuss JSONL storage and date‑sharded folders. See openai/codex issue threads on sessions and logging format. (Example: rollout‑*.jsonl in date shards.)
- For how Codex enumerates and resumes sessions, see `docs/codex-resume.md`.

## File Structure
- Encoding: UTF‑8.
- Format: One JSON object per line; each line is a standalone “event”.
- Ordering: Append‑only, chronological in practice (not guaranteed by the format).

## Event Schema (Observed)
Codex is tolerant to schema drift. Fields below are commonly present; names may vary. Unknown fields should be preserved.

- Identity and threading
  - `id` or `message_id`: stable identifier for a message/chunk.
  - `parent_id`: identifier of the parent message (for threaded/tool flows).
  - `delta`, `chunk`, `delta_index`: presence implies a streamed/delta part of a larger message.

- Time
  - Keys: any of `timestamp`, `time`, `ts`, `created`, `created_at`, `datetime`, `date`, `event_time`, `when`, `at`.
  - Types: ISO‑8601 string (with/without fractional seconds) or numeric epoch (seconds, milliseconds, microseconds).

- Kind and role
  - `type`: preferred source for event kind; examples: `user`, `assistant`, `tool_call`, `tool_result`, `error`, `meta`.
  - `role`: fallback when `type` is absent; common values `user`, `assistant`, `system`.
  - Compatibility mappings (examples):
    - `function_call` → `tool_call`
    - `function_result` → `tool_result`
    - `system` → `meta`

- Model and metadata
  - `model`: model name if supplied by the client or server.
  - Optional repo/context fields sometimes included by clients: e.g., `git_branch`, `repo.branch`, `branch`.

- Text content
  - Singular string: `content`, `text`, or `message` as a simple string.
  - Array of parts: `content: [...]` where parts are objects or strings. Typical text shapes include:
    - `{ "type": "text", "text": "..." }`
    - `{ "value": "..." }` (client‑specific)
    - Raw strings within the array

- Tool calls and results
  - Tool name: `tool`, `name`, or `function.name`.
  - Arguments: `arguments` or `input` as a string; may also be an object/array (JSON‑encoded when logged).
  - Outputs (stable precedence when multiple are present): `stdout`, `stderr`, `result`, `output`. Values can be strings or structured JSON.

## Images in Events
Codex records whatever the client sends. Two common patterns:

1) Inline (Base64 data URI)
   - Chat/Responses content may include an image part whose URL is a `data:` URI, e.g., `data:image/png;base64,<...>`.
   - Example part:
     ```json
     { "type": "input_image", "image_url": { "url": "data:image/png;base64,iVBORw0..." } }
     ```

2) Reference (HTTP(S) URL or file identifier)
   - The part points at a remote URL (HTTP/S) or a platform file reference (e.g., `image_file` with an ID).
   - Example part:
     ```json
     { "type": "input_image", "image_url": { "url": "https://example.com/picture.jpg" } }
     ```

Notes:
- Different Codex clients choose different strategies. Some IDE clients embed Base64 to ensure offline reproducibility; others log URLs or file IDs to keep logs small and avoid storing pixels.
- Viewers should treat large Base64 payloads carefully (lazy render, size caps) and avoid fetching remote URLs unless explicitly allowed by the user.

## Encrypted Reasoning Content (`encrypted_content`)
When using the Responses API with reasoning content and privacy features (e.g., stateless mode or Zero‑Data Retention), reasoning items can be returned as encrypted blobs. In those cases, Codex session lines may include opaque, base64‑encoded `encrypted_content` instead of plaintext reasoning.

- Storage: persist exactly as returned. Do not attempt to decrypt or pretty‑print.
- Reuse: to maintain context without storing plaintext, forward the encrypted item back to the API (e.g., via `include: ["reasoning.encrypted_content"]`). The service re‑encrypts/decrypts server‑side.
- UX: consider redacting the blob by default in UIs, with an explicit reveal action and clear retention controls.

Example (reasoning item excerpt within a response):
```json
{
  "type": "reasoning",
  "encrypted_content": "AAECAwQFBgcICQoL..."
}
```

## Example Events

- User message (text):
```json
{ "type": "user", "timestamp": "2025-09-12T16:41:03Z", "content": "Find all TODOs in the repo" }
```

- Assistant with text and an image reference:
```json
{
  "type": "assistant",
  "message_id": "msg_123",
  "content": [
    { "type": "text", "text": "Here is the diagram:" },
    { "type": "input_image", "image_url": { "url": "https://example.com/arch.png" } }
  ]
}
```

- Tool call + result:
```json
{ "type": "tool_call", "function": { "name": "grep" }, "arguments": { "pattern": "TODO", "path": "." } }
{ "type": "tool_result", "stdout": "README.md:12: TODO: add tests\n" }
```

- Streamed assistant chunks (delta):
```json
{ "type": "assistant", "message_id": "msg_456", "delta": true, "content": [{"type":"text","text":"First part"}] }
{ "type": "assistant", "message_id": "msg_456", "delta": true, "content": [{"type":"text","text":" and more"}] }
```

- Reasoning with encrypted content:
```json
{ "type": "meta", "reasoning": { "encrypted_content": "AAECAwQ..." } }
```

## Viewer Recommendations
- Preserve the raw JSON line verbatim alongside any parsed fields.
- Parse kind from `type` first, then `role` as a fallback.
- Coalesce streamed assistant/tool chunks by `message_id` when present.
- Pretty‑print structured `arguments`, `stdout`/`stderr`/`result`/`output` for readability.
- Treat `encrypted_content` as sensitive/opaque; do not index it for search.
- For images:
  - Inline Base64: render lazily and cap size.
  - URL/file reference: show a placeholder with an explicit fetch action.

## Resume Integration
- Codex’s `--resume` picker lists files newest-first by timestamp embedded in the filename (not mtime), with a stable UUID tiebreaker. Pagination is page-sized (25) with a scan cap (100) per fetch.
- The picker’s preview line is the first plain user message found within the first 10 JSONL records.
- The list is global across all repos; Codex does not filter by cwd. App-level repo filters are optional conveniences.
- Launching Codex to resume a specific session can be done via a config override: `codex --config experimental_resume=/abs/path/to/rollout-*.jsonl`. See `docs/codex-resume.md`.

## JSON Schema (Normalized Output)
For contributors and downstream tooling, a minimal schema for our normalized `SessionEvent` lives at:

- `docs/schemas/session_event.schema.json`

Notes:
- This schema covers the normalized output used by Agent Sessions after parsing a raw JSONL line, not the raw input format, which varies by client/version.
- The schema is permissive (`additionalProperties: true`) and only requires `id`, `kind`, and `rawJSON`.

## Provenance
- Codex CLI source/issues describing session JSONL files and logging behavior (rollout‑*.jsonl; date sharding; tolerant fields).
- OpenAI API examples showing image content parts (URL vs. data URL) and encrypted reasoning content guidance.
