# Phase 0 — Bootstrap & Legacy Wrapper Baseline

**Goal**: Create a SwiftUI 6+ app skeleton, config/logging, and (optionally) a temporary wrapper for `plantit_html/` to keep a running baseline.

## Tasks
- Xcode project with modules: Domain, Data, Services, AppUI, Support.
- Settings screen with:
  - `veryVerboseLogs` (default ON)
  - `useLegacyWebFallback` (default ON in P0–P2)
- OSLog setup; log to console + file.
- Optional: Add `Resources/legacy_web/` and load `index.html` via `WKWebView`.
- Implement a `fetch` shim for wrapper mode to call Swift services.

## Acceptance
- App launches on iPad.
- When wrapper enabled, `plantit_html` loads and navigates.
- Logs show structured startup banners.
