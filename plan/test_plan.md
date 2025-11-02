# Test Plan

- **Unit tests**
  - PDF line grouping (fixtures: synthetic PDFs).
  - Header JSON parsing & validation.
  - Matching strategies with adversarial inputs (near-duplicates, punctuation deltas).
  - Search index ranking (queries & expected IDs).
- **Integration tests**
  - Import → Parse → Headers → Match → Sectionize → Search.
  - Plant import/export roundtrips (JSON equality ignoring ordering of optional fields).
- **UI snapshot tests**
  - Core screens at multiple dynamic type sizes.
- **Performance tests**
  - 250-page document ingest time, index time, search latency under 50ms for common queries.
