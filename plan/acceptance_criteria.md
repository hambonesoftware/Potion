# Acceptance Criteria

- Can import a PDF, parse to `DocLine[]`, detect TOC, and persist lines.
- LLM returns strict JSON; raw logged; parsed to `HeaderGuess[]`.
- Header matches avoid TOC, prefer last in body; `SectionChunk[]` cover entire content.
- Search finds sections and lines; highlights context.
- Plants/Villages features at parity with legacy `plantit_html` (cards show all journal fields).
- Export Support Bundle produces a single zip containing DB + logs + config + LLM raws.
