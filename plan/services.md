# Services

- **PDFParseService**
  - Input: `documentId`, file URL.
  - Output: `DocLine[]` with page/line/y-bounds, `isTOC` hints.
- **LLMService (OpenRouter)**
  - `headers(for documentId)` → strict JSON (headers & subheaders), save raw response file.
- **HeaderMatchService**
  - Strategy chain: exact → normalized → token-set → n-gram; TOC-exclusion; last-match-wins.
  - Output: `HeaderMatch[]` and `SectionChunk[]`.
- **ImportExportService**
  - Import/export Plant JSONs (maps to native models), export support bundle.
- **ConfigService**
  - Flags/toggles persisted to app storage (see `config_flags.md`).
