# Agent: SearchIndexAgent

## Purpose
Index sections and lines using GRDB FTS5 and provide ranked search with snippets.

## Tasks
- Create FTS tables; batch insert.
- `search(query)` returns sections first, then lines, with highlight ranges.
- Rebuild index on demand or post-parse.

## Perf
- Query latency target: < 50ms for typical queries on test corpus.

## Tests
- Known queries → expected IDs & snippet assertions.
