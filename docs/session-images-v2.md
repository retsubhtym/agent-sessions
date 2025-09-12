# Session Images: Storage Notes and V2 Plan

This document explains how images appear in Codex CLI session JSONL logs and outlines a pragmatic V2 plan to surface them in CodexHistory while preserving privacy and performance.

## What Sessions May Contain
- Image content parts from assistant/user messages:
  - Inline Base64 data URIs: `data:image/png;base64,<...>` inside `image_url.url` or parts of type `input_image`.
  - References: HTTP(S) URLs or platform file identifiers (e.g., uploaded file IDs).
- Tool outputs containing images:
  - Some tools emit Base64 strings or `data:` URLs in `stdout`/`result`.

Implications:
- Logs may embed large Base64 payloads or only references. We must not assume network access nor that pixels are present locally.

## Representation Patterns (Observed)
- Content array shapes:
  - `{ "type": "text", "text": "..." }`
  - `{ "type": "input_image", "image_url": { "url": "data:image/png;base64,..." } }`
  - `{ "type": "image_url", "image_url": { "url": "https://.../image.jpg" } }`
- Tool results:
  - `{ "type": "tool_result", "stdout": "data:image/jpeg;base64,/9j/..." }`

## Constraints and Guardrails
- Privacy: No automatic network fetches. Treat `encrypted_content` as opaque and never index it. Do not index raw image bytes.
- Safety and size: Cap decoded Base64 by configurable limit (default: 25 MB). Downsample when rendering. Lazy decode only on user action.
- Offline‑first: Data URIs render locally; remote URLs require explicit enablement.

## V2 Plan: Parsing, Model, and UI

1) Parser: extract image references
- Detect image parts in `content` arrays where `type` is `image_url` or `input_image`; read `image_url.url`.
- Detect possible `data:` images in tool outputs (`stdout`/`stderr`/`result`/`output`) via prefix match.
- Record images as structured attachments on the normalized event.

Proposed model additions (normalized output):
- `SessionImage` (internal):
  - `source: String` (original URL or data URI)
  - `mediaType: String?` (e.g., `image/png`)
  - `isDataURI: Bool`
  - `approxBytes: Int?` (for size gating)
- `SessionEvent.images: [SessionImage]?` (optional; omitted when none)

Schema/ADR:
- Add `images` array (optional) to the normalized Event schema with permissive items; update ADR 0001 or author ADR 0002 when implemented.

2) UI: transcript chips and preview
- Transcript chips: For events with images, render inline chips: `[image/png • 64 KB] [Preview] [Save…]`.
- Preview: Click opens a sheet or separate window (`ImagePreviewView`) that decodes and downscales as needed.
- Optional Quick Look: Provide a “Quick Look” action if convenient.

3) Preferences
- `Show image chips in transcript` (default: on).
- `Allow fetching remote images` (default: off).
- `Maximum decoded image size (MB)` (default: 25).

4) Fetch policy for remote URLs
- If disabled: show placeholder with an enable‑once button; perform HEAD+GET with timeout and `Content-Type: image/*` validation when enabled.
- Never auto‑cache to disk by default; prompt or keep only in RAM LRU.

5) Caching and performance
- In‑memory LRU keyed by SHA‑256 of the `source` string and effective bytes; evict on memory pressure.
- No persistent cache initially. Consider opt‑in disk cache later.

6) Export and clipboard
- “Save…” exports decoded image to user‑chosen path.
- Copy places bitmap on the pasteboard; optionally include original `source` URL on the pasteboard.

7) Indexing and search
- Do not index raw bytes. Record only small metadata (count, media types).
- Exclude any `encrypted_content` and Base64 payloads from full‑text search.

8) Testing
- Fixtures: one event with a PNG data URI; one with an HTTP URL; one tool result with a data URI.
- Unit tests: parser extracts images; viewer refuses to decode images exceeding the limit; remote fetch guarded by preference.
- Performance tests: decode large Base64 within memory/time budget; verify downsampling.

## Acceptance Criteria
- Parser yields `images` array for supported shapes without breaking existing text/tool behaviors.
- Transcript shows chips only when enabled; preview works for data URIs offline.
- Remote URLs never fetched unless explicitly allowed per preference or “fetch once”.
- Large data URIs are rejected with a clear error banner; app remains responsive.
- No raw image bytes or encrypted blobs are indexed.

## Non‑Goals (for V2)
- No live inline thumbnails inside the monospaced transcript text view.
- No persistent on‑disk image cache by default.
- No remote authentication for private image URLs.

## Open Questions
- Support for animated formats (GIF/WebP) in preview window.
- Handling SVG and PDF images; consider rasterizing with size caps.
- Exif orientation/metadata stripping on export.

## References
- Session storage format: `docs/session-storage-format.md` (background and examples).

