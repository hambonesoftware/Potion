# Repositories (Protocols)

- `protocol PlantsRepo { list(); get(id); add(PlantDraft); update(Plant); remove(id) }`
- `protocol VillagesRepo { ... }`
- `protocol ActivitiesRepo { ... }`
- `protocol DocsRepo { list(); add(from fileURL); lines(for docID); sections(for docID) }`
- `protocol LogsRepo { append(event), exportBundle() }`
- `protocol SearchIndex { rebuild(for docID); search(query) -> [Result] }`

All repositories provide async APIs and are testable with in-memory fakes.
