import Foundation
import SwiftData

@MainActor
final class VillageRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchVillages() async throws -> [Village] {
        let descriptor = FetchDescriptor<Village>(
            sortBy: [SortDescriptor(\Village.name, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    @discardableResult
    func createVillage(name: String, climate: Village.Climate) async throws -> Village {
        let village = Village(name: name, climate: climate)
        context.insert(village)
        try context.save()
        return village
    }

    func updateVillage(_ village: Village, name: String, climate: Village.Climate) async throws {
        village.name = name
        village.climate = climate
        try context.save()
    }

    func deleteVillage(_ village: Village) async throws {
        context.delete(village)
        try context.save()
    }
}
