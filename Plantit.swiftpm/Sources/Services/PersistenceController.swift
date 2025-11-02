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
            container = try ModelContainer(
                for: Village.self,
                Plant.self,
                PlantActivity.self,
                PlantPhoto.self,
                Schedule.self,
                configurations: configuration
            )
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
        let lastWatered = Date().addingTimeInterval(-86_400)
        let wateringSchedule = Schedule(
            kind: .watering,
            cadenceKind: .everyNDays,
            frequencyInDays: 7,
            lastCompletedAt: lastWatered
        )
        wateringSchedule.recomputeNextDue(referenceDate: lastWatered)
        let samplePlant = Plant(
            name: "Starter Aloe",
            species: "Aloe Vera",
            lastWateredAt: lastWatered,
            notes: "Loves bright light.",
            village: starterVillage,
            activities: [
                PlantActivity(
                    createdAt: Date().addingTimeInterval(-43_200),
                    kind: .water,
                    note: "Morning mist"
                )
            ],
            photos: [
                PlantPhoto(caption: "Arrival day", placeholderSymbolName: "camera.fill")
            ],
            schedules: [wateringSchedule]
        )
        wateringSchedule.plant = samplePlant
        samplePlant.activities.forEach { $0.plant = samplePlant }
        samplePlant.photos.forEach { $0.plant = samplePlant }
        starterVillage.plants.append(samplePlant)

        context.insert(starterVillage)
        context.insert(samplePlant)
        try context.save()
    }
}
