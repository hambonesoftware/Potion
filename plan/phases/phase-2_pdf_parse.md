# Phase 2 — PDF Parse (line-accurate)

**Goal**: Replace Python PDF parsing with PDFKit + line grouping.

## Tasks
- Files picker → copy PDF to sandbox; create `Document` record.
- Extract text per page; group runs into visual lines by y-position tolerance.
- Persist `DocLine` with page, line index, y-bounds, text.
- TOC detection: leader dots, page-number columns, "Contents/Index" pages → mark `isTOC = true`.
- ParseLog entries for durations, counts, memory.

## Acceptance
- Import a real PDF; see `DocLine[]` with stable ordering.
- TOC lines excluded (flag true).
- Parse transcript written.
