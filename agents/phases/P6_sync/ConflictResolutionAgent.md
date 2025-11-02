# Agent: ConflictResolutionAgent

## Purpose
Define conflict strategy and audit trail.

## Strategy
- Last-write-wins; keep previous version in history table.
- Emit audit entries to Logs.

## Tests
- Parallel edits; expected survivor + audit entries.
