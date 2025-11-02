import Foundation
import SwiftData

@Model
final class Plant: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var species: String
    var lastWateredAt: Date?
    var notes: String
    var village: Village?

    init(
        id: UUID = UUID(),
        name: String,
        species: String,
        lastWateredAt: Date? = nil,
        notes: String = "",
        village: Village? = nil
    ) {
        self.id = id
        self.name = name
        self.species = species
        self.lastWateredAt = lastWateredAt
        self.notes = notes
        self.village = village
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
