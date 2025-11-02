import Foundation
import SwiftData

@MainActor
final class LegacyImportService: ObservableObject {
    struct CommitResult {
        let plant: Plant
        let createdVillage: Village?
        let activityCount: Int
        let scheduleCount: Int
    }

    enum ServiceError: LocalizedError {
        case missingDraft
        case emptyPlantName

        var errorDescription: String? {
            switch self {
            case .missingDraft:
                return "There is no draft available to import."
            case .emptyPlantName:
                return "The plant name cannot be empty."
            }
        }
    }

    @Published private(set) var draft: LegacyImportDraft?
    @Published private(set) var lastError: String?
    @Published private(set) var lastResult: CommitResult?

    private let decoder: JSONDecoder

    init() {
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom(Self.decodeDate)
    }

    func loadDraft(from url: URL, context: ModelContext) throws {
        let data = try Data(contentsOf: url)
        do {
            let payload = try decoder.decode(LegacyPlantPayload.self, from: data)
            let villages = try context.fetch(FetchDescriptor<Village>())
            let draft = payload.makeDraft(existingVillages: villages, sourceURL: url)
            self.draft = draft
            lastError = nil
            lastResult = nil
        } catch {
            lastError = error.localizedDescription
            throw error
        }
    }

    func clearDraft() {
        draft = nil
    }

    func commit(
        draft: LegacyImportDraft,
        context: ModelContext,
        selectedVillage: Village?,
        newVillageName: String?,
        newVillageClimate: Village.Climate,
        existingVillages: [Village]
    ) throws -> CommitResult {
        guard draft.plant.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            throw ServiceError.emptyPlantName
        }

        let plant = draft.plant
        plant.name = plant.name.trimmingCharacters(in: .whitespacesAndNewlines)
        plant.species = plant.species.trimmingCharacters(in: .whitespacesAndNewlines)
        if plant.species.isEmpty {
            plant.species = "Unknown"
        }
        plant.notes = plant.notes.trimmingCharacters(in: .whitespacesAndNewlines)

        var createdVillage: Village?
        var finalVillage: Village? = selectedVillage ?? plant.village

        let trimmedNewVillage = newVillageName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if finalVillage == nil {
            if !trimmedNewVillage.isEmpty {
                if let existing = existingVillages.first(where: { $0.name.caseInsensitiveCompare(trimmedNewVillage) == .orderedSame }) {
                    finalVillage = existing
                } else {
                    let village = Village(name: trimmedNewVillage, climate: newVillageClimate)
                    createdVillage = village
                    finalVillage = village
                    context.insert(village)
                }
            } else if let pending = draft.pendingVillage {
                if let existing = existingVillages.first(where: { $0.name.caseInsensitiveCompare(pending.name) == .orderedSame }) {
                    finalVillage = existing
                } else {
                    let village = Village(name: pending.name, climate: pending.climate)
                    createdVillage = village
                    finalVillage = village
                    context.insert(village)
                }
            }
        }

        plant.village = finalVillage

        let activities = draft.activities
        let schedules = draft.schedules

        plant.activities.removeAll()
        plant.schedules.removeAll()

        context.insert(plant)

        for activity in activities {
            activity.plant = plant
            plant.activities.append(activity)
            context.insert(activity)
        }

        for schedule in schedules {
            schedule.plant = plant
            plant.schedules.append(schedule)
            context.insert(schedule)
        }

        if let wateringDate = activities.filter({ $0.kind == .water }).map(\PlantActivity.createdAt).max() {
            plant.lastWateredAt = wateringDate
        }

        try context.save()

        let result = CommitResult(
            plant: plant,
            createdVillage: createdVillage,
            activityCount: activities.count,
            scheduleCount: schedules.count
        )
        lastResult = result
        lastError = nil
        self.draft = nil
        return result
    }

    private static func decodeDate(from decoder: Decoder) throws -> Date {
        let container = try decoder.singleValueContainer()
        if let timestamp = try? container.decode(Double.self) {
            return Date(timeIntervalSince1970: timestamp)
        }
        if let string = try? container.decode(String.self) {
            if let isoDate = isoFormatter.date(from: string) {
                return isoDate
            }
            if let simpleDate = dateFormatter.date(from: string) {
                return simpleDate
            }
        }
        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unrecognized date format"))
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        return formatter
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = .current
        return formatter
    }()
}
