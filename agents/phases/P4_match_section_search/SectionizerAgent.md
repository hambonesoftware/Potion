# Agent: SectionizerAgent

## Purpose
Build `SectionChunk[]` from each anchor to the line above the next header/subheader (depth-aware).

## Tasks
- Walk matched headers in reading order.
- Build chunk text by concatenating `DocLine.text` preserving blank lines.
- Persist chunks and surface in UI.

## Tests
- Coverage check: union of chunks spans body without overlap.
- Edge: last section till EOF.
