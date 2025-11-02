# Prompt Snippets (Reusable in Agents)

**Very Verbose Logging Toggle**
- Add `AppConfig.veryVerboseLogs` (default: true).
- Wrap long tasks with log banners: start/end, durations, counts (pages, lines, sections), token stats.
- Provide a Settings switch to enable/disable.

**Keychain Access (OpenRouter)**
- Use `SecItemAdd/CopyMatching/Update` wrappers.
- Provide Settings UI for entering/updating key; validate by performing a no-op call (e.g., model list).

**Files Location**
- Use `FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)`.
- Create subdirs: `logs/`, `docs/`, `exports/`.

**Export Support Bundle**
- Zip: SQLite/SwiftData store, GRDB db + fts tables, `logs/`, `config.json`, `llm_raw/`.
