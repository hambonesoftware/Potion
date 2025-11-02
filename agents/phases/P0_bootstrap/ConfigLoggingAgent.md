# Agent: ConfigLoggingAgent

## Purpose
Wire very verbose logging, log file sink, and Settings toggle.

## Tasks
- Implement `LogStore` that writes to `Application Support/logs/` (rotating files).
- Add Settings view with toggles for `veryVerboseLogs` and `useLegacyWebFallback`.
- Add startup banner logging with versions/build number.

## Tests
- Unit test `LogStore` write/rotate behavior.
- Snapshot of Settings view.
