import Foundation
import SwiftData

@MainActor
final class PlantRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchPlants(in village: Village? = nil) async throws -> [Plant] {
        var descriptor = FetchDescriptor<Plant>(
            predicate: nil,
            sortBy: [SortDescriptor(\Plant.name, order: .forward)]
        )

        if let village {
            descriptor.predicate = #Predicate<Plant> { plant in
                plant.village?.id == village.id
            }
        }

        return try context.fetch(descriptor)
    }

    @discardableResult
    func createPlant(
        name: String,
        species: String,
        notes: String,
        village: Village?,
        wateringFrequencyInDays: Int?
    ) async throws -> Plant {
        let plant = Plant(
            name: name,
            species: species,
            notes: notes,
            lastWateredAt: nil,
            village: village
        )

        if let frequency = wateringFrequencyInDays {
            let schedule = Schedule(kind: .watering, frequencyInDays: frequency, plant: plant)
            schedule.recomputeNextDue()
            plant.schedules.append(schedule)
        }

        context.insert(plant)
        try context.save()
        return plant
    }

    func updatePlant(
        _ plant: Plant,
        name: String,
        species: String,
        notes: String,
        village: Village?,
        wateringFrequencyInDays: Int?
    ) async throws {
        plant.name = name
        plant.species = species
        plant.notes = notes
        plant.village = village

        var wateringSchedule = plant.schedules.first { $0.kind == .watering }
        if let frequency = wateringFrequencyInDays {
            if let schedule = wateringSchedule {
                schedule.cadenceKind = .everyNDays
                schedule.frequencyInDays = max(1, frequency)
                schedule.recomputeNextDue()
            } else {
                let schedule = Schedule(kind: .watering, frequencyInDays: frequency, plant: plant)
                schedule.recomputeNextDue()
                plant.schedules.append(schedule)
                wateringSchedule = schedule
            }
        } else if let schedule = wateringSchedule {
            context.delete(schedule)
            plant.schedules.removeAll { $0.id == schedule.id }
        }

        try context.save()
    }

    func deletePlant(_ plant: Plant) async throws {
        context.delete(plant)
        try context.save()
    }

    @discardableResult
    func recordActivity(
        for plant: Plant,
        kind: PlantActivity.ActivityKind,
        note: String = ""
    ) async throws -> PlantActivity {
        let activity = PlantActivity(kind: kind, note: note, plant: plant)
        plant.activities.append(activity)

        if kind == .water {
            plant.lastWateredAt = activity.createdAt
            if let schedule = plant.schedules.first(where: { $0.kind == .watering }) {
                schedule.lastCompletedAt = activity.createdAt
                schedule.recomputeNextDue(referenceDate: activity.createdAt)
            }
        }

        context.insert(activity)
        try context.save()
        return activity
    }

    func complete(schedule: Schedule, at date: Date = .now) async throws {
        if let plant = schedule.plant, let activityKind = schedule.kind.defaultActivityKind {
            _ = try await recordActivity(for: plant, kind: activityKind)
        } else {
            schedule.lastCompletedAt = date
            schedule.recomputeNextDue(referenceDate: date)
            try context.save()
        }
    }

    func snooze(schedule: Schedule, by interval: TimeInterval = 3600) throws {
        let reference = max(Date(), schedule.nextDueAt ?? Date())
        schedule.nextDueAt = reference.addingTimeInterval(interval)
        try context.save()
    }

    @discardableResult
    func addPlaceholderPhoto(
        to plant: Plant,
        caption: String = "",
        symbolName: String = "photo.on.rectangle"
    ) async throws -> PlantPhoto {
        let photo = PlantPhoto(
            caption: caption,
            placeholderSymbolName: symbolName,
            plant: plant
        )
        plant.photos.append(photo)
        context.insert(photo)
        try context.save()
        return photo
    }
}
