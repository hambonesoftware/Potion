# Architecture

## Modules (Swift packages or targets)
- **Domain**: Core entities and use cases. Pure Swift.
- **Data**: Persistence implementations (SwiftData for domain, GRDB/SQLite for FTS index).
- **Services**: PDF parse, LLM client, header matching, search index, import/export, logging.
- **AppUI**: SwiftUI feature modules (Villages/Plants, Documents, Search, Settings, Logs).
- **Support**: AppConfig, OSLog categories, Error types, Utilities.

## Execution model
- Swift Concurrency (async/await).
- Long-running tasks (parse/index) cancellable; progress reporting via `AsyncStream`/`Observation`.

## Storage
- SwiftData for domain models (Plants, Villages, Activities, Documents, Sections).
- GRDB (SQLite FTS5) for full-text search over SectionChunk + DocLine.

## Logs
- OSLog categories: `parse`, `headers`, `match`, `search`, `ui`, `net`.
- Exportable bundle: DB, logs, config flags, LLM request/response JSON.
