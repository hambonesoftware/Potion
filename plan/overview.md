# Plantit Native SwiftUI 6+ Port — Plan
**Date:** 2025-11-02

This plan converts the entire Plantit app (both frontend and backend) into a single, fully native SwiftUI 6+ application. 
The current working web app is assumed to be present at `plantit_html/` (HTML/CSS/ESM-JS).

**Guiding principles**
- Keep a *baseline working mode* by wrapping `plantit_html` during Phase 0–2 for parity while we port features natively.
- Replace Python/FastAPI with *pure Swift services*: PDF parsing, header extraction orchestration, persistence, and search.
- Maintain your preference for **very verbose debugging**, explicit logs and exportable support bundles.
- No external servers required except for LLM calls (OpenRouter). 

**Top-level phases**
- P0 Bootstrap & Legacy-Wrapper Baseline
- P1 Domain Models & Persistence
- P2 PDF Parse (line-accurate)
- P3 LLM Headers (strict JSON) + Logging
- P4 Header Matching, Sectionizer & Search (FTS5)
- P5 SwiftUI Feature Set (Plants, Docs, Search, Settings)
- P6 Optional Sync/Interop
- P7 QA Hardening (perf, scale, offline)

Deliverables: docs in this `plan_docs/` folder + per-phase acceptance criteria and tests.
