# Risks & Mitigations

- **PDF line fidelity**: PDFKit text runs may not equal visual lines. 
  - *Mitigation*: y-position clustering tolerance, hyphenation join, whitespace aware grouping, bbox retained.
- **TOC bleed-through**: Matches anchor TOC.
  - *Mitigation*: TOC detection; last-match-wins; min distance from TOC pages.
- **LLM drift**: model outputs shift.
  - *Mitigation*: strict schema parsing with validation; version prompts; fixture tests with recorded responses.
- **Index bloat**: FTS grows with large docs.
  - *Mitigation*: store plain text once per SectionChunk; periodic vacuum; batch rebuild.
