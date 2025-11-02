# Agent: LegacyWrapperAgent (optional)

## Purpose
Load `plantit_html/index.html` inside `WKWebView` for parity while we port features.

## Tasks
- Bundle `plantit_html/` under `Resources/legacy_web/`.
- Add `LegacyWebContainerView` to load local HTML with `loadFileURL`.
- Inject `window.PLANTIT_BASE_URL='app://native'` and install a JS bridge to Swift for API stubs.

## Tests
- Smoke test: wrapper loads and displays the legacy home.
