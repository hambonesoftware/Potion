# Agent: SchemaValidationAgent

## Purpose
Validate and parse the LLM JSON into `HeaderGuess[]` with robust error reporting.

## Tasks
- JSON schema validation (levels normalized, no cycles).
- Record validation errors into ParseLog and present in Logs UI.

## Tests
- Fixtures with missing/extra fields; ensure graceful handling.
