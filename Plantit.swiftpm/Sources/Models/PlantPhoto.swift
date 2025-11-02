import Foundation
import SwiftData

@Model
final class PlantPhoto: Identifiable {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var caption: String
    var placeholderSymbolName: String
    var colorSeed: Int
    var plant: Plant?

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        caption: String = "",
        placeholderSymbolName: String = "leaf", 
        colorSeed: Int = Int.random(in: 0...4),
        plant: Plant? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.caption = caption
        self.placeholderSymbolName = placeholderSymbolName
        self.colorSeed = colorSeed
        self.plant = plant
    }
}

extension PlantPhoto: Hashable {
    static func == (lhs: PlantPhoto, rhs: PlantPhoto) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
