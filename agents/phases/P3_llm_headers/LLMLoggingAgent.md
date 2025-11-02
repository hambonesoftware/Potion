# Agent: LLMLoggingAgent

## Purpose
Comprehensive logging for LLM interactions.

## Tasks
- Log model name, token usage estimates, latency, retry count.
- Link raw JSON file path in ParseLog.
- Provide "Copy prompt" and "Copy raw" buttons in Logs UI.

## Tests
- Ensure logs are written even on failure.
