# Agent: LLMAgent

## Purpose
Fetch strict headers/subheaders JSON for a Document.

## Tasks
- OpenRouter client with retry/backoff and timeouts.
- Prompt enforcing fenced JSON with fields: title, level, pageHint? children[].
- Stream response → write raw to `logs/llm_raw/<docId>/<timestamp>.json`.

## Security
- API key in Keychain; test a minimal call to validate.

## Tests
- Mocked client returning fixtures; parse success/failure paths.
