import Foundation
import SwiftData

@Model
final class PlantActivity: Identifiable {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var kind: ActivityKind
    var note: String
    var plant: Plant?

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        kind: ActivityKind,
        note: String = "",
        plant: Plant? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.kind = kind
        self.note = note
        self.plant = plant
    }

    enum ActivityKind: String, Codable, CaseIterable, Identifiable {
        case water
        case fertilize
        case note

        var id: String { rawValue }

        var iconName: String {
            switch self {
            case .water: return "drop.fill"
            case .fertilize: return "leaf.fill"
            case .note: return "square.and.pencil"
            }
        }

        var description: String {
            switch self {
            case .water: return "Watered"
            case .fertilize: return "Fertilized"
            case .note: return "Note"
            }
        }
    }
}

extension PlantActivity: Hashable {
    static func == (lhs: PlantActivity, rhs: PlantActivity) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
