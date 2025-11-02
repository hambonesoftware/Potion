# Agent: HeaderMatchAgent

## Purpose
Resolve `HeaderGuess` → `HeaderMatch` (DocLine anchor).

## Strategy
1) Exact match
2) Normalized (whitespace/case/punct)
3) Token-set ratio
4) N-gram similarity
- Hard exclusion: lines where `isTOC = true`
- Last-match-wins to avoid TOC.

## Output
- `HeaderMatch` with confidence score and anchor lineId.

## Tests
- Adversarial headers (punctuation variants, duplicates, near-matches).
- Ensure anchors never land in TOC.
