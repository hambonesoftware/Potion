import Foundation
import SwiftData

@Model
final class Schedule: Identifiable {
    @Attribute(.unique) var id: UUID
    var kind: Kind
    var frequencyInDays: Int
    var lastCompletedAt: Date?
    var plant: Plant?

    init(
        id: UUID = UUID(),
        kind: Kind,
        frequencyInDays: Int,
        lastCompletedAt: Date? = nil,
        plant: Plant? = nil
    ) {
        self.id = id
        self.kind = kind
        self.frequencyInDays = frequencyInDays
        self.lastCompletedAt = lastCompletedAt
        self.plant = plant
    }

    enum Kind: String, Codable, CaseIterable, Identifiable {
        case watering
        case fertilizing
        case custom

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .watering: return "Watering"
            case .fertilizing: return "Fertilizing"
            case .custom: return "Custom"
            }
        }
    }
}

extension Schedule: Hashable {
    static func == (lhs: Schedule, rhs: Schedule) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
