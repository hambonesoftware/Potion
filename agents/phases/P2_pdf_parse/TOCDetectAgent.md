# Agent: TOCDetectAgent

## Purpose
Detect and mark TOC/Index lines to exclude from header matching later.

## Heuristics
- Presence of leader dots, trailing page numbers.
- Pages titled 'Contents', 'Table of Contents', 'Index'.
- Narrow columns with many numeric endings.

## Output
- `DocLine.isTOC = true` for lines inside detected TOC ranges.

## Tests
- PDFs with and without TOC; ensure recall without over-flagging.
