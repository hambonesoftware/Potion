# Phase 7 — QA Hardening (Perf, Scale, Offline)

**Goal**: Validate performance at realistic sizes and ensure robust offline operation.

## Tasks
- Perf tests: 250+ pages, 20k lines, 1k sections.
- Instruments profiling; fix leaks/hangs; streaming parse where needed.
- Offline-first UX (LLM disabled state, queued ops).
- UI snapshot tests; accessibility audit (Dynamic Type, VoiceOver).

## Acceptance
- Latency goals met; no crashes; smooth scrolling on large datasets.
- Legacy wrapper fully removed.
