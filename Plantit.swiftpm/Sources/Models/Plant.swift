import Foundation
import SwiftData

@Model
final class Plant: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var species: String
    var lastWateredAt: Date?
    var notes: String
    var createdAt: Date
    var village: Village?
    @Relationship(deleteRule: .cascade, inverse: \PlantActivity.plant) var activities: [PlantActivity]
    @Relationship(deleteRule: .cascade, inverse: \PlantPhoto.plant) var photos: [PlantPhoto]
    @Relationship(deleteRule: .cascade, inverse: \Schedule.plant) var schedules: [Schedule]

    init(
        id: UUID = UUID(),
        name: String,
        species: String,
        lastWateredAt: Date? = nil,
        notes: String = "",
        createdAt: Date = .now,
        village: Village? = nil,
        activities: [PlantActivity] = [],
        photos: [PlantPhoto] = [],
        schedules: [Schedule] = []
    ) {
        self.id = id
        self.name = name
        self.species = species
        self.lastWateredAt = lastWateredAt
        self.notes = notes
        self.createdAt = createdAt
        self.village = village
        self.activities = activities
        self.photos = photos
        self.schedules = schedules
    }
}

extension Plant: Hashable {
    static func == (lhs: Plant, rhs: Plant) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
