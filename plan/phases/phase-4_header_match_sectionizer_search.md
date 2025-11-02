# Phase 4 — Header Matching, Sectionizer & Search (FTS5)

**Goal**: Map header guesses to `DocLine` anchors, build `SectionChunk[]`, and index/search with FTS5.

## Tasks
- Matching strategy chain: exact → normalized → token-set → n-gram.
- Hard TOC exclusion; prefer last match in body.
- Build `SectionChunk[]` from anchor to next header/subheader (depth-aware).
- GRDB FTS5 index: index `SectionChunk.plainText` and optionally `DocLine.text`.
- Search service: ranked results, highlights/snippets.

## Acceptance
- Golden vs. matched report shows high precision mapping.
- Search returns correct sections quickly (<50ms typical queries).
