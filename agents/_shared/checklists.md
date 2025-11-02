# Checklists

## PR/Commit Checklist (each agent)
- [ ] Update `CHANGELOG.md` with short, imperative summary.
- [ ] Add/Update unit tests and (if UI) snapshot tests.
- [ ] Run build with `OTHER_SWIFT_FLAGS=-warnings-as-errors` (no warnings).
- [ ] Instruments quick check: no allocations explosion / leaks for new long-running tasks.
- [ ] Update `AppConfig` if new toggles added; wire to Settings.
- [ ] Verify VoiceOver labels on new views.

## Acceptance Gates
- Phase-specific criteria must be satisfied (see `plan_docs/` acceptance_criteria).
