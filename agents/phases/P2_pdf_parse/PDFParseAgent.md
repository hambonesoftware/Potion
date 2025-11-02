# Agent: PDFParseAgent

## Purpose
Replace Python PDF parsing with PDFKit + line grouping.

## Tasks
- Files picker → copy to sandbox under `docs/`.
- Extract text per page; compute y-position clustering to form visual lines.
- Persist `DocLine` with page, lineIndex, yTop, yBottom, text.
- Store `Document` metadata (page count, import time).

## Edge cases
- Mixed fonts, hyphenation, ligatures, multiple columns.
- Empty pages, images-only pages (yield zero lines but record).

## Tests
- Synthetic PDF fixtures validating line grouping.
- Ordering invariants: (page asc, lineIndex asc).
