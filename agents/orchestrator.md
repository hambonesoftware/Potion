# Orchestrator — Plantit Native SwiftUI Port
**Date:** 2025-11-02

This orchestrator coordinates phase-specific agents to fully port Plantit (frontend + backend) into a single SwiftUI 6+ iPad app. 
Legacy web assets are assumed to live in `plantit_html/` and may be wrapped in early phases for parity.

## Global Constraints
- Swift 6, SwiftUI 6+, iPadOS 18 target.
- Pure Swift services (no Python runtime). LLM via OpenRouter only.
- Persistence: SwiftData for domain, GRDB/SQLite FTS5 for search.
- Logging: OSLog categories (`parse`, `headers`, `match`, `search`, `ui`, `net`), exportable bundle.
- Config flags default ON: `veryVerboseLogs`, `headersLLMStrict`, `excludeTOC`, `lastMatchWins`.
- Secrets: `OPENROUTER_API_KEY` in Keychain; never hardcode or commit.
- Accessibility: Dynamic Type and VoiceOver labels required for all views.
- Tests required per phase before advancing.

## Execution Flow
1. Run Phase agent(s) in order P0 → P7.
2. Each agent must: (a) write/modify files, (b) add/update tests, (c) update CHANGELOG line, (d) run build/tests, (e) emit short status.
3. If a phase fails acceptance tests, do not continue.

## Definition of Done (Global)
- Builds clean (no warnings) with Swift 6 strict concurrency checks.
- Unit + snapshot tests pass; perf thresholds met by P7.
- Support bundle export verified.
- Legacy wrapper disabled by default in P5+.
