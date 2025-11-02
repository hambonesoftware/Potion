import Foundation
import SwiftData

@Model
final class Village: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var climate: Climate
    @Relationship(deleteRule: .cascade, inverse: \Plant.village) var plants: [Plant]

    init(id: UUID = UUID(), name: String, climate: Climate, plants: [Plant] = []) {
        self.id = id
        self.name = name
        self.climate = climate
        self.plants = plants
    }

    enum Climate: String, Codable, CaseIterable {
        case tropical
        case arid
        case temperate
        case continental
        case polar
    }
}

extension Village: Hashable {
    static func == (lhs: Village, rhs: Village) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
