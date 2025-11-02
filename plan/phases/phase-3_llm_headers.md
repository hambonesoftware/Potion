# Phase 3 — LLM Headers (strict JSON) + Logging

**Goal**: Call OpenRouter to retrieve exact headers/subheaders, store raw JSON, and parse to `HeaderGuess[]`.

## Tasks
- LLMService with retry/backoff and model/version setting.
- Strict prompt returning fenced JSON with header hierarchy.
- Validate JSON (schema), store raw to `Application Support/logs/headers_<doc>_<ts>.json`.
- Persist `HeaderGuess[]` linked to Document.

## Acceptance
- For known PDFs, stable header lists returned.
- Logs include token estimates, latency, model name.
