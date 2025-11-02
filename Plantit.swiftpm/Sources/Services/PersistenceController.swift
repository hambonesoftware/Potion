import Foundation
import SwiftData

@MainActor
final class PersistenceController {
    static let shared = PersistenceController()
    static let preview = PersistenceController(inMemory: true)

    let container: ModelContainer

    private init(inMemory: Bool = false) {
        do {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
            container = try ModelContainer(for: Village.self, Plant.self, configurations: configuration)
            try seedInitialDataIfNeeded()
        } catch {
            fatalError("Failed to configure SwiftData container: \(error.localizedDescription)")
        }
    }

    private func seedInitialDataIfNeeded() throws {
        let context = ModelContext(container)
        let villages = try context.fetch(FetchDescriptor<Village>())
        guard villages.isEmpty else { return }

        let starterVillage = Village(name: "Demo Village", climate: .temperate)
        let samplePlant = Plant(
            name: "Starter Aloe",
            species: "Aloe Vera",
            lastWateredAt: Date().addingTimeInterval(-86_400),
            notes: "Loves bright light."
        )
        starterVillage.plants.append(samplePlant)
        samplePlant.village = starterVillage

        context.insert(starterVillage)
        context.insert(samplePlant)
        try context.save()
    }
}
