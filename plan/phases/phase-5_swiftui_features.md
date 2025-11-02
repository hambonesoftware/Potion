# Phase 5 — SwiftUI Feature Set

**Goal**: Full native UI for Plants, Documents, Search, Settings, and Logs; parity with legacy `plantit_html` features.

## Tasks
- Villages list → Plants grid → Plant detail with activities & attachments.
- Documents list → Import → Parse → Headers → Sections → Diff view.
- Global search; jump-to section/line.
- Settings: API Key (Keychain), toggles; Developer: dump DB, export bundle.
- Import/export individual Plant JSON (compat with legacy files).

## Acceptance
- Native UI flow covers all primary features.
- Logs viewer shows raw LLM JSON and parse traces.
- `useLegacyWebFallback` can be OFF by default.
