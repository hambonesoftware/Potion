# Migration Guide (with `plantit_html/` present)

## Goal
Use `plantit_html` as a **baseline and functional reference** in early phases, then retire it once native UI is feature complete.

## Steps
1. **P0 Wrapper (temporary)**
   - Copy `plantit_html/` into Xcode project under `Resources/legacy_web/`.
   - Add `useLegacyWebFallback` flag to Settings. When ON, a `WKWebView` loads `index.html` for parity demos.
2. **API shim**
   - For wrapper mode, inject `window.PLANTIT_BASE_URL = 'app://native'` and intercept fetches to call Swift services.
3. **Parity checks**
   - For each feature you port natively (plants, docs, search), verify outputs match the legacy page results for the same input PDFs and plant JSON.
4. **Retire legacy**
   - At Phase 5 exit, default `useLegacyWebFallback` to OFF. Remove in Phase 7.

## Mapping
- Plant JSON importers read the same schema used by `plantit_html` individual plant files.
- All images/attachments imported into sandbox; references updated.
