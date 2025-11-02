# Domain Data Models (initial sketch)

- `Village { id, name, createdAt, updatedAt }`
- `Plant { id, villageId, name, species, acquiredAt, notes, tags[], images[], createdAt, updatedAt }`
- `PlantActivity { id, plantId, type (water/prune/repot/etc), at, notes }`
- `Document { id, displayName, fileURL (sandbox), pageCount, importedAt }`
- `DocLine { id, documentId, page, lineIndex, yTop, yBottom, text, isTOC }`
- `HeaderGuess { id, documentId, level, title, rawJSONIndexPath }`
- `HeaderMatch { id, documentId, guessId, lineId, confidence }`
- `SectionChunk { id, documentId, headerMatchId, startLineId, endLineId, plainText }`
- `ParseLog { id, documentId, startedAt, endedAt, events[], llmRawPath? }`

> Final properties will be refined in implementation; models should be SwiftData `@Model` types where appropriate.
