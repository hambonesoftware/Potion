# Agent: ParseLoggingAgent

## Purpose
Add detailed parse transcript and metrics to `ParseLog` and OSLog.

## Metrics
- Pages, lines, TOC lines, durations, memory watermark.
- Per-page timing and anomalies (e.g., zero-text pages).

## Tests
- Verify log entries written; export to support bundle.
